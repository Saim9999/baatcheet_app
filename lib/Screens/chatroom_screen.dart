import 'package:baatcheet_app/functions/chatroom_img_aud_doc_functions.dart';
import 'package:baatcheet_app/functions/chatroom_message_widget.dart';
import 'package:baatcheet_app/functions/chatroom_msg_function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays > 6) {
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


  @override
  void initState() {
    super.initState();
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
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.amber,
      appBar: AppBar(
        toolbarHeight: 80.h,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Image.asset('assets/images/Back (1).png'),
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
                    height: 52.h,
                    width: 52.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(52.r),
                      image: DecorationImage(
                        image: NetworkImage(widget.userMap['profileImageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userMap['name'],
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        snapshot.data!['status'],
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
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    formatDateLabel(messageTime),
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
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
            child: SizedBox(
              height: size.height / 12,
              width: size.width / 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          content: Container(
                            height: 300.h,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.amber,
                                          CupertinoIcons.doc,
                                          () {
                                            // _pickDocument();
                                            ImgAudDocChatroomFunctions.pickDocFile(
                                              onDocPicked: (file) async {
                                                await ImgAudDocChatroomFunctions.uploadDocFileWithProgress(
                                                  chatRoomId: widget.chatRoomId,
                                                  docFile: file,
                                                  userMap: widget.userMap,
                                                  onProgress: (progress) {
                                                    setState(() {
                                                      downloadProgress =
                                                          progress;
                                                    });
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Document',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.deepOrange,
                                          CupertinoIcons.camera,
                                          () {
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
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Camera',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.deepPurple,
                                          CupertinoIcons.photo_fill,
                                          () {
                                            // getImage();
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
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Gallery',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.cyan,
                                          CupertinoIcons.headphones,
                                          () async {
                                            // _pickAudioFile();
                                            ImgAudDocChatroomFunctions.pickAudioFile(
                                              onAudioPicked: (file) async {
                                                await ImgAudDocChatroomFunctions.uploadAudioFileWithProgress(
                                                  chatRoomId: widget.chatRoomId,
                                                  audioFile: file,
                                                  userMap: widget.userMap,
                                                  onProgress: (progress) {
                                                    setState(() {
                                                      downloadProgress =
                                                          progress;
                                                    });
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Audio',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.brown,
                                          CupertinoIcons.location_solid,
                                          () {},
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Location',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.pinkAccent,
                                          CupertinoIcons.person,
                                          () {},
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Contact',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        containerWidget(
                                          Colors.purple,
                                          CupertinoIcons.chart_bar_alt_fill,
                                          () {},
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Poll',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    icon: Image.asset('assets/images/file path.png'),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    height: size.height / 10,
                    width: size.width / 1.6,
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
                        suffixIcon: IconButton(
                          // onPressed: () => getCameraImage(),
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
                          // icon: Image.asset('assets/images/camera image.png'),
                          icon: Icon(Icons.camera_alt_outlined),
                        ),
                        hintText: "Write your message",
                        border: InputBorder.none,
                      ),
                      cursorColor: Color.fromARGB(255, 32, 160, 145),
                    ),
                  ),
                  IconButton(
                    splashRadius: 50,
                    iconSize: 50,
                    onPressed: () {
                      _sendController.reset();
                      _sendController.forward();
                      // onSendMessage();
                      MsgChatroomFunctions.sendTextMessage(
                        messageText: _message.text.trim(),
                        userMap: widget.userMap,
                        messageController: _message,
                      );
                    },
                    icon: Lottie.asset(
                      'assets/animations/send_animation.json',
                      controller: _sendController,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          shape: CircleBorder(),
          mini: true,
          backgroundColor: Colors.white70,
          child: Icon(Icons.keyboard_double_arrow_down_rounded),
          onPressed: () {},
        ),
      ),
    );
  }

  Container containerWidget(
    Color color,
    IconData cupertinoIcons,
    void Function() onPressed,
  ) {
    return Container(
      height: 60.h,
      width: 60.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(60),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(cupertinoIcons, color: Colors.white, size: 30),
      ),
    );
  }
}
