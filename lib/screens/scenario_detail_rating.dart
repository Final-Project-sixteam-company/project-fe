// lib/screens/scenario_detail_rating.dart
import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class ScenarioRatingCard extends StatelessWidget {
  const ScenarioRatingCard({required this.scenario, super.key});
  final Scenario scenario;

  String _fmt(int p) => p >= 1000 ? '${(p / 1000).toStringAsFixed(1)}k' : '$p';
  static const _ratios = [0.68, 0.22, 0.07, 0.02, 0.01];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
          color: c.bgElev,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(children: [
          Text(scenario.rating.toStringAsFixed(1),
              style: AppText.monoNum.copyWith(
                  fontSize: AppTokens.fsD2,
                  fontWeight: FontWeight.w700,
                  color: c.primary, height: 1.0)),
          const SizedBox(height: AppTokens.sp1),
          Text('${_fmt(scenario.plays)}플레이',
              style: AppText.monoLabel.copyWith(
                  fontSize: AppTokens.fsSm, color: c.textMute)),
        ]),
        const SizedBox(width: AppTokens.sp6),
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star  = 5 - i;
              final ratio = _ratios[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.rowGap),
                child: Row(children: [
                  Text('$star',
                      style: AppText.monoLabel.copyWith(
                          fontSize: AppTokens.fsSm, color: c.textMute)),
                  const SizedBox(width: AppTokens.sp2),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.r1),
                      child: SizedBox(
                        height: AppTokens.sp2,
                        child: LayoutBuilder(
                          builder: (_, box) => Stack(children: [
                            Positioned.fill(
                                child: ColoredBox(color: c.bgHover)),
                            Positioned(
                              left: 0, top: 0, bottom: 0,
                              width: box.maxWidth * ratio,
                              child: DecoratedBox(
                                  decoration: BoxDecoration(color: c.primary)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
      ]),
    );
  }
}
