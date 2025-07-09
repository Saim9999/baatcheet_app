import 'package:audioplayers/audioplayers.dart';
import 'package:baatcheet_app/Screens/show_image_screen.dart';
import 'package:baatcheet_app/Screens/view_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class MessageWidget extends StatefulWidget {
  final Size size;
  final Map<String, dynamic> map;
  final String currentUserUid;
  final double downloadProgress;

  const MessageWidget({
    super.key,
    required this.size,
    required this.map,
    required this.currentUserUid,
    this.downloadProgress = 0.0,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool isPlaying = false;
  Map<String, AudioPlayer> audioPlayers = {};
  String? currentPlayingMessageId;
  Duration currentMessagePosition = Duration.zero;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  void dispose() {
    audioPlayers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.map['type'] == "text") {
      final bool isMe = widget.map['sendbyUid'] == widget.currentUserUid;
      return Container(
        width: widget.size.width,
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              constraints: BoxConstraints(maxWidth: widget.size.width * 0.75),
              decoration: BoxDecoration(
                borderRadius:
                    isMe
                        ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                        : const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                color:
                    isMe
                        ? const Color.fromARGB(255, 32, 160, 144)
                        : const Color.fromARGB(255, 242, 247, 251),
              ),
              child: Text(
                widget.map['message']?.toString() ?? '',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 10),
              child: Text(
                (widget.map['time'] != null)
                    ? DateFormat(
                      'hh:mm a',
                    ).format((widget.map['time'] as Timestamp).toDate())
                    : '',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Color.fromARGB(255, 121, 124, 123),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.map['type'] == "img") {
      return Column(
        crossAxisAlignment:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center,
        children: [
          Container(
            height: widget.size.height / 2.5,
            width: widget.size.width,
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            alignment:
                widget.map['sendbyUid'] == widget.currentUserUid
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child: InkWell(
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        print('SenderID: ${widget.map['sendby']}');
                        return ShowImage(
                          senderName: widget.map['sendby'],
                          imageUrl: widget.map['message'],
                        );
                      },
                      // (_) => ShowImage(imageUrl: widget.map['message']),
                    ),
                  ),
              child: Container(
                height: widget.size.height / 2.5,
                width: widget.size.width / 2,
                decoration: BoxDecoration(
                  borderRadius:
                      widget.map['sendbyUid'] == widget.currentUserUid
                          ? BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          )
                          : BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                  border: Border.all(
                    width: 3,
                    color:
                        widget.map['sendbyUid'] == widget.currentUserUid
                            ? Color.fromARGB(255, 32, 160, 144)
                            : Color.fromARGB(255, 242, 247, 251),
                  ),
                ),
                alignment:
                    widget.map['message'] != "" ? null : Alignment.center,
                child:
                    widget.map['message'] != ""
                        ? Image.network(
                          widget.map['message'],
                          fit: BoxFit.contain,
                        )
                        : Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 3.0,
                                value: widget.downloadProgress,
                                backgroundColor: Colors.grey,
                                color: Color.fromARGB(255, 32, 160, 145),
                              ),
                              SizedBox(height: 5.h),
                              Center(
                                child: Text(
                                  '${(100 * widget.downloadProgress).roundToDouble()}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
          Padding(
            padding:
                widget.map['sendbyUid'] == widget.currentUserUid
                    ? EdgeInsets.only(right: 10)
                    : EdgeInsets.only(right: 20),
            child: Text(
              (widget.map['time'] != null)
                  ? DateFormat(
                    'hh:mm a',
                  ).format((widget.map['time'] as Timestamp).toDate())
                  : '',
              style: TextStyle(
                fontSize: 10.sp,
                color: Color.fromARGB(255, 121, 124, 123),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      );
    } else if (widget.map['type'] == "file") {
      Uri fileUri = Uri.parse(widget.map['message']);
      String fileName =
          fileUri.pathSegments.isNotEmpty
              ? fileUri.pathSegments.last
              : fileUri.path;
      String cleanedFileName = fileName.substring(fileName.indexOf('/') + 1);

      return Container(
        // Widget for text messages
        alignment:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius:
                    widget.map['sendbyUid'] == widget.currentUserUid
                        ? BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                        : BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                color:
                    (widget.map['sendbyUid'] == widget.currentUserUid)
                        ? Color.fromARGB(255, 32, 160, 144)
                        : Color.fromARGB(255, 242, 247, 251),
              ),
              child:
                  widget.map['message'] != ""
                      ? ListTile(
                        horizontalTitleGap: 0.0,
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ViewScreen(
                                    fileUrl: widget.map['message'],
                                    senderName: widget.map['sendby'],
                                    onPageCountLoaded: (totalPages) {
                                      print(
                                        'Total pages received in the widget: $totalPages',
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                        leading: Image.asset(
                          'assets/images/pdf.png',
                          height: 30.h,
                        ),
                        title: Text(
                          cleanedFileName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color:
                                widget.map['sendbyUid'] == widget.currentUserUid
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      )
                      : Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 3.0,
                              value: widget.downloadProgress,
                              backgroundColor: Colors.grey,
                              color: Color.fromARGB(255, 32, 160, 145),
                            ),
                            SizedBox(height: 5.h),
                            Center(
                              child: Text(
                                '${(100 * widget.downloadProgress).roundToDouble()}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                (widget.map['time'] != null)
                    ? DateFormat(
                      'hh:mm a',
                    ).format((widget.map['time'] as Timestamp).toDate())
                    : '',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Color.fromARGB(255, 121, 124, 123),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.map['type'] == "audiofile") {
      Uri fileUri = Uri.parse(widget.map['message']);
      String fileName =
          fileUri.pathSegments.isNotEmpty
              ? fileUri.pathSegments.last
              : fileUri.path;
      String cleanedFileName = fileName.substring(fileName.indexOf('/') + 1);
      String messageId = cleanedFileName;

      if (!audioPlayers.containsKey(messageId)) {
        audioPlayers[messageId] = AudioPlayer();
        // Listen to states: playing, paused, stoped
        audioPlayers[messageId]!.onPlayerStateChanged.listen((state) {
          setState(() {
            isPlaying = state == PlayerState.playing;
          });
        });

        // Listen to audio duration
        audioPlayers[messageId]!.onDurationChanged.listen((newDuration) {
          setState(() {
            duration = newDuration;
          });
        });

        // Listen to audio position
        audioPlayers[messageId]!.onPositionChanged.listen((newPosition) {
          setState(() {
            if (currentPlayingMessageId == messageId) {
              currentMessagePosition = newPosition;
              position = newPosition; // Update the slider's position as well
            }
          });
        });
      }
      return Container(
        // Widget for text messages
        alignment:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              height: 90.h,
              decoration: BoxDecoration(
                borderRadius:
                    widget.map['sendbyUid'] == widget.currentUserUid
                        ? BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                        : BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                color:
                    (widget.map['sendbyUid'] == widget.currentUserUid)
                        ? Color.fromARGB(255, 32, 160, 144)
                        : Color.fromARGB(255, 242, 247, 251),
              ),
              child:
                  widget.map['message'] != ""
                      ? ListTile(
                        title: Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.headphones_rounded),
                              SizedBox(width: 5.w),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    overflow: TextOverflow.ellipsis,
                                    '$messageId.mp3',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          widget.map['sendbyUid'] ==
                                                  widget.currentUserUid
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Column(
                          children: [
                            Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: IconButton(
                                    onPressed: () async {
                                      final player = audioPlayers[messageId]!;

                                      if (player.state == PlayerState.playing) {
                                        await player.pause();
                                      } else {
                                        // Pause any currently playing audio
                                        if (currentPlayingMessageId != null &&
                                            currentPlayingMessageId !=
                                                messageId) {
                                          await audioPlayers[currentPlayingMessageId!]
                                              ?.pause();
                                        }

                                        await player.play(
                                          UrlSource(widget.map['message']),
                                        );
                                        setState(() {
                                          currentPlayingMessageId = messageId;
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      audioPlayers[messageId]!.state ==
                                              PlayerState.playing
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                  ),
                                ),
                                Slider(
                                  min: 0,
                                  max: duration.inSeconds.toDouble(),
                                  value:
                                      currentPlayingMessageId == messageId
                                          ? currentMessagePosition.inSeconds
                                              .toDouble()
                                          : 0,
                                  onChanged: (value) async {
                                    if (currentPlayingMessageId == messageId) {
                                      final position = Duration(
                                        seconds: value.toInt(),
                                      );
                                      await audioPlayers[messageId]!.seek(
                                        position,
                                      );
                                    }
                                  },
                                  thumbColor: Colors.amber,
                                  activeColor: Colors.grey,
                                  inactiveColor: Colors.amber,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: Text(
                                    currentPlayingMessageId == messageId
                                        ? formatTime(position)
                                        : '00:00',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ),
                                Text(
                                  currentPlayingMessageId == messageId
                                      ? formatTime(duration - position)
                                      : '00:00',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      : Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 3.0,
                              value: widget.downloadProgress,
                              backgroundColor: Colors.grey,
                              color: Color.fromARGB(255, 32, 160, 145),
                            ),
                            SizedBox(height: 5.h),
                            Center(
                              child: Text(
                                '${(100 * widget.downloadProgress).roundToDouble()}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                (widget.map['time'] != null)
                    ? DateFormat(
                      'hh:mm a',
                    ).format((widget.map['time'] as Timestamp).toDate())
                    : '',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Color.fromARGB(255, 121, 124, 123),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }
}
