import 'package:flutter/material.dart';

import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class EvidenceDetailScreen extends StatelessWidget {
  const EvidenceDetailScreen({required this.evidence, super.key});

  final Evidence evidence;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final statusLabel = evidence.isLocked
        ? 'LOCKED'
        : evidence.isAnalyzed
            ? 'ANALYZED'
            : (evidence.isNew ? 'NEW' : 'PENDING');

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AppTokens.sp4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'EVIDENCE',
          style: AppText.monoLabel.copyWith(color: c.textMute),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.sp6),

                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.tealBase, AppColors.skyBase],
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r6),
                      border: Border.all(color: const Color(0x24FFFFFF)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      evidence.icon,
                      size: 34,
                      color: AppColors.ink0,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.sp4),

                Center(
                  child: Text(
                    evidence.name,
                    style: AppText.titleL.copyWith(color: c.text),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp2),

                Center(
                  child: Text(
                    evidence.location,
                    style: AppText.monoLabel.copyWith(color: c.textSub),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),

                Wrap(
                  spacing: AppTokens.sp2,
                  runSpacing: AppTokens.sp2,
                  alignment: WrapAlignment.center,
                  children: [
                    if (evidence.isLocked)
                      const MSPill('잠김', tone: MSPillTone.mute),
                    if (evidence.isAnalyzed)
                      const MSPill('분석완료', tone: MSPillTone.success)
                    else if (evidence.isNew)
                      const MSPill('NEW', tone: MSPillTone.primary)
                    else
                      const MSPill('대기', tone: MSPillTone.mute),
                  ],
                ),

                const SizedBox(height: AppTokens.sp6),

                Container(
                  padding: const EdgeInsets.all(AppTokens.sp4),
                  decoration: BoxDecoration(
                    color: c.bgElev,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(AppTokens.r4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const MSKicker('관찰 정보'),
                      const SizedBox(height: AppTokens.sp3),

                      Text(
                        evidence.isLocked
                            ? '이 증거는 잠겨 있습니다. 잠금 해제 후에만 상세 정보를 확인할 수 있어요.'
                            : evidence.isAnalyzed
                                ? '분석이 완료되었습니다. 해당 정보로 사건을 추리하세요.'
                                : '아직 분석되지 않았습니다. 관련 행동을 수행해 분석 상태를 진행하세요.',
                        style: AppText.body.copyWith(
                          color: c.text,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: AppTokens.sp4),

                      Row(
                        children: [
                          Expanded(
                            child: _MetaCell(
                              label: 'EVIDENCE ID',
                              value: evidence.id,
                            ),
                          ),
                          const SizedBox(width: AppTokens.sp3),
                          Expanded(
                            child: _MetaCell(
                              label: 'STATUS',
                              value: statusLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTokens.sp10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.monoLabel.copyWith(
              color: c.textMute,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: AppTokens.sp1),
          Text(
            value,
            style: AppText.bodySm.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

