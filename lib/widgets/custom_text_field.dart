import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final Widget? prefixIcon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                prefixIcon: prefixIcon,
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                border: InputBorder.none,
                counterText: '', // Hide default counter
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
