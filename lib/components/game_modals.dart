// lib/components/game_modals.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../models/sample_case.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 힌트 모달 ─────────────────────────────────────────────────────────────────

Future<void> showHintModal(BuildContext context, {required int sessionId}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _HintSheet(sessionId: sessionId),
  );
}

class _HintSheet extends StatefulWidget {
  const _HintSheet({required this.sessionId});

  final int sessionId;

  @override
  State<_HintSheet> createState() => _HintSheetState();
}

class _HintSheetState extends State<_HintSheet> {
  bool _loading = true;
  String? _error;
  List<PlayHint> _hints = const [];
  int? _usingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hints = await playSessionRepo.hints(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _hints = hints;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '힌트를 불러오지 못했습니다.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _use(PlayHint hint) async {
    if (_usingId != null) return;
    setState(() => _usingId = hint.hintId);
    try {
      await playSessionRepo.useHint(widget.sessionId, hint.hintId);
      await _load(); // 사용 후 content/사용 상태 갱신
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('힌트 사용 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _usingId = null);
    }
  }

  static String _levelLabel(int level) => switch (level) {
        1 => '방향 힌트',
        2 => '증거 연결 힌트',
        3 => '결정적 힌트',
        _ => '힌트',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final usedPenalty =
        _hints.where((h) => h.isUsed).fold(0, (s, h) => s + h.penaltyScore);

    return Container(
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
              // ── 드래그 핸들 ──────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTokens.sp4),
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(AppTokens.rPill),
                  ),
                ),
              ),
              // ── 제목 ─────────────────────────────────────────────
              Text(
                '힌트 요청',
                style: AppText.titleL.copyWith(color: c.text),
              ),
              const SizedBox(height: AppTokens.sp2),
              Text(
                '힌트 사용 시 최종 점수가 감점됩니다.',
                style: AppText.bodySm.copyWith(color: c.danger),
              ),
              // ── 누적 감점 표시 ───────────────────────────────────
              if (usedPenalty > 0) ...[
                const SizedBox(height: AppTokens.sp3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.sp3,
                    vertical: AppTokens.sp2,
                  ),
                  decoration: BoxDecoration(
                    color: c.dangerSoft,
                    border: Border.all(color: c.danger),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                  ),
                  child: Text(
                    '누적 감점: -$usedPenalty점',
                    style: AppText.monoLabel.copyWith(color: c.danger),
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.sp6),
              // ── 힌트 목록 ────────────────────────────────────────
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTokens.sp6),
                  child: Center(child: MSSpinner(size: 20)),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.sp6),
                  child: MSEmpty(
                    icon: Icons.cloud_off,
                    title: '힌트를 불러오지 못했습니다',
                    action: MSButton(
                      label: '다시 시도',
                      variant: MSButtonVariant.secondary,
                      onPressed: _load,
                    ),
                  ),
                )
              else
                ..._hints.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.sp3),
                    child: _HintTile(
                      hint: h,
                      label: _levelLabel(h.hintLevel),
                      busy: _usingId == h.hintId,
                      onUse: () => _use(h),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintTile extends StatelessWidget {
  const _HintTile({
    required this.hint,
    required this.label,
    required this.busy,
    required this.onUse,
  });

  final PlayHint hint;
  final String label;
  final bool busy;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    // 사용 완료: 라벨 + 힌트 내용 표시
    if (hint.isUsed) {
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.monoLabel.copyWith(color: c.textSub),
                  ),
                ),
                Text(
                  '-${hint.penaltyScore}점',
                  style: AppText.monoLabel.copyWith(color: c.danger),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.sp2),
            Text(
              hint.content ?? '',
              style: AppText.body.copyWith(
                fontSize: 13,
                color: c.text,
                height: 1.55,
              ),
            ),
          ],
        ),
      );
    }

    // 잠김: 해금 대기 시간 안내(비활성)
    if (!hint.isAvailable) {
      final mins = hint.remainingMinutes;
      final suffix = (mins != null && mins > 0) ? ' · $mins분 후 해금' : ' · 잠김';
      return MSButton(
        label: '$label$suffix',
        variant: MSButtonVariant.ghost,
        icon: Icons.lock_outline,
        expanded: true,
        onPressed: null,
      );
    }

    // 사용 가능: 사용 버튼
    return MSButton(
      label: busy ? '사용 중...' : '$label (-${hint.penaltyScore}점)',
      variant: hint.hintLevel >= 3
          ? MSButtonVariant.danger
          : MSButtonVariant.secondary,
      expanded: true,
      onPressed: busy ? null : onUse,
    );
  }
}

// ── 증거 제시 모달 ────────────────────────────────────────────────────────────

Future<Evidence?> showEvidencePresentModal(BuildContext context) {
  // 제시 가능한(해금된) 증거를 미리 읽어서 Sheet에 전달한다.
  // showModalBottomSheet는 새 루트 컨텍스트를 만들기 때문에
  // Sheet 내부에서 GameSessionProvider를 찾을 수 없다.
  //
  // 서버 연동 세션의 evidence는 백엔드 정수 ID를 가지므로(증거 제시 API에 필요)
  // controller.evidences 를 우선 사용하고, 비어 있거나 없으면 sampleCase로 폴백한다.
  List<Evidence> accessible;
  try {
    final serverEvidences = GameSessionProvider.read(context).evidences;
    accessible = serverEvidences.isNotEmpty
        ? serverEvidences.where((e) => !e.isLocked).toList()
        : sampleCase.evidences.where((e) => !e.isLocked).toList();
  } catch (_) {
    // GameSessionProvider가 없는 컨텍스트(미리보기 등)에서는 샘플로 폴백
    accessible = sampleCase.evidences.where((e) => !e.isLocked).toList();
  }

  return showModalBottomSheet<Evidence>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _EvidencePresentSheet(evidences: accessible),
  );
}

