import 'package:baatcheet_app/Screens/chatroom_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatHistoryListTile extends StatefulWidget {
  const ChatHistoryListTile({super.key});

  @override
  State<ChatHistoryListTile> createState() => _ChatHistoryListTileState();
}

class _ChatHistoryListTileState extends State<ChatHistoryListTile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('chathistory')
              .doc(currentUid)
              .collection('chats')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final chatDocs = snapshot.data?.docs ?? [];

        if (chatDocs.isEmpty) {
          return Center(child: Text('No chats yet.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final data = chatDocs[index].data() as Map<String, dynamic>;

            if (data['userId'] == null || data['name'] == null) {
              return SizedBox(); // Skip invalid entries
            }

            final String userId = data['userId'];
            final String name = data['name'];
            final String email = data['email'] ?? '';
            final String imageUrl = data['profileImageUrl'] ?? '';
            final String roomId = getChatRoomId(currentUid, userId);

            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatRoom(
                          chatRoomId: roomId,
                          userMap: {
                            'uid': userId,
                            'name': name,
                            'email': email,
                            'profileImageUrl': imageUrl,
                          },
                        ),
                  ),
                );
              },
              leading:
                  imageUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.network(
                          imageUrl,
                          height: 52,
                          width: 52,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          loadingBuilder: (context, child, loadingProgress) {
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
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 52,
                                width: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                        ),
                      )
                      : CircleAvatar(radius: 26, child: Icon(Icons.person)),
              title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(email),
            );
          },
        );
      },
    );
  }
}
