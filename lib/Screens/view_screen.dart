import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ViewScreen extends StatelessWidget {
  final String fileUrl;
  final String senderName;
  final String time;

  final Function(int)
  onPageCountLoaded; // Callback function to pass the total number of pages

  ViewScreen({
    super.key,
    required this.fileUrl,
    required this.senderName,
    required this.onPageCountLoaded,
    required this.time,
  });

  PdfViewerController? _pdfViewerController;

  @override
  Widget build(BuildContext context) {
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
      body: SfPdfViewer.network(
        fileUrl,
        controller: _pdfViewerController,
        onDocumentLoaded: (details) async {
          int totalPages = details.document.pages.count;
          print('Total pages in the PDF: $totalPages');
          onPageCountLoaded(totalPages);
        },
      ),
    );
  }
}
