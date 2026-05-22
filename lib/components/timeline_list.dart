import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class TimelineList extends StatelessWidget {
  const TimelineList(this.entries, {super.key});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        children: entries.map((e) => _Row(e)).toList(),
      ),
    );
  }
}

// ── 타임라인 행 ───────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row(this.entry);

  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bool hasConflict = entry.conflict != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              entry.time,
              style: AppText.monoLabel.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: hasConflict ? c.danger : c.primary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.sp2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.label,
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    color: c.text,
                    height: 1.45,
                  ),
                ),
                if (hasConflict) ...[
                  const SizedBox(height: AppTokens.sp2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.dangerSoft,
                      border: Border.all(color: c.danger),
                      borderRadius: BorderRadius.circular(AppTokens.r2),
                    ),
                    child: Text(
                      '⚠ ${entry.conflict}',
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        color: c.danger,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class TimelineListExample extends StatelessWidget {
  const TimelineListExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: TimelineList(sampleCase.timeline),
    );
  }
}