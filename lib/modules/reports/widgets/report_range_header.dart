import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportRangeHeader extends StatelessWidget {
  const ReportRangeHeader({
    super.key,
    required this.range,
    required this.onPick,
    this.title,
    this.trailing,
  });

  final DateTimeRange range;
  final VoidCallback onPick;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('d MMM yyyy');
    final rangeText =
        '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'reports.range.title'.tr,
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rangeText,
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.date_range_rounded),
              label: Text('reports.range.edit'.tr),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
