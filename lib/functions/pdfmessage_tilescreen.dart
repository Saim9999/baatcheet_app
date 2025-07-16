import 'package:baatcheet_app/Screens/view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfMessageTile extends StatefulWidget {
  final Map<String, dynamic> map;
  final String currentUserUid;
  final String cleanedFileName;
  const PdfMessageTile({
    super.key,
    required this.map,
    required this.currentUserUid,
    required this.cleanedFileName,
  });

  @override
  State<PdfMessageTile> createState() => _PdfMessageTileState();
}

class _PdfMessageTileState extends State<PdfMessageTile> {
  Future<Map<String, dynamic>>? _pdfInfoFuture;

  @override
  void initState() {
    super.initState();
    _pdfInfoFuture = getPdfInfo(widget.map['message']);
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
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _pdfInfoFuture,
      builder: (context, snapshot) {
        String subtitleText = "Loading PDF info...";
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            final size = snapshot.data!['size'];
            final pages = snapshot.data!['pages'];
            subtitleText = 'Pages: $pages | Size: $size';
          } else {
            subtitleText = 'Failed to load PDF info';
          }
        }

        return ListTile(
          horizontalTitleGap: 0.0,
          onTap: () {
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
          leading: Image.asset('assets/images/pdf.png', height: 30),
          title: Text(
            widget.cleanedFileName,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color:
                  widget.map['sendbyUid'] == widget.currentUserUid
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          subtitle: Text(subtitleText, style: TextStyle(fontSize: 12.sp)),
        );
      },
    );
  }
}
