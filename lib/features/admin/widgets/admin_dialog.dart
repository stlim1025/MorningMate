import 'package:flutter/material.dart';

class AdminWebDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double? width;
  final double? height;
  final IconData? titleIcon;
  final Color? headerColor;

  const AdminWebDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.width,
    this.height,
    this.titleIcon,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: width ?? MediaQuery.of(context).size.width * 0.8,
        height: height ?? 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: headerColor ?? Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(titleIcon,
                          size: 18, color: const Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ClipRRect(
                child: content,
              ),
            ),
            // Footer
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
