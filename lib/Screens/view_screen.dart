import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ViewScreen extends StatelessWidget {
  final String fileUrl;
  final String senderName;

  final Function(int)
  onPageCountLoaded; // Callback function to pass the total number of pages

  ViewScreen({
    required this.fileUrl,
    required this.senderName,
    required this.onPageCountLoaded,
    super.key,
  });

  PdfViewerController? _pdfViewerController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(senderName)),
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
