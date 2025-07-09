
import 'package:flutter/material.dart';

class ShowImage extends StatelessWidget {
  final String imageUrl;
  final String senderName;

  const ShowImage({
    required this.imageUrl,
    required this.senderName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(senderName),
      ),
        body: Container(
      height: size.height,
      width: size.width,
      color: Colors.black,
      child: Image.network(imageUrl),
    ));
  }
}
