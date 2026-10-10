import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../utils/blob_storage.dart';

class ListingImage extends StatefulWidget {
  final Map<String, dynamic> listing;
  final int index;
  final double? height;
  final double? width;
  final BoxFit fit;

  const ListingImage({
    super.key,
    required this.listing,
    this.index = 0,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  State<ListingImage> createState() => _ListingImageState();
}

class _ListingImageState extends State<ListingImage> {
  static final Map<String, Uint8List> _bytesCache = {};
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ListingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing != widget.listing || oldWidget.index != widget.index) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    final String id = widget.listing['id']?.toString() ?? '';
    final String phone = widget.listing['sellerPhone']?.toString() ?? widget.listing['dealerPhone']?.toString() ?? 'unknown_phone';
    final baseKey = '$phone/$id';
    final targetKey = '$baseKey/photo_${widget.index}';

    if (_bytesCache.containsKey(targetKey)) {
      if (mounted) {
        setState(() {
          _imageBytes = _bytesCache[targetKey];
          _isLoading = false;
        });
      }
      return;
    }

    final blobStorage = BlobStorage();
    Uint8List? bytes = await blobStorage.get(targetKey);

    if (bytes == null && widget.index == 0) {
      for (int i = 1; i <= 5; i++) {
        bytes = await blobStorage.get('$baseKey/photo_$i');
        if (bytes != null) break;
      }
    }

    if (bytes != null) {
      _bytesCache[targetKey] = bytes;
    }

    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        color: const Color(0xFFF3F4F6),
      );
    }

    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Image.asset(
      'assets/images/logo.png',
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
    );
  }
}
