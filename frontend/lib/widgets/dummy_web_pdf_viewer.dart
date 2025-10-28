import 'package:flutter/material.dart';

class WebPdfViewer extends StatelessWidget {
  final String fileUrl;
  const WebPdfViewer({Key? key, required this.fileUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Web PDF viewer not available on this platform'),
    );
  }
} 