import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Back button + title (+ optional subtitle) banner. Port of
/// `src/components/common/PageTitleBar.jsx`.
class PageTitleBar extends StatelessWidget {
  const PageTitleBar({
    super.key,
    required this.title,
    this.subtitle = '',
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgPageTitle,
      padding: const EdgeInsets.fromLTRB(4, 2, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 2),
              child: Text(
                subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