class _EvidencePresentSheet extends StatefulWidget {
  const _EvidencePresentSheet({required this.evidences});

  /// 제시 가능한(해금된) 증거 목록. 서버 연동 시 백엔드 정수 ID를 가진다.
  final List<Evidence> evidences;

  @override
  State<_EvidencePresentSheet> createState() =>
      _EvidencePresentSheetState();
}

class _EvidencePresentSheetState extends State<_EvidencePresentSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 제시 가능한 증거(이미 해금된 것)에서 검색어로 필터링한다.
  List<Evidence> get _filtered {
    if (_query.isEmpty) return widget.evidences;
    return widget.evidences
        .where(
          (e) => e.name.contains(_query) || e.location.contains(_query),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
              padding:
              const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppTokens.sp3,
                      ),
                      decoration: BoxDecoration(
                        color: c.line,
                        borderRadius:
                        BorderRadius.circular(AppTokens.rPill),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '제시할 증거 선택',
                          style: AppText.titleM.copyWith(color: c.text),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: c.textSub, size: 20),
                        // 기본 48dp 최소 터치 타깃 유지(별도 padding/constraints 억제 안 함).
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  MSTextField(
                    controller: _searchCtrl,
                    hintText: '보유한 증거 검색...',
                    suffixIcon: Icons.search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  Expanded(
                    child: results.isEmpty
                        ? Center(
                      child: Text(
                        '일치하는 증거가 없습니다',
                        style: AppText.bodySm
                            .copyWith(color: c.textSub),
                      ),
                    )
                        : ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.sp2),
                      itemBuilder: (_, i) => _EvidencePickItem(
                        evidence: results[i],
                        onTap: () =>
                            Navigator.of(context).pop(results[i]),
                      ),
                      padding: const EdgeInsets.only(
                        bottom: AppTokens.sp6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 증거 선택 아이템 ──────────────────────────────────────────────────────────

class _EvidencePickItem extends StatelessWidget {
  const _EvidencePickItem({
    required this.evidence,
    required this.onTap,
  });

  final Evidence evidence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(AppTokens.r4),
      child: InkWell(
        onTap: onTap,
        splashColor: c.primary.withValues(alpha: .08),
        highlightColor: c.primary.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.cardPadH,
            vertical: AppTokens.cardPadV,
          ),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.bgHover,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                alignment: Alignment.center,
                child: Icon(evidence.icon, size: 17, color: c.primary),
              ),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      evidence.name,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      evidence.location,
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9.5,
                        color: c.textMute,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── 사건 브리핑 재확인 모달 ───────────────────────────────────────────────────
// 게임 진행 중 상단 HUD에서 사건 개요·피해자·목표를 다시 확인한다.
// (브리핑 화면은 pushReplacement 로 진입해 스택에 없으므로 모달로 재노출)

Future<void> showCaseBriefingModal(
  BuildContext context, {
  required DashboardInfo dashboard,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BriefingSheet(dashboard: dashboard),
  );
}

class _BriefingSheet extends StatelessWidget {
  const _BriefingSheet({required this.dashboard});

  final DashboardInfo dashboard;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final b = dashboard.briefing;

    return Container(
      decoration: BoxDecoration(
        color: c.bgElev,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTokens.r6),
          topRight: Radius.circular(AppTokens.r6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTokens.sp4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTokens.sp4),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(AppTokens.rPill),
                    ),
                  ),
                ),
                Text('사건 브리핑', style: AppText.titleL.copyWith(color: c.text)),
                if (dashboard.scenarioTitle.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp1),
                  Text(
                    dashboard.scenarioTitle,
                    style: AppText.bodySm.copyWith(color: c.textSub),
                  ),
                ],
                if (b.summary.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp5),
                  const MSKicker('사건 개요'),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    b.summary,
                    style: AppText.body.copyWith(color: c.text, height: 1.6),
                  ),
                ],
                const SizedBox(height: AppTokens.sp5),
                const MSKicker('피해자 정보'),
                const SizedBox(height: AppTokens.sp3),
                _BriefingInfoRow(label: '피해자', value: b.victimName),
                const SizedBox(height: AppTokens.sp2),
                _BriefingInfoRow(label: '발견 장소', value: b.foundLocation),
                const SizedBox(height: AppTokens.sp5),
                const MSKicker('탐정 목표'),
                const SizedBox(height: AppTokens.sp3),
                Container(
                  padding: const EdgeInsets.all(AppTokens.sp4),
                  decoration: BoxDecoration(
                    color: c.dangerSoft,
                    border: Border.all(color: c.danger),
                    borderRadius: BorderRadius.circular(AppTokens.r4),
                  ),
                  child: Text(
                    '1. 진범을 찾아라\n'
                    '2. 살해 방법과 동기를 밝혀라\n'
                    '3. 결정적 증거 3개를 수집하라',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.danger,
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.sp5),
                MSButton(
                  label: '닫기',
                  variant: MSButtonVariant.secondary,
                  expanded: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BriefingInfoRow extends StatelessWidget {
  const _BriefingInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppText.bodySm.copyWith(color: c.textMute),
          ),
        ),
        Expanded(
          child: Text(value, style: AppText.body.copyWith(color: c.text)),
        ),
      ],
    );
  }
}
