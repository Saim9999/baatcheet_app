import 'package:audioplayers/audioplayers.dart';
import 'package:baatcheet_app/Screens/show_image_screen.dart';
import 'package:baatcheet_app/Screens/view_screen.dart';
import 'package:baatcheet_app/functions/chatroom_voicenote_screen.dart';
import 'package:baatcheet_app/helper/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:video_player/video_player.dart';

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
  Map<String, dynamic>? _pdfInfoCache;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  Widget _buildTickIcon(bool isMe, bool isRead) {
    if (!isMe) return SizedBox(); // show ticks only for sender

    return Icon(
      isRead ? Icons.done_all : Icons.check,
      size: 18,
      color: isRead ? Colors.blue : Colors.grey,
    );
  }

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    fetchPdfInfoOnce();
    _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.map['message']),
      )
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    _controller.addListener(() {
      setState(() {
        isPlaying = _controller.value.isPlaying;
      });
    });
  }

  Future<void> fetchPdfInfoOnce() async {
    final info = await getPdfInfo(widget.map['message']);
    if (mounted) {
      setState(() {
        _pdfInfoCache = info;
      });
    }
  }

  Future<Map<String, dynamic>> getPdfInfo(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final document = PdfDocument(inputBytes: bytes);
        final sizeInKB = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
        final pageCount = document.pages.count;
        return {'size': '$sizeInKB KB', 'pages': pageCount};
      } else {
        throw Exception('Failed to load PDF');
      }
    } catch (e) {
      print("📄 Error loading PDF info: $e");
      return {'size': 'Unknown', 'pages': 0};
    }
  }

  @override
  void dispose() {
    // Stop and release all audio players
    _controller.dispose();
    for (var player in audioPlayers.values) {
      player.stop();
      player.dispose(); // optional but recommended for cleanup
    }
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
                  fontFamily: 'CircularStd-Book',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                  SizedBox(width: 4),
                  _buildTickIcon(isMe, widget.map['isRead'] ?? false),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (widget.map['type'] == "img") {
      final bool isMe = widget.map['sendbyUid'] == widget.currentUserUid;
      return Column(
        crossAxisAlignment:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        children: [
          Container(
            height: widget.size.height / 3.7,
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
                          // senderName: widget.map['sendby'],
                          senderName:
                              widget.map['sendbyUid'] == widget.currentUserUid
                                  ? "You"
                                  : widget.map['sendby'],
                          imageUrl: widget.map['message'],
                          time:
                              (widget.map['time'] != null)
                                  ? DateFormat('d MMMM, hh:mm a').format(
                                    (widget.map['time'] as Timestamp).toDate(),
                                  )
                                  : '',
                        );
                      },
                    ),
                  ),
              child:
                  widget.map['message'] != ""
                      ? ClipRRect(
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
                        child: Container(
                          height: widget.size.height / 3.7,
                          width: widget.size.width / 1.5,
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
                              width: 2,
                              color:
                                  widget.map['sendbyUid'] ==
                                          widget.currentUserUid
                                      ? Color.fromARGB(255, 32, 160, 144)
                                      : Color.fromARGB(255, 242, 247, 251),
                            ),
                          ),
                          child: Image.network(
                            widget.map['message'],
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.low,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              final progress =
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null;
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 3.0,
                                      value: progress,
                                      backgroundColor: Colors.grey,
                                      color: const Color.fromARGB(
                                        255,
                                        32,
                                        160,
                                        145,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
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
                                  color: Color.fromARGB(255, 32, 160, 145),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          Padding(
            padding:
                widget.map['sendbyUid'] == widget.currentUserUid
                    ? EdgeInsets.only(right: 10)
                    : EdgeInsets.only(left: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                SizedBox(width: 4),
                _buildTickIcon(isMe, widget.map['isRead'] ?? false),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
      );
    } else if (widget.map['type'] == "file") {
      final bool isMe = widget.map['sendbyUid'] == widget.currentUserUid;
      Uri fileUri = Uri.parse(widget.map['message']);
      String fileName =
          fileUri.pathSegments.isNotEmpty
              ? fileUri.pathSegments.last
              : fileUri.path;
      String cleanedFileName = fileName.substring(fileName.indexOf('/') + 1);

      return Container(
        margin:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? EdgeInsets.only(left: 80, top: 8, bottom: 8)
                : EdgeInsets.only(right: 80, top: 8, bottom: 8),
        padding:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? EdgeInsets.only(right: 10)
                : EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin:
                  widget.map['sendbyUid'] == widget.currentUserUid
                      ? EdgeInsets.only(left: 20)
                      : EdgeInsets.only(right: 20),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ViewScreen(
                                    fileUrl: widget.map['message'],
                                    // senderName: widget.map['sendby'],
                                    senderName:
                                        widget.map['sendbyUid'] ==
                                                widget.currentUserUid
                                            ? "You"
                                            : widget.map['sendby'],
                                    time:
                                        (widget.map['time'] != null)
                                            ? DateFormat(
                                              'd MMMM, hh:mm a',
                                            ).format(
                                              (widget.map['time'] as Timestamp)
                                                  .toDate(),
                                            )
                                            : '',

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
                          height: 30,
                        ),
                        minLeadingWidth: 35,
                        title: Text(
                          cleanedFileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'CircularStd-Book',
                            color:
                                widget.map['sendbyUid'] == widget.currentUserUid
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          _pdfInfoCache == null
                              ? "Loading PDF info..."
                              : "Size: ${_pdfInfoCache!['size']} | Pages: ${_pdfInfoCache!['pages']}",
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'CircularStd-Book',
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                  SizedBox(width: 4),
                  _buildTickIcon(isMe, widget.map['isRead'] ?? false),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (widget.map['type'] == "audiofile") {
      final bool isMe = widget.map['sendbyUid'] == widget.currentUserUid;
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
          if (mounted) {
            setState(() {
              isPlaying = state == PlayerState.playing;
            });
          }
        });
        // Listen to audio duration
        audioPlayers[messageId]!.onDurationChanged.listen((newDuration) {
          if (mounted) {
            setState(() {
              duration = newDuration;
            });
          }
        });
        // Listen to audio position
        audioPlayers[messageId]!.onPositionChanged.listen((newPosition) {
          if (mounted) {
            setState(() {
              if (currentPlayingMessageId == messageId) {
                currentMessagePosition = newPosition;
                position = newPosition; // Update the slider's position as well
              }
            });
          }
        });
      }
      return Container(
        margin:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? EdgeInsets.only(right: 10)
                : EdgeInsets.only(left: 10),
        alignment:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? Alignment.centerRight
                : Alignment.centerLeft,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              // margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              margin:
                  widget.map['sendbyUid'] == widget.currentUserUid
                      ? EdgeInsets.only(left: 70)
                      : EdgeInsets.only(right: 70),
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
                      ? Row(
                        children: [
                          SizedBox(width: 10.w),
                          CircleAvatar(
                            radius: 30.r,
                            backgroundColor:
                                widget.map['sendbyUid'] == widget.currentUserUid
                                    ? secondaryClr
                                    : primaryClr,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  color:
                                      widget.map['sendbyUid'] ==
                                              widget.currentUserUid
                                          ? primaryClr
                                          : secondaryClr,
                                ),
                                Text(
                                  currentPlayingMessageId == messageId
                                      ? formatTime(duration - position)
                                      : '00:00',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        widget.map['sendbyUid'] ==
                                                widget.currentUserUid
                                            ? primaryClr
                                            : secondaryClr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        final player = audioPlayers[messageId]!;
                                        if (player.state ==
                                            PlayerState.playing) {
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
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                      iconSize: 32.0,
                                      color:
                                          widget.map['sendbyUid'] ==
                                                  widget.currentUserUid
                                              ? Color.fromARGB(
                                                255,
                                                242,
                                                247,
                                                251,
                                              )
                                              : Color.fromARGB(
                                                255,
                                                32,
                                                160,
                                                144,
                                              ),
                                    ),
                                    SizedBox(
                                      width: 122.w,
                                      child: Slider(
                                        min: 0,
                                        max: duration.inSeconds.toDouble(),
                                        value:
                                            currentPlayingMessageId == messageId
                                                ? currentMessagePosition
                                                    .inSeconds
                                                    .toDouble()
                                                : 0,
                                        onChanged: (value) async {
                                          if (currentPlayingMessageId ==
                                              messageId) {
                                            final position = Duration(
                                              seconds: value.toInt(),
                                            );
                                            await audioPlayers[messageId]!.seek(
                                              position,
                                            );
                                          }
                                        },
                                        activeColor: Colors.white,
                                        inactiveColor: Color.fromARGB(
                                          255,
                                          129,
                                          203,
                                          194,
                                        ),
                                        thumbColor: Colors.white,
                                        padding: EdgeInsets.all(0),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      overflow: TextOverflow.ellipsis,
                                      messageId,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'CircularStd-Book',
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
                        ],
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
              padding: const EdgeInsets.only(right: 10, top: 8, left: 10),
              child: Row(
                mainAxisSize:
                    widget.map['sendbyUid'] == widget.currentUserUid
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                children: [
                  Text(
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
                  SizedBox(width: 4),
                  _buildTickIcon(isMe, widget.map['isRead'] ?? false),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (widget.map['type'] == "voice") {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final isSender = widget.map['sendbyUid'] == currentUser.uid;
      return VoiceMessageWidget(map: widget.map, isSender: isSender);
    } else if (widget.map['type'] == "video") {
      final bool isMe = widget.map['sendbyUid'] == widget.currentUserUid;
      return Column(
        crossAxisAlignment:
            widget.map['sendbyUid'] == widget.currentUserUid
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        children: [
          Container(
            height: widget.size.height / 3.7,
            width: widget.size.width / 1.2,
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            alignment:
                widget.map['sendbyUid'] == widget.currentUserUid
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child:
                widget.map['message'] != ""
                    ? ClipRRect(
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
                      child: Container(
                        height: widget.size.height / 3.7,
                        width: widget.size.width / 1.5,
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
                            width: 2,
                            color:
                                widget.map['sendbyUid'] == widget.currentUserUid
                                    ? Color.fromARGB(255, 32, 160, 144)
                                    : Color.fromARGB(255, 242, 247, 251),
                          ),
                        ),
                        child:
                            _controller.value.isInitialized
                                ? SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AspectRatio(
                                        aspectRatio:
                                            _controller.value.aspectRatio,
                                        child: VideoPlayer(_controller),
                                      ),
                                      SizedBox(height: 8),
                                      VideoProgressIndicator(
                                        _controller,
                                        allowScrubbing: true,
                                        colors: VideoProgressColors(
                                          playedColor: Colors.blue,
                                          bufferedColor: Colors.grey,
                                          backgroundColor: Colors.black12,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 30,
                                            ),
                                            onPressed: () {
                                              isPlaying
                                                  ? _controller.pause()
                                                  : _controller.play();
                                            },
                                          ),
                                          Text(
                                            '${formatTime(_controller.value.position)} / ${formatTime(_controller.value.duration)}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                : SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
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
                                color: Color.fromARGB(255, 32, 160, 145),
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),

          Padding(
            padding:
                widget.map['sendbyUid'] == widget.currentUserUid
                    ? EdgeInsets.only(right: 10)
                    : EdgeInsets.only(left: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                SizedBox(width: 4),
                _buildTickIcon(isMe, widget.map['isRead'] ?? false),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }
}
