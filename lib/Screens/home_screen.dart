import 'package:baatcheet_app/Screens/chatroom_screen.dart';
import 'package:baatcheet_app/group_chats/group_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Authenticate/signin_screen.dart';
import 'drawer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
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

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  void onSearch() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    setState(() {
      isLoading = true;
    });

    await _firestore
        .collection('users')
        .where("email", isEqualTo: _search.text)
        .where("email", isNotEqualTo: FirebaseAuth.instance.currentUser!.email)
        .get()
        .then((value) {
          setState(() {
            if (value.docs.isEmpty) {
              userMap = null;
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("Oops!"),
                      content: Text("User Not Found."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("OK"),
                        ),
                      ],
                    ),
              );
            } else {
              userMap = value.docs[0].data();
            }
            isLoading = false;
          });
        });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
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
                child: Container(
                  height: size.height / 20,
                  width: size.height / 20,
                  child: CircularProgressIndicator(),
                ),
              )
              : Column(
                children: [
                  SizedBox(height: size.height / 20),
                  Container(
                    height: size.height / 10,
                    width: size.width,
                    alignment: Alignment.center,
                    child: Container(
                      height: size.height / 10,
                      width: size.width / 1.15,
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
                  ),
                  SizedBox(height: size.height / 50),
                  ElevatedButton(onPressed: onSearch, child: Text("Search")),
                  SizedBox(height: size.height / 30),
                  userMap != null
                      ? StreamBuilder<QuerySnapshot>(
                        stream:
                            _firestore
                                .collection('chatroom')
                                .doc(
                                  getChatRoomId(
                                    _auth.currentUser!.uid,
                                    userMap!['uid'],
                                  ),
                                )
                                .collection('chats')
                                .orderBy('time', descending: true)
                                .limit(1)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (!snapshot.hasData) {
                            return Container();
                          }

                          final lastMessageData =
                              snapshot.data!.docs.isNotEmpty
                                  ? snapshot.data!.docs[0].data()
                                      as Map<String, dynamic>
                                  : null;
                          String lastMessage = 'Hey!';
                          if (lastMessageData != null) {
                            if (lastMessageData['type'] == 'img') {
                              Uri fileUri = Uri.parse(
                                lastMessageData['message'],
                              );
                              String fileName =
                                  fileUri.pathSegments.isNotEmpty
                                      ? fileUri.pathSegments.last
                                      : fileUri.path;
                              String cleanedFileName = fileName.substring(
                                fileName.indexOf('/') + 1,
                              );
                              lastMessage = 'Photo: $cleanedFileName';
                            } else if (lastMessageData['type'] == 'file') {
                              Uri fileUri = Uri.parse(
                                lastMessageData['message'],
                              );
                              String fileName =
                                  fileUri.pathSegments.isNotEmpty
                                      ? fileUri.pathSegments.last
                                      : fileUri.path;
                              String cleanedFileName = fileName.substring(
                                fileName.indexOf('/') + 1,
                              );
                              lastMessage = 'File: $cleanedFileName';
                            } else if (lastMessageData['type'] == 'audiofile') {
                              Uri fileUri = Uri.parse(
                                lastMessageData['message'],
                              );
                              String fileName =
                                  fileUri.pathSegments.isNotEmpty
                                      ? fileUri.pathSegments.last
                                      : fileUri.path;
                              String cleanedFileName = fileName.substring(
                                fileName.indexOf('/') + 1,
                              );
                              lastMessage = 'Audio: $cleanedFileName.mp3';
                            } else {
                              lastMessage = lastMessageData['message'];
                            }
                          }

                          return ListTile(
                            horizontalTitleGap: 10,
                            onTap: () {
                              String roomId = getChatRoomId(
                                _auth.currentUser!.uid,
                                userMap!['uid'],
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => ChatRoom(
                                        chatRoomId: roomId,
                                        userMap: userMap!,
                                      ),
                                ),
                              );
                              print("object11111111 ${userMap!['uid']}");
                            },
                            leading:
                                userMap!['profileImageUrl'] != ''
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(26),
                                      child: Image.network(
                                        userMap!['profileImageUrl'],
                                        height: 52,
                                        width: 52,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.low,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: 52,
                                            width: 52,
                                            alignment: Alignment.center,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 52,
                                                  width: 52,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          26,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                      ),
                                    )
                                    : CircleAvatar(
                                      radius: 26,
                                      child: Icon(Icons.person),
                                    ),
                            title: Text(
                              userMap!['name'],
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(lastMessage),
                            trailing: Icon(Icons.chat, color: Colors.black),
                          );
                        },
                      )
                      : Container(),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('chathistory')
                              .doc(_auth.currentUser!.uid)
                              .collection('chats')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final userDocs = snapshot.data!.docs;

                        if (userDocs.isEmpty) {
                          return Center(child: Text('No chat history!'));
                        }

                        return ListView.builder(
                          itemCount: userDocs.length,
                          itemBuilder: (context, index) {
                            final userMap =
                                userDocs[index].data() as Map<String, dynamic>;

                            final String targetUid = userMap['userId'] ?? '';
                            final String currentUid = _auth.currentUser!.uid;
                            final String roomId = getChatRoomId(
                              currentUid,
                              targetUid,
                            );

                            return Column(
                              children: [
                                ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ChatRoom(
                                              chatRoomId: roomId,
                                              userMap: userMap,
                                            ),
                                      ),
                                    );
                                  },
                                  leading:
                                      userMap['profileImageUrl'] != null &&
                                              userMap['profileImageUrl']
                                                  .toString()
                                                  .isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              26,
                                            ),
                                            child: Image.network(
                                              userMap['profileImageUrl'],
                                              height: 52,
                                              width: 52,
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.low,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  height: 52,
                                                  width: 52,
                                                  alignment: Alignment.center,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    height: 52,
                                                    width: 52,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            26,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                            ),
                                          )
                                          : CircleAvatar(
                                            radius: 26,
                                            child: Icon(Icons.person),
                                          ),
                                  title: Text(
                                    userMap['name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    userMap['email'] ?? '',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
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
