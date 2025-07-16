import 'package:baatcheet_app/functions/homescreen_historylisttile.dart';
import 'package:baatcheet_app/functions/homescreen_searchchattile.dart';
import 'package:baatcheet_app/group_chats/group_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Authenticate/signin_screen.dart';
import 'drawer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      setStatus("Online");
    } else {
      // offline
      setStatus("Offline");
    }
  }

  void onSearch() async {
    setState(() => isLoading = true);

    final result =
        await _firestore
            .collection('users')
            .where("email", isEqualTo: _search.text)
            .where("email", isNotEqualTo: _auth.currentUser!.email)
            .get();

    if (result.docs.isEmpty) {
      setState(() {
        userMap = null;
        isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Oops!"),
              content: Text("User Not Found."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
      );
    } else {
      setState(() {
        userMap = result.docs.first.data();
        isLoading = false;
        print('Check UserID: ${result.docs.first.data()}');
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Navigate to the sign-in screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      // Handle logout errors
      print('Logout Error: $e');
    }
  }

  String formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(messageTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(messageTime); // e.g., Monday
    } else {
      return DateFormat(
        'MMM d, yyyy',
      ).format(messageTime); // e.g., Mar 25, 2025
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Drawer(child: DrawerScreen()),
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _signOut)],
      ),
      body:
          isLoading
              ? Center(
                child: SizedBox(
                  height: size.height / 20,
                  width: size.height / 20,
                  child: CircularProgressIndicator(),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height / 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: "Search",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height / 50),
                    ElevatedButton(onPressed: onSearch, child: Text("Search")),
                    SizedBox(height: size.height / 30),

                    // Search Chat List Tile,
                    SearchChatTile(userMap: userMap),
                    Divider(),
                    // Chat History List Tile,
                    ChatHistoryListTile(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.group),
        onPressed:
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => GroupChatHomeScreen())),
      ),
    );
  }
}
