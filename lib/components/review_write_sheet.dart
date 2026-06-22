// lib/components/review_write_sheet.dart
import 'package:flutter/material.dart';
import '../models/review_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'ms_button.dart';

/// 리뷰 작성 바텀시트를 띄우고, 등록 시 작성된 [ScenarioReview]를 반환한다.
/// (취소/닫기 시 null) — 시나리오 상세·결과 화면 양쪽에서 재사용한다.
Future<ScenarioReview?> showReviewWriteSheet(
    BuildContext context, {
      required String scenarioId,
    }) {
  return showModalBottomSheet<ScenarioReview>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => ReviewWriteSheet(scenarioId: scenarioId),
  );
}

class ReviewWriteSheet extends StatefulWidget {
  const ReviewWriteSheet({required this.scenarioId, super.key});

  final String scenarioId;

  @override
  State<ReviewWriteSheet> createState() => _ReviewWriteSheetState();
}

class _ReviewWriteSheetState extends State<ReviewWriteSheet> {
  double _rating = 5.0;
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _isSpoiler = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElev,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTokens.r6),
            topRight: Radius.circular(AppTokens.r6),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.sp4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AppTokens.handleW,
                    height: AppTokens.handleH,
                    margin: const EdgeInsets.only(bottom: AppTokens.sp4),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(AppTokens.rPill),
                    ),
                  ),
                ),
                Text(
                  '리뷰 작성',
                  style: AppText.titleM.copyWith(color: c.text),
                ),
                const SizedBox(height: AppTokens.sp4),
                // 별점 슬라이더
                Row(
                  children: [
                    Text(
                      '평점',
                      style: AppText.body.copyWith(color: c.textSub),
                    ),
                    const Spacer(),
                    Text(
                      '★ ${_rating.toStringAsFixed(1)}',
                      style: AppText.monoNum.copyWith(
                        fontSize: AppTokens.fsXl2,
                        color: c.primary,
                        height: AppTokens.lhLabel,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: c.primary,
                  inactiveColor: c.bgHover,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: AppTokens.sp3),
                // 리뷰 본문
                Container(
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                  ),
                  child: TextField(
                    controller: _bodyCtrl,
                    maxLines: 4,
                    style: AppText.body.copyWith(color: c.text),
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      hintText: '이 사건은 어떠셨나요?',
                      hintStyle: AppText.body.copyWith(color: c.textMute),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppTokens.sp3),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.sp3),
                // 스포일러 토글
                Row(
                  children: [
                    Switch(
                      value: _isSpoiler,
                      activeThumbColor: c.danger,
                      onChanged: (v) => setState(() => _isSpoiler = v),
                    ),
                    const SizedBox(width: AppTokens.sp2),
                    Text(
                      '스포일러 포함',
                      style: AppText.body.copyWith(
                        color: _isSpoiler ? c.danger : c.textSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.sp4),
                MSButton(
                  label: '리뷰 등록',
                  variant: MSButtonVariant.primary,
                  expanded: true,
                  onPressed: () {
                    final body = _bodyCtrl.text.trim();
                    if (body.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('리뷰 내용을 입력해 주세요.')),
                      );
                      return;
                    }
                    final review = ScenarioReview(
                      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                      scenarioId: widget.scenarioId,
                      authorName: '나',
                      rating: _rating,
                      body: body,
                      createdAt: DateTime.now(),
                      isSpoiler: _isSpoiler,
                    );
                    Navigator.of(context).pop(review);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}