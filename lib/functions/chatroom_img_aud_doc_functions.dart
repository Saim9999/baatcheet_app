import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

/// image, audio & document functions

class ImgAudDocChatroomFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static File? imageFile;

  static String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Pick image from gallery
  static Future<void> getImage(Function(File) onImagePicked) async {
    final ImagePicker _picker = ImagePicker();

    try {
      final XFile? xFile = await _picker.pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        imageFile = File(xFile.path);
        onImagePicked(imageFile!);
      } else {
        print("🖼️ No image selected from gallery.");
      }
    } catch (e) {
      print("🖼️ Gallery error: $e");
    }
  }

  /// Pick image from camera
  static Future<void> getCameraImage(Function(File) onImagePicked) async {
    final ImagePicker _picker = ImagePicker();

    try {
      final XFile? xFile = await _picker.pickImage(source: ImageSource.camera);
      if (xFile != null) {
        imageFile = File(xFile.path);
        onImagePicked(imageFile!);
      } else {
        print("📷 No image captured from camera.");
      }
    } catch (e) {
      print("📷 Camera error: $e");
    }
  }

  /// Upload image to Firestore & Storage
  static Future<String> uploadImage({
    required File imageFile,
    required Map<String, dynamic> userMap,
    required Function(double progress) onProgress,
  }) async {
    final String fileName = const Uuid().v1();
    final ref = _storage.ref().child('images/$fileName.jpg');

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
      "type": "img",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    final currentUserDoc =
        await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data() ?? {};

    // Step 2: Upload image
    final uploadTask = ref.putFile(imageFile);

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
    final imageUrl = await ref.getDownloadURL();
    await messageDoc.update({"message": imageUrl});

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
      "lastMessage": imageUrl,
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
      "lastMessage": imageUrl,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    };

    await theirChatRef.set(theirChatData, SetOptions(merge: true));

    // Step 6: Optional message log in my history
    await myChatRef.collection('messages').add({
      "sendby": currentUserName,
      "sendbyUid": currentUserUid,
      "message": imageUrl,
      "type": "img",
      "time": FieldValue.serverTimestamp(),
      "isRead": true,
    });

    return imageUrl;
  }

  /// Pick audio file from gallery
  static Future<void> pickAudioFile({
    required Function(File) onAudioPicked,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );

      if (result != null && result.files.single.path != null) {
        final File audioFile = File(result.files.single.path!);
        onAudioPicked(audioFile);
      } else {
        print('⚠️ No file selected');
        return null;
      }
    } catch (e) {
      print('❌ File picking failed: $e');
      return null;
    }
  }

  /// Upload audio file to Firestore & Storage
  static Future<String> uploadAudioFileWithProgress({
    required File audioFile,
    required Map<String, dynamic> userMap,
    required String chatRoomId,
    required Function(double) onProgress,
  }) async {
    final String fileName = const Uuid().v1();
    final String currentUserName = _auth.currentUser?.displayName ?? 'Unknown';
    final String myUid = _auth.currentUser!.uid;
    final String? myDisplayName = _auth.currentUser!.displayName;
    final String currentUserUid = _auth.currentUser!.uid;

    final String otherUserUid = userMap['uid'] ?? userMap['userId'] ?? '';
    if (otherUserUid.isEmpty) {
      print("⚠️ No recipient UID found.");
      return '';
    }

    final chatRoomId = getChatRoomId(currentUserUid, otherUserUid);

    final String fileOnlyName = audioFile.path.split('/').last;
    final String firebaseAudioPath = 'mp3/$fileOnlyName';

    final messageDoc = _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(fileName);

    await messageDoc.set({
      "sendby": myDisplayName ?? '',
      "sendbyUid": myUid,
      "message": "",
      "type": "audiofile",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    final currentUserDoc =
        await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data() ?? {};

    final ref = FirebaseStorage.instance.ref().child(firebaseAudioPath);
    final uploadTask = ref.putFile(audioFile);

    uploadTask.snapshotEvents.listen(
      (snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      },
      onError: (error) {
        print('❌ Upload failed: $error');
      },
    );

    try {
      await uploadTask;
    } catch (error) {
      await messageDoc.delete();
      print('🔥 Upload failed: $error');
      return '';
    }

    final fileUrl = await ref.getDownloadURL();
    await messageDoc.update({"message": fileUrl});

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
      "lastMessage": fileUrl,
      "timestamp": FieldValue.serverTimestamp(),
    };
    await myChatRef.set(myChatData, SetOptions(merge: true));

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
      "lastMessage": fileUrl,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    };
    await theirChatRef.set(theirChatData, SetOptions(merge: true));

    await myChatRef.collection('messages').add({
      "sendby": currentUserName,
      "sendbyUid": currentUserUid,
      "message": fileUrl,
      "type": "audiofile",
      "time": FieldValue.serverTimestamp(),
      "isRead": true,
    });

    print("✅ Audio file uploaded successfully.");
    return fileUrl;
  }

  /// Pick document file from gallery
  static Future<void> pickDocFile({required Function(File) onDocPicked}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final File docFile = File(result.files.single.path!);
        onDocPicked(docFile);
      } else {
        print('⚠️ No file selected');
        return null;
      }
    } catch (e) {
      print('❌ File picking failed: $e');
      return null;
    }
  }

  /// Upload document file to Firestore & Storage
  static Future<String> uploadDocFileWithProgress({
    required File docFile,
    required Map<String, dynamic> userMap,
    required String chatRoomId,
    required Function(double) onProgress,
  }) async {
    final String fileName = const Uuid().v1();
    final String currentUserName = _auth.currentUser?.displayName ?? 'Unknown';
    final String myUid = _auth.currentUser!.uid;
    final String? myDisplayName = _auth.currentUser!.displayName;
    final String currentUserUid = _auth.currentUser!.uid;

    final String otherUserUid = userMap['uid'] ?? userMap['userId'] ?? '';
    if (otherUserUid.isEmpty) {
      print("⚠️ No recipient UID found.");
      return '';
    }

    final chatRoomId = getChatRoomId(currentUserUid, otherUserUid);

    final String fileOnlyName = docFile.path.split('/').last;
    final String firebaseAudioPath = 'documents/$fileOnlyName';

    final messageDoc = _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(fileName);

    await messageDoc.set({
      "sendby": myDisplayName ?? '',
      "sendbyUid": myUid,
      "message": "",
      "type": "file",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    final currentUserDoc =
        await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data() ?? {};

    final ref = FirebaseStorage.instance.ref().child(firebaseAudioPath);
    final uploadTask = ref.putFile(docFile);

    uploadTask.snapshotEvents.listen(
      (snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      },
      onError: (error) {
        print('❌ Upload failed: $error');
      },
    );

    try {
      await uploadTask;
    } catch (error) {
      await messageDoc.delete();
      print('🔥 Upload failed: $error');
      return '';
    }

    final fileUrl = await ref.getDownloadURL();
    await messageDoc.update({"message": fileUrl});

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
      "lastMessage": fileUrl,
      "timestamp": FieldValue.serverTimestamp(),
    };
    await myChatRef.set(myChatData, SetOptions(merge: true));

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
      "lastMessage": fileUrl,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    };
    await theirChatRef.set(theirChatData, SetOptions(merge: true));

    await myChatRef.collection('messages').add({
      "sendby": currentUserName,
      "sendbyUid": currentUserUid,
      "message": fileUrl,
      "type": "file",
      "time": FieldValue.serverTimestamp(),
      "isRead": true,
    });

    print("✅ Document file uploaded successfully.");
    return fileUrl;
  }
}
