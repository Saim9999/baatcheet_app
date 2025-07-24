import 'package:audioplayers/audioplayers.dart';
import 'package:baatcheet_app/helper/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Map<String, dynamic> map;
  final bool isSender;
  final double downloadProgress;

  const VoiceMessageWidget({
    super.key,
    required this.map,
    required this.isSender,
    this.downloadProgress = 0.0,
  });

  @override
  _VoiceMessageWidgetState createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  Widget _buildTickIcon(bool isMe, bool isRead) {
    if (!isMe) return SizedBox(); // show ticks only for sender

    return Icon(
      isRead ? Icons.done_all : Icons.check,
      size: 18,
      color: isRead ? Colors.blue : Colors.grey,
    );
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.map['type'] != "voice" || widget.map['voiceNote'] == null) {
      return SizedBox.shrink();
    }

    final voiceUrl = widget.map['voiceNote'];
    final timestamp =
        widget.map['time'] != null
            ? DateFormat(
              'h:mm a',
            ).format((widget.map['time'] as Timestamp).toDate())
            : '';

    return Container(
      alignment:
          widget.map['sendbyUid'] == widget.map['sendby']
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            // margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            margin:
                widget.isSender
                    ? EdgeInsets.only(left: 80, right: 8, top: 8, bottom: 8)
                    : EdgeInsets.only(right: 80, left: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: widget.isSender ? primaryClr : secondaryClr,
              borderRadius:
                  widget.isSender
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
            ),
            child:
                widget.map['message'] != ""
                    ? Row(
                      children: [
                        IconButton( 
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: widget.isSender ? secondaryClr : primaryClr,
                            size: 34.r,
                          ),
                          onPressed: () async {
                            if (_isPlaying) {
                              await _audioPlayer.pause();
                            } else {
                              await _audioPlayer.play(UrlSource(voiceUrl));
                            }
                          },
                        ),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 122.w,
                                child: Slider(
                                  activeColor: Colors.white,
                                  inactiveColor: Color.fromARGB(
                                    255,
                                    129,
                                    203,
                                    194,
                                  ),
                                  thumbColor: Colors.white,
                                  padding: EdgeInsets.all(0),
                                  min: 0,
                                  max: _duration.inSeconds.toDouble(),
                                  value:
                                      _position.inSeconds
                                          .clamp(0, _duration.inSeconds)
                                          .toDouble(),
                                  onChanged: (value) async {
                                    final position = Duration(
                                      seconds: value.toInt(),
                                    );
                                    await _audioPlayer.seek(position);
                                  },
                                ),
                              ),
                              SizedBox(width: 15.w),
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.black,
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
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: Row(
              mainAxisSize:
                  widget.isSender ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Color.fromARGB(255, 121, 124, 123),
                  ),
                ),
                SizedBox(width: 4),
                _buildTickIcon(widget.isSender, widget.map['isRead'] ?? false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
