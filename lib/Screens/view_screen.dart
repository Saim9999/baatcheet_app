import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ViewScreen extends StatelessWidget {
  final String fileUrl;

  final Function(int)
      onPageCountLoaded; // Callback function to pass the total number of pages

  ViewScreen({
    super.key,
    required this.fileUrl,
    required this.onPageCountLoaded,
  });

  PdfViewerController? _pdfViewerController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pdf View'),
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
