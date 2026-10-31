import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_document.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final PatientDocument document;
  final VoidCallback onDelete;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(document.filePath);
    final exists = file.existsSync();
    final isImage = document.fileType == 'image' ||
        document.filePath.toLowerCase().endsWith('.jpg') ||
        document.filePath.toLowerCase().endsWith('.jpeg') ||
        document.filePath.toLowerCase().endsWith('.png');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          document.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            tooltip: 'Delete Document',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Delete Document?',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to remove "${document.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        onDelete();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: exists
                  ? (isImage
                      ? InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(),
                          ),
                        )
                      : _buildFallbackIcon(isDocument: true))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            size: 64, color: Colors.white54),
                        const SizedBox(height: 12),
                        Text(
                          'File not found at saved path',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                      ],
                    ),
            ),
          ),
          // Metadata bottom bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          document.fileType.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2DD4BF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.data_usage,
                          size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text('Size: ${document.fileSize}',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text('Uploaded: ${document.uploadedAt}',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Local Path: ${document.filePath}',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon({bool isDocument = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isDocument
              ? Icons.picture_as_pdf_outlined
              : Icons.insert_drive_file_outlined,
          size: 72,
          color: const Color(0xFF0D9488),
        ),
        const SizedBox(height: 16),
        Text(
          document.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Document stored locally in app sandbox',
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }
}
