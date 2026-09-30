import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class KycUploadField extends StatefulWidget {
  final XFile? initialDocument;
  final Uint8List? initialDocumentBytes;
  final bool initialIsUploaded;
  final void Function(XFile? file, Uint8List? bytes) onChanged;

  const KycUploadField({
    super.key,
    this.initialDocument,
    this.initialDocumentBytes,
    this.initialIsUploaded = false,
    required this.onChanged,
  });

  @override
  State<KycUploadField> createState() => _KycUploadFieldState();
}

class _KycUploadFieldState extends State<KycUploadField> {
  final ImagePicker _picker = ImagePicker();
  XFile? _document;
  Uint8List? _documentBytes;
  bool _isUploaded = false;

  @override
  void initState() {
    super.initState();
    _document = widget.initialDocument;
    _documentBytes = widget.initialDocumentBytes;
    _isUploaded = widget.initialIsUploaded || _document != null || _documentBytes != null;
  }

  Future<void> _pickDocument() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _document = pickedFile;
        _documentBytes = bytes;
        _isUploaded = true;
      });
      widget.onChanged(_document, _documentBytes);
    }
  }

  void _removeDocument() {
    setState(() {
      _document = null;
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
        const Text(
          'KYC Verification',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload any one government ID for verification',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        // TODO: TEMPORARY — KYC document image is currently held only in local memory (XFile) for this session.
        // Once backend is connected, this image should be uploaded via a real API call (e.g., POST /api/user/kyc-upload)
        // and the response reference stored, rather than relying on local state alone.
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
                style: BorderStyle.solid, // solid or dashed
              ),
            ),
            child: _isUploaded
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _documentBytes != null
                              ? Image.memory(
                                  _documentBytes!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Text(
                                      'Document already uploaded',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file,
                          color: Colors.grey.shade500, size: 32),
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
