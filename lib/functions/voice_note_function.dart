import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class VoiceNoteHelper {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  final String chatRoomId;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  VoiceNoteHelper({required this.chatRoomId});
  bool get isRecording => _isRecording;

  Future<void> toggleRecording({
    required Function(bool, String?) onRecordingChanged,
    required Map<String, dynamic> userMap,
    required String chatRoomId,
    required Function(double) onProgress,
  }) async {
    bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      await Permission.microphone.request();
      return;
    }

    if (_isRecording) {
      final path = await _recorder.stop();
      _isRecording = false;
      _audioPath = path;
      onRecordingChanged(_isRecording, _audioPath);

      if (_audioPath != null) {
        await uploadVoiceFileWithProgress(
          voiceFile: File(_audioPath!),
          userMap: userMap,
          chatRoomId: chatRoomId,
          onProgress: onProgress,
        );
      }
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      _isRecording = true;
      _audioPath = null;
      onRecordingChanged(_isRecording, null);
    }
  }

  static Future<String> uploadVoiceFileWithProgress({
    required File voiceFile,
    required Map<String, dynamic> userMap,
    required String chatRoomId,
    required Function(double) onProgress,
  }) async {
    try {
      final String fileName = const Uuid().v1();
      final String myUid = _auth.currentUser!.uid;
      final String currentUserName =
          _auth.currentUser?.displayName ?? 'Unknown';
      final String myDisplayName = _auth.currentUser!.displayName ?? "Unknown";
      final String currentUserUid = myUid;

      final String otherUserUid = userMap['uid'] ?? userMap['userId'] ?? '';
      if (otherUserUid.isEmpty) {
        print("⚠️ No recipient UID found.");
        return '';
      }

      final String fileOnlyName = voiceFile.path.split('/').last;
      final String firebaseAudioPath = 'voice_notes/$fileOnlyName';

      final messageDoc = FirebaseFirestore.instance
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName);

      await messageDoc.set({
        "sendby": myDisplayName,
        "sendbyUid": myUid,
        "message": "",
        "voiceNote": "", // updated after upload
        "type": "voice",
        "time": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      final currentUserDoc =
          await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final currentUserData = currentUserDoc.data() ?? {};

      final ref = FirebaseStorage.instance.ref().child(firebaseAudioPath);
      final uploadTask = ref.putFile(voiceFile);

      // Track progress
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        },
        onError: (error) {
          print('❌ Upload failed: $error');
        },
      );

      // Await final upload
      try {
        await uploadTask;
      } catch (error) {
        await messageDoc.delete();
        print('🔥 Upload failed: $error');
        return '';
      }

      final fileUrl = await ref.getDownloadURL();
      // Update Firestore message with voiceNote URL
      await messageDoc.update({"voiceNote": fileUrl, "message": fileUrl});

      /// Update chat history (you can skip this if already managed elsewhere)
      final myChatRef = FirebaseFirestore.instance
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
        "lastMessage": fileUrl,
        "timestamp": FieldValue.serverTimestamp(),
      };
      await myChatRef.set(myChatData, SetOptions(merge: true));

      final theirChatRef = FirebaseFirestore.instance
          .collection('chathistory')
          .doc(otherUserUid)
          .collection('chats')
          .doc(chatRoomId);

      final theirChatData = {
        "userId": myUid,
        "name": currentUserData['name'] ?? '',
        "profileImageUrl": currentUserData['profileImageUrl'] ?? '',
        "email": currentUserData['email'] ?? '',
        "lastMessage": fileUrl,
        "timestamp": FieldValue.serverTimestamp(),
        "isRead": false,
      };
      await theirChatRef.set(theirChatData, SetOptions(merge: true));

      await myChatRef.collection('messages').add({
        "sendby": currentUserName,
        "sendbyUid": currentUserUid,
        "message": fileUrl,
        "type": "voice",
        "time": FieldValue.serverTimestamp(),
        "isRead": true,
      });

      print("✅ Voice note uploaded successfully.");
      return fileUrl;
    } catch (e) {
      print("🔥 Error uploading voice note: $e");
      return '';
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
