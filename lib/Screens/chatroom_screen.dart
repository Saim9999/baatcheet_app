import 'package:baatcheet_app/functions/chatroom_img_aud_doc_functions.dart';
import 'package:baatcheet_app/functions/chatroom_message_widget.dart';
import 'package:baatcheet_app/functions/chatroom_msg_function.dart';
import 'package:baatcheet_app/functions/voice_note_function.dart';
import 'package:baatcheet_app/helper/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatRoom extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;
  const ChatRoom({super.key, required this.chatRoomId, required this.userMap});
  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> with TickerProviderStateMixin {
  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double downloadProgress = 0.0;
  late AnimationController _sendController;

  bool showSendButton = false;

  String getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  bool isNewDate(DateTime currentMessageTime, DateTime? previousMessageTime) {
    if (previousMessageTime == null) return true;
    return currentMessageTime.day != previousMessageTime.day ||
        currentMessageTime.month != previousMessageTime.month ||
        currentMessageTime.year != previousMessageTime.year;
  }

  // Function to format the date label
  String formatDateLabel(DateTime messageTime) {
    final now = DateTime.now();

    // Get just the date parts for accurate calendar day comparison
    final nowDate = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      messageTime.year,
      messageTime.month,
      messageTime.day,
    );
    final difference = nowDate.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    }
    if (difference > 6) {
      // Older than 7 days ➔ show full date
      return DateFormat('d MMMM yyyy').format(messageTime);
    } else {
      // Within 7 days ➔ show day name (Monday, Tuesday...)
      return DateFormat('EEEE').format(messageTime);
    }
  }

  void markMessagesAsRead(String chatRoomId) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final query =
        await FirebaseFirestore.instance
            .collection('chatroom')
            .doc(chatRoomId)
            .collection('chats')
            .where('sendbyUid', isNotEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get();

    for (var doc in query.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  late VoiceNoteHelper _voiceNoteHelper;
  bool isRecording = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();
    _message.addListener(() {
      setState(() {
        showSendButton = _message.text.trim().isNotEmpty;
      });
    });
    _voiceNoteHelper = VoiceNoteHelper(chatRoomId: widget.chatRoomId);
    markMessagesAsRead(widget.chatRoomId);
    _sendController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    // Add this to automatically start the animation after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendController.reset();
      _sendController.forward();
    });
  }

  @override
  void dispose() {
    _voiceNoteHelper.dispose();
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80.h,
        backgroundColor: Colors.transparent,
        elevation: 0,
        forceMaterialTransparency: true,
        systemOverlayStyle: SystemUiOverlayStyle(),
        titleSpacing: 10.0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.keyboard_backspace_rounded),
        ),
        shape: Border(
          bottom: BorderSide(color: Color.fromARGB(255, 238, 250, 248)),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore
                  .collection("users")
                  .doc(widget.userMap['uid'] ?? widget.userMap['userId'])
                  .snapshots(),
          builder: (context, snapshot) {
            print("object323232323 ${widget.userMap['name']}");
            if (snapshot.data != null) {
              return Row(
                children: [
                  Container(
                    alignment: Alignment.bottomRight,
                    height: 44.h,
                    width: 44.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(52.r),
                      image: DecorationImage(
                        image: NetworkImage(widget.userMap['profileImageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3, bottom: 5),
                      child: CircleAvatar(
                        radius: 4.r,
                        backgroundColor:
                            snapshot.data!['status'] == "Online"
                                ? Color.fromARGB(255, 43, 239, 131)
                                : Color.fromARGB(255, 121, 124, 123),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.userMap['name'], style: appbartitleText),
                      Text(
                        snapshot.data!['status'] == "Online"
                            ? 'Active now'
                            : 'Offline',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Container();
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              // height: size.height / 1.25,
              width: size.width,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('chatroom')
                        .doc(widget.chatRoomId)
                        .collection('chats')
                        .orderBy("time", descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        // return messages(size, map, context);
                        DateTime messageTime =
                            (map['time'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        DateTime? previousMessageTime;
                        if (index < snapshot.data!.docs.length - 1) {
                          Map<String, dynamic> previousMap =
                              snapshot.data!.docs[index + 1].data()
                                  as Map<String, dynamic>;
                          previousMessageTime =
                              (previousMap['time'] as Timestamp?)?.toDate();
                        }
                        bool showDate = isNewDate(
                          messageTime,
                          previousMessageTime,
                        );
                        return Column(
                          children: [
                            if (showDate)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 248, 251, 250),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    formatDateLabel(messageTime),
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 14, 8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12.sp,
                                      fontFamily: 'cretype  Caros-Medium',
                                    ),
                                  ),
                                ),
                              ),
                            MessageWidget(
                              size: size,
                              map: map,
                              currentUserUid: _auth.currentUser!.uid,
                              downloadProgress: downloadProgress,
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
          Container(
            height: size.height / 10,
            width: size.width,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color.fromARGB(255, 238, 250, 248)),
              ),
            ),
            child: SizedBox(
              height: size.height / 12,
              width: size.width / 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                            alignment: Alignment.bottomCenter,
                            insetPadding: EdgeInsets.all(0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: SizedBox(
                              height: size.height / 1.4,
                              width: size.width,
                              child: ListView(
                                children: [
                                  ListTile(
                                    leading: IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      icon: Icon(Icons.close_rounded),
                                    ),
                                    title: Text(
                                      'Share Content',
                                      style: TextStyle(
                                        fontFamily: 'cretype  Caros-Medium',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    minTileHeight: 80,
                                    horizontalTitleGap: 60,
                                  ),
                                  listTileMethod(
                                    context,
                                    "Camera",
                                    "",
                                    'assets/images/camera image.png',
                                    () {
                                      Navigator.of(context).pop();
                                      // getCameraImage();
                                      ImgAudDocChatroomFunctions.getCameraImage((
                                        pickedFile,
                                      ) async {
                                        await ImgAudDocChatroomFunctions.uploadImage(
                                          imageFile: pickedFile,
                                          userMap: widget.userMap,
                                          onProgress: (progress) {
                                            setState(() {
                                              downloadProgress = progress;
                                            });
                                          },
                                        );
                                      });
                                    },
                                  ),
                                  Divider(endIndent: 20, indent: 20),
                                  listTileMethod(
                                    context,
                                    "Documents",
                                    "Share your files",
                                    'assets/images/doc.png',
                                    () {
                                      ImgAudDocChatroomFunctions.pickDocFile(
                                        onDocPicked: (file) async {
                                          await ImgAudDocChatroomFunctions.uploadDocFileWithProgress(
                                            chatRoomId: widget.chatRoomId,
                                            docFile: file,
                                            userMap: widget.userMap,
                                            onProgress: (progress) {
                                              setState(() {
                                                downloadProgress = progress;
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Divider(endIndent: 20, indent: 20),
                                  listTileMethod(
                                    context,
                                    "Media",
                                    "Share photos from gallery",
                                    'assets/images/media.png',
                                    () {
                                      ImgAudDocChatroomFunctions.getImage((
                                        pickedFile,
                                      ) async {
                                        await ImgAudDocChatroomFunctions.uploadImage(
                                          imageFile: pickedFile,
                                          userMap: widget.userMap,
                                          onProgress: (progress) {
                                            setState(() {
                                              downloadProgress = progress;
                                            });
                                          },
                                        );
                                      });
                                    },
                                  ),
                                  Divider(endIndent: 20, indent: 20),
                                  listTileMethod(
                                    context,
                                    "Audio",
                                    "Share your audio files",
                                    Icons.headphones_rounded,
                                    () {
                                      ImgAudDocChatroomFunctions.pickAudioFile(
                                        onAudioPicked: (file) async {
                                          await ImgAudDocChatroomFunctions.uploadAudioFileWithProgress(
                                            chatRoomId: widget.chatRoomId,
                                            audioFile: file,
                                            userMap: widget.userMap,
                                            onProgress: (progress) {
                                              setState(() {
                                                downloadProgress = progress;
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Divider(endIndent: 20, indent: 20),
                                  listTileMethod(
                                    context,
                                    "Video",
                                    "",
                                    Icons.video_file_rounded,
                                    () {
                                      MsgChatroomFunctions.pickVideo((
                                        pickedFile,
                                      ) async {
                                        await MsgChatroomFunctions.uploadVideo(
                                          videoFile: pickedFile,
                                          userMap: widget.userMap,
                                          onProgress: (progress) {
                                            setState(() {
                                              downloadProgress = progress;
                                            });
                                          },
                                        );
                                      });
                                      // ImgAudDocChatroomFunctions.getImage((
                                      //   pickedFile,
                                      // ) async {
                                      //   await ImgAudDocChatroomFunctions.uploadImage(
                                      //     imageFile: pickedFile,
                                      //     userMap: widget.userMap,
                                      //     onProgress: (progress) {
                                      //       setState(() {
                                      //         downloadProgress = progress;
                                      //       });
                                      //     },
                                      //   );
                                      // });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: Image.asset(
                      'assets/images/file path.png',
                      height: 24.h,
                      width: 24.w,
                      color: Color.fromARGB(255, 0, 14, 8),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    height: size.height / 17,
                    width: size.width / 1.7,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 243, 246, 246),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextFormField(
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: _message,
                      decoration: InputDecoration(
                        hintText: "Write your message",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Color.fromARGB(255, 121, 124, 123),
                        ),
                      ),
                      cursorColor: Color.fromARGB(255, 32, 160, 145),
                    ),
                  ),
                  Row(
                    children: [
                      if (showSendButton)
                        IconButton(
                          onPressed: () {
                            _sendController.reset();
                            _sendController.forward();
                            MsgChatroomFunctions.sendTextMessage(
                              messageText: _message.text.trim(),
                              userMap: widget.userMap,
                              messageController: _message,
                            );
                          },
                          icon: Image.asset(
                            'assets/images/send message.png',
                            height: 40.h,
                            width: 40.w,
                          ),
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  () => ImgAudDocChatroomFunctions.getCameraImage((
                                    pickedFile,
                                  ) async {
                                    await ImgAudDocChatroomFunctions.uploadImage(
                                      imageFile: pickedFile,
                                      userMap: widget.userMap,
                                      onProgress: (progress) {
                                        setState(() {
                                          downloadProgress = progress;
                                        });
                                      },
                                    );
                                  }),
                              icon: Icon(
                                Icons.camera_alt_outlined,
                                color: Color.fromARGB(255, 0, 14, 8),
                              ),
                              iconSize: 30,
                            ),
                            IconButton(
                              iconSize: 30,
                              icon: Icon(
                                isRecording
                                    ? Icons.stop
                                    : Icons.mic_none_rounded,
                              ),
                              onPressed: () async {
                                await _voiceNoteHelper.toggleRecording(
                                  onRecordingChanged: (recording, path) {
                                    setState(() {
                                      isRecording = recording;
                                      audioPath = path;
                                    });
                                  },
                                  userMap: widget.userMap,
                                  chatRoomId: widget.chatRoomId,
                                  onProgress: (progress) {
                                    downloadProgress = progress;
                                  },
                                );
                              },
                              color:
                                  isRecording
                                      ? Colors.red
                                      : Color.fromARGB(255, 0, 14, 8),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 60),
      //   child: FloatingActionButton(
      //     shape: CircleBorder(),
      //     mini: true,
      //     backgroundColor: Colors.white70,
      //     child: Icon(Icons.keyboard_double_arrow_down_rounded),
      //     onPressed: () {},
      //   ),
      // ),
    );
  }

  ListTile listTileMethod(
    BuildContext context,
    String title,
    String subtitle,
    // String image,
    // IconData icon,
    dynamic imageOrIcon,
    void Function() onPressed,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.all(10),
      horizontalTitleGap: 0,
      leading: CircleAvatar(
        radius: 44.r,
        backgroundColor: Color.fromARGB(255, 242, 248, 247),
        child:
            imageOrIcon is String
                ? Image.asset(
                  imageOrIcon,
                  height: 18.h,
                  width: 20.w,
                  color: Color.fromARGB(255, 121, 124, 123),
                )
                : Icon(
                  imageOrIcon as IconData,
                  size: 20.w,
                  color: Color.fromARGB(255, 121, 124, 123),
                ),
      ),
      title: Text(title),
      titleTextStyle: TextStyle(
        fontFamily: 'cretype  Caros-Bold',
        color: Colors.black,
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      subtitleTextStyle: TextStyle(
        fontFamily: 'CircularStd-Book',
        color: Color.fromARGB(255, 121, 124, 123),
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      onTap: onPressed,
    );
  }
}
