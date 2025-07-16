import 'package:baatcheet_app/Screens/chatroom_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class SearchChatTile extends StatefulWidget {
  Map<String, dynamic>? userMap;
  SearchChatTile({super.key, required this.userMap});

  @override
  State<SearchChatTile> createState() => _SearchChatTileState();
}

class _SearchChatTileState extends State<SearchChatTile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Stream<int> getUnreadMessageCount(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .where('isRead', isEqualTo: false)
        .where(
          'sendbyUid',
          isNotEqualTo: FirebaseAuth.instance.currentUser!.uid,
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
    if (widget.userMap != null &&
        widget.userMap!.containsKey('uid') &&
        widget.userMap!['uid'] != null) {
      final targetUid = widget.userMap!['uid'];
      print('Using UID in StreamBuilder: $targetUid');
      return StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('chatroom')
                .doc(
                  getChatRoomId(_auth.currentUser!.uid, widget.userMap!['uid']),
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
                  ? snapshot.data!.docs[0].data() as Map<String, dynamic>
                  : null;
          String lastMessage = 'Hey!';
          if (lastMessageData != null) {
            if (lastMessageData['type'] == 'img') {
              Uri fileUri = Uri.parse(lastMessageData['message']);
              String fileName =
                  fileUri.pathSegments.isNotEmpty
                      ? fileUri.pathSegments.last
                      : fileUri.path;
              String cleanedFileName = fileName.substring(
                fileName.indexOf('/') + 1,
              );
              lastMessage = 'Photo: $cleanedFileName';
            } else if (lastMessageData['type'] == 'file') {
              Uri fileUri = Uri.parse(lastMessageData['message']);
              String fileName =
                  fileUri.pathSegments.isNotEmpty
                      ? fileUri.pathSegments.last
                      : fileUri.path;
              String cleanedFileName = fileName.substring(
                fileName.indexOf('/') + 1,
              );
              lastMessage = 'File: $cleanedFileName';
            } else if (lastMessageData['type'] == 'audiofile') {
              Uri fileUri = Uri.parse(lastMessageData['message']);
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
                widget.userMap!['uid'],
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => ChatRoom(
                        chatRoomId: roomId,
                        userMap: widget.userMap!,
                      ),
                ),
              );
              print("object11111111 ${widget.userMap!['uid']}");
            },
            leading:
                widget.userMap!['profileImageUrl'] != ''
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.network(
                        widget.userMap!['profileImageUrl'],
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
                                      ? loadingProgress.cumulativeBytesLoaded /
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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.userMap!['name'],
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  (lastMessageData != null &&
                          lastMessageData['time'] != null &&
                          lastMessageData['time'] is Timestamp)
                      ? formatMessageTime(
                        (lastMessageData['time'] as Timestamp).toDate(),
                      )
                      : '',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Color.fromARGB(255, 121, 124, 123),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                if (lastMessageData != null &&
                    lastMessageData['sendbyUid'] == _auth.currentUser!.uid) ...[
                  Icon(
                    lastMessageData['isRead'] == true
                        ? Icons.done_all
                        : Icons.check,
                    size: 18,
                    color:
                        lastMessageData['isRead'] == true
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(lastMessage, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            trailing: StreamBuilder<int>(
              stream: getUnreadMessageCount(
                getChatRoomId(_auth.currentUser!.uid, widget.userMap!['uid']),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data! > 0) {
                  return CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${snapshot.data}',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          );
        },
      );
    }
    return SizedBox();
  }
}
