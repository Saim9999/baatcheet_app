import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShowImage extends StatelessWidget {
  final String imageUrl;
  final String senderName;
  final String time;

  const ShowImage({
    required this.imageUrl,
    required this.senderName,
    required this.time,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(senderName, style: TextStyle(fontFamily: 'CircularStd-Book')),
            Text(
              time,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: 'CircularStd-Book',
                color: Color.fromARGB(255, 121, 124, 123),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: InteractiveViewer(
          panEnabled: false, // Set it to false
          boundaryMargin: EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2,
          child: Image.network(
            imageUrl,
          ),
        ),
      ),
    );
  }
}
