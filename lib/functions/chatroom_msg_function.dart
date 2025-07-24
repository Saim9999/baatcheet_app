import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// send & upload text message function
class MsgChatroomFunctions {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
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

  /// pick video file gallery
  static File? videoFile;

  static Future<void> pickVideo(Function(File) onImagePicked) async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? xFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (xFile != null) {
        videoFile = File(xFile.path);
        onImagePicked(videoFile!);
      } else {
        print("🖼️ No Video selected from gallery.");
      }
    } catch (e) {
      print("🖼️ Gallery error: $e");
    }
  }

  /// Upload video to Firestore & Storage
  static Future<String> uploadVideo({
    required File videoFile,
    required Map<String, dynamic> userMap,
    required Function(double progress) onProgress,
  }) async {
    final String fileName = const Uuid().v1();
    final ref = _storage.ref().child('videos/$fileName.jpg');

    final currentUser = _auth.currentUser;
    final String myUid = _auth.currentUser!.uid;
    final String currentUserUid = currentUser?.uid ?? '';
    final String currentUserName = currentUser?.displayName ?? 'Unknown';
    final String? myDisplayName = currentUser!.displayName;

    final String? otherUserUid = userMap['uid'] ?? userMap['userId'] ?? '';
    if (otherUserUid == null || otherUserUid.isEmpty) {
      print("⚠️ No recipient UID available.");
      return '';
    }
    final String chatRoomId = getChatRoomId(currentUserUid, otherUserUid);

    // Step 1: Create placeholder chat document
    final messageDoc = _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(fileName);

    await messageDoc.set({
      "sendby": myDisplayName ?? '',
      "sendbyUid": myUid,
      "message": "",
      "type": "video",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    final currentUserDoc =
        await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data() ?? {};

    // Step 2: Upload image
    final uploadTask = ref.putFile(videoFile);

    uploadTask.snapshotEvents.listen(
      (TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      },
      onError: (error) {
        print('🔥 Upload error: $error');
      },
    );

    try {
      await uploadTask;
    } catch (error) {
      print('❌ Upload failed, deleting placeholder doc...');
      await messageDoc.delete();
      return '';
    }

    // Step 3: Get download URL
    final videoUrl = await ref.getDownloadURL();
    await messageDoc.update({"message": videoUrl});

    // Step 4: Update chat history for current user
    final myChatRef = _firestore
        .collection('chathistory')
        .doc(myUid)
        .collection('chats')
        .doc(chatRoomId);
    final myChatDoc = await myChatRef.get();
    final myExistingData = myChatDoc.data();

    final myChatData = {
      "userId": otherUserUid,
      "name": userMap['name'] ?? '',
      "profileImageUrl": userMap['profileImageUrl'] ?? '',
      "email": userMap['email'] ?? myExistingData?['email'] ?? '',
      "lastMessage": videoUrl,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await myChatRef.set(myChatData, SetOptions(merge: true));

    // Step 5: Update chat history for other user
    final theirChatRef = _firestore
        .collection('chathistory')
        .doc(otherUserUid)
        .collection('chats')
        .doc(chatRoomId);

    final theirChatData = {
      "userId": myUid,
      "name": currentUserData['name'] ?? '',
      "profileImageUrl": currentUserData['profileImageUrl'] ?? '',
      "email": currentUserData['email'] ?? '',
      "lastMessage": videoUrl,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    };

    await theirChatRef.set(theirChatData, SetOptions(merge: true));

    // Step 6: Optional message log in my history
    await myChatRef.collection('messages').add({
      "sendby": currentUserName,
      "sendbyUid": currentUserUid,
      "message": videoUrl,
      "type": "video",
      "time": FieldValue.serverTimestamp(),
      "isRead": true,
    });

    return videoUrl;
  }
}
