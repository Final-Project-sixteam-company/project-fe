import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

enum StatTone { neutral, good, warn }

class StatCell {
  final String label;
  final String value;
  final StatTone tone;

  const StatCell(
    this.label,
    this.value, {
    this.tone = StatTone.neutral,
  });
}

class MSStatRow extends StatelessWidget {
  final List<StatCell> cells;

  const MSStatRow(this.cells, {super.key});

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool bounded = constraints.hasBoundedWidth;
        final c = context.c;
        final List<Widget> children = [];

        for (int i = 0; i < cells.length; i++) {
          final cell = _buildCell(context, cells[i]);
          children.add(
            bounded
                ? Expanded(child: cell)
                : Flexible(child: IntrinsicWidth(child: cell)),
          );

          if (i < cells.length - 1) {
            children.add(
              Container(
                width: 1,
                color: c.line,
              ),
            );
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r3),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(BuildContext context, StatCell cell) {
    final c = context.c;
    Color valueColor;

    switch (cell.tone) {
      case StatTone.neutral:
        valueColor = c.text;
        break;
      case StatTone.good:
        valueColor = c.success;
        break;
      case StatTone.warn:
        valueColor = c.danger;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTokens.sp3,
        horizontal: AppTokens.sp2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cell.label.toUpperCase(),
            style: AppText.monoLabel.copyWith(
              fontSize: 9,
              letterSpacing: 9 * 0.14,
              color: c.textMute,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // 4개 이상일 때도 폰트 사이즈 고정, 넘치면 줄임표 처리
          ),
          const SizedBox(height: AppTokens.sp1),
          Text(
            cell.value,
            style: AppText.monoNum.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// [사용 예시]
// ----------------------------------------------------------------------
class MSStatRowExample extends StatelessWidget {
  const MSStatRowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          MSStatRow([
            StatCell('진행 시간', '14:22'),
            StatCell('확보 단서', '8/12', tone: StatTone.good),
            StatCell('위험도', '94%', tone: StatTone.warn),
          ]),
          SizedBox(height: 16),
          MSStatRow([
            StatCell('알리바이', '불확실', tone: StatTone.warn),
            StatCell('혈액형', 'AB'),
            StatCell('지문 일치', '100%', tone: StatTone.good),
            StatCell('접근 권한', '있음'),
          ]),
        ],
      ),
    );
  }
}
