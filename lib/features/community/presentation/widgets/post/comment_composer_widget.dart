/// Comment composer widget for writing and submitting comments
///
/// Responsibilities:
/// - Text input field for comments
/// - Image picker and preview
/// - Upload progress indicator
/// - Submit button with validation
/// - Single image limitation for comments
///
/// Used by: PostCard

library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class CommentComposer extends StatelessWidget {
  const CommentComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedImages,
    required this.isSubmitting,
    required this.isUploadingImages,
    required this.uploadProgress,
    required this.canSubmit,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmit,
    this.enabled = true,
    this.onDisabledTap,
    this.hintText = '댓글을 입력하세요...',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<XFile> selectedImages;
  final bool isSubmitting;
  final bool isUploadingImages;
  final double uploadProgress;
  final bool canSubmit;
  final VoidCallback onPickImages;
  final void Function(int index) onRemoveImage;
  final VoidCallback onSubmit;
  final bool enabled;
  final VoidCallback? onDisabledTap;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text input field
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: !enabled,
          onTap: !enabled ? onDisabledTap : null,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 60, 10),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker button
                IconButton(
                  icon: const Icon(Icons.image_outlined, size: 20),
                  onPressed: enabled ? onPickImages : onDisabledTap,
                  tooltip: '이미지 첨부',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                // Submit button
                IconButton(
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  onPressed: enabled && canSubmit && !isSubmitting ? onSubmit : (!enabled ? onDisabledTap : null),
                  tooltip: '댓글 등록',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),

        // Image preview
        if (selectedImages.isNotEmpty) ...[
          const Gap(8),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: index < selectedImages.length - 1 ? 8 : 0,
                  ),
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(selectedImages[index].path),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        // Upload progress indicator
        if (isUploadingImages) ...[
          const Gap(8),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: uploadProgress,
                ),
              ),
              const Gap(8),
              Text('업로드 중... ${(uploadProgress * 100).toInt()}%'),
              const Gap(12),
              Expanded(
                child: LinearProgressIndicator(
                  value: uploadProgress,
                  minHeight: 2,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
