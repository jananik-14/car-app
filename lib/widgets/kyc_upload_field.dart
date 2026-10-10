import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';

class KycUploadField extends StatefulWidget {
  final String? initialFileName;
  final Uint8List? initialDocumentBytes;
  final void Function(String? fileName, Uint8List? bytes) onChanged;

  const KycUploadField({
    super.key,
    this.initialFileName,
    this.initialDocumentBytes,
    required this.onChanged,
  });

  @override
  State<KycUploadField> createState() => _KycUploadFieldState();
}

class _KycUploadFieldState extends State<KycUploadField> {
  String? _fileName;
  Uint8List? _documentBytes;
  bool _isUploaded = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
    _documentBytes = widget.initialDocumentBytes;
    _isUploaded = _fileName != null;
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File must be less than 5 MB'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      setState(() {
        _fileName = result.files.single.name;
        _documentBytes = bytes;
        _isUploaded = true;
      });
      widget.onChanged(_fileName, _documentBytes);
    }
  }

  void _removeDocument() {
    setState(() {
      _fileName = null;
      _documentBytes = null;
      _isUploaded = false;
    });
    widget.onChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'KYC Verification *',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Required',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Upload any one government ID for verification (JPG/PNG/PDF, max 5MB)',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploaded ? null : _pickDocument,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: _isUploaded
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _fileName?.toLowerCase().endsWith('.pdf') == true
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: AppColors.primary,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _fileName ?? 'Document uploaded',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_documentBytes != null)
                                Text(
                                  '${(_documentBytes!.length / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeDocument,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _pickDocument,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Replace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: Colors.grey.shade500, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to Upload ID',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aadhaar, PAN, or Driving License',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
