import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chatroom_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat History')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('chathistory')
                .doc(_auth.currentUser!.uid)
                .collection('chats')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final userDocs = snapshot.data!.docs;

          if (userDocs.isEmpty) {
            return Center(child: Text('No chat history!'));
          }

          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userMap = userDocs[index].data() as Map<String, dynamic>;
              final String targetUid = userMap['userId'] ?? '';
              final String currentUid = _auth.currentUser!.uid;
              final String roomId = getChatRoomId(currentUid, targetUid);
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
                    leading: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        image: DecorationImage(
                          image: NetworkImage(userMap['profileImageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(userMap['name'] ?? ''),
                    subtitle: Text(userMap['email']),
                  ),
                  SizedBox(height: 10.h),
                ],
              );
            },
          ); // Return the desired widget
        },
      ),
    );
  }
}
