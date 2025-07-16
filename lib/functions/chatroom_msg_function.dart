import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

/// send & upload text message function

class MsgChatroomFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Send & Upload messages to Firestore & Storage
  static Future<void> sendTextMessage({
    required String messageText,
    required Map<String, dynamic> userMap,
    required TextEditingController messageController,
  }) async {
    if (messageText.trim().isEmpty) {
      print("Enter some text");
      return;
    }

    final String myUid = _auth.currentUser!.uid;
    final String? myDisplayName = _auth.currentUser!.displayName;
    final String otherUserUid = userMap['uid'] ?? userMap['userId'] ?? '';

    if (otherUserUid.isEmpty) {
      print("❌ Error: UID is missing in userMap.");
      return;
    }

    String getChatRoomId(String uid1, String uid2) {
      return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
    }

    final String chatRoomId = getChatRoomId(myUid, otherUserUid);

    Map<String, dynamic> messageData = {
      "sendby": myDisplayName ?? '',
      "sendbyUid": myUid,
      "message": messageText.trim(),
      "type": "text",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
    };

    messageController.clear();

    await _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .add(messageData);

    final myChatHistoryRef = _firestore
        .collection('chathistory')
        .doc(myUid)
        .collection('chats')
        .doc(chatRoomId);

    await myChatHistoryRef.set({
      "userId": otherUserUid,
      "name": userMap['name'] ?? '',
      "profileImageUrl": userMap['profileImageUrl'] ?? '',
      "email": userMap['email'] ?? '',
      "lastMessage": messageText,
      "timestamp": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final currentUserDoc =
        await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data() ?? {};

    final theirChatHistoryRef = _firestore
        .collection('chathistory')
        .doc(otherUserUid)
        .collection('chats')
        .doc(chatRoomId);

    await theirChatHistoryRef.set({
      "userId": myUid,
      "name": currentUserData['name'] ?? '',
      "profileImageUrl": currentUserData['profileImageUrl'] ?? '',
      "email": currentUserData['email'] ?? '',
      "lastMessage": messageText,
      "timestamp": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await myChatHistoryRef.collection('messages').add(messageData);

    print("✅ Message sent successfully.");
  }
}
