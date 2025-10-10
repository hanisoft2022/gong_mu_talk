import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 메모리 효율적인 이미지 프리뷰 위젯
class OptimizedImagePreview extends StatefulWidget {
  const OptimizedImagePreview({
    super.key,
    required this.imageFile,
    required this.onRemove,
    this.size = 80,
  });

  final XFile imageFile;
  final VoidCallback onRemove;
  final double size;

  @override
  State<OptimizedImagePreview> createState() => _OptimizedImagePreviewState();
}

class _OptimizedImagePreviewState extends State<OptimizedImagePreview> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      // 한 번만 파일을 읽어서 메모리에 캐시
      final bytes = await widget.imageFile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widget.size,
      height: widget.size,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isLoading
                ? Container(
                    width: widget.size,
                    height: widget.size,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                    // 메모리 캐시 설정
                    cacheWidth: widget.size.toInt(),
                    cacheHeight: widget.size.toInt(),
                  )
                : Container(
                    width: widget.size,
                    height: widget.size,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.error, color: colorScheme.error),
                  ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.scrim.withValues(alpha: 0.54),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: colorScheme.onInverseSurface,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
