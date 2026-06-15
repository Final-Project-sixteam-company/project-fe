// lib/screens/interrogation_actions_mixin.dart
import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/play_models.dart';
import '../models/session_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_theme.dart';

enum InterrogationSender { detective, suspect }

class InterrogationMessage {
  const InterrogationMessage({
    required this.text,
    required this.sender,
    this.presentedEvidenceId,
  });

  final String text;
  final InterrogationSender sender;
  final String? presentedEvidenceId;
}

/// 심문 화면에서 사용되는 액션 로직을 담당하는 mixin.
mixin InterrogationActionsMixin<T extends StatefulWidget> on State<T> {
  // ── 외부 주입 ──────────────────────────────────────────────────────────────
  String get suspectId;
  String get suspectName;
  String get backendSessionId_;
  TextEditingController get inputCtrl;
  ScrollController get scrollCtrl;

  // ── 내부 상태 (mixin 사용 측 State에서 선언) ───────────────────────────────
  List<InterrogationMessage> get messages;
  bool get isWaiting;
  set isWaiting(bool v);
  String? get prefillEvidenceId;
  set prefillEvidenceId(String? v);
  String? get prefillEvidenceTitle;
  set prefillEvidenceTitle(String? v);

  // 💡 리뷰어 피드백 반영: 프리필된 추천 질문 타입을 보관할 필드 추가
  QuestionType? get prefillQuestionType;
  set prefillQuestionType(QuestionType? v);

  // ── 메시지 전송 ─────────────────────────────────────────────────────────────
  Future<void> sendMessage(
      String text, {
        String? evidenceId,
        QuestionType questionType = QuestionType.free,
      }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isWaiting) return;

    final ctrl = context.sessionRead;
    final sessionId = ctrl.backendSessionId;
    final suspectIdInt = int.tryParse(suspectId);
    final evidenceIdInt = evidenceId != null ? int.tryParse(evidenceId) : null;

    if (evidenceId != null && evidenceIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 증거는 제시할 수 없습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    setState(() {
      messages.add(InterrogationMessage(
        text: trimmed,
        sender: InterrogationSender.detective,
        presentedEvidenceId: evidenceId,
      ));
      isWaiting = true;
      inputCtrl.clear();
      prefillEvidenceId = null;
      prefillEvidenceTitle = null;
      prefillQuestionType = null; // 전송 시작 시 프리필 타입 초기화
    });
    scrollToBottom();

    if (sessionId == null || suspectIdInt == null) {
      if (mounted) {
        setState(() {
          messages.add(const InterrogationMessage(
            text: '세션이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.',
            sender: InterrogationSender.suspect,
          ));
          isWaiting = false;
        });
        scrollToBottom();
      }
      return;
    }

    String answer = '...대답을 거부하고 있습니다.';
    String? errorNotice;
    List<RelatedEvidence> unlocked = const [];

    try {
      final res = await playSessionRepo.interrogate(
        sessionId,
        suspectId: suspectIdInt,
        questionType: questionType, // 최종 판별된 타입으로 API 요청
        question: trimmed,
        presentedEvidenceId: evidenceIdInt,
      );

      answer = res.answer;
      unlocked = res.unlockedEvidences;

      if (mounted) {
        ctrl.addInterrogationLog(InterrogationLog(
          suspectId: suspectId,
          suspectName: suspectName,
          question: trimmed,
          answer: answer,
          askedAt: ctrl.elapsed,
          presentedEvidenceId: evidenceId,
        ));
      }
    } on ApiException {
      answer = '...지금은 대답하기 어려운 것 같습니다.';
      errorNotice = '응답을 받지 못했습니다. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      answer = '...지금은 대답하기 어려운 것 같습니다.';
      errorNotice = '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    } finally {
      if (mounted) {
        setState(() {
          messages.add(InterrogationMessage(text: answer, sender: InterrogationSender.suspect));
          isWaiting = false;
        });
        scrollToBottom();
      }
    }

    if (!mounted) return;

    if (errorNotice != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorNotice)));
    }

    if (unlocked.isNotEmpty) {
      await ctrl.refreshEvidences();
      if (mounted) {
        final evidenceNames = unlocked.map((e) => e.title).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('새로운 증거 확보: $evidenceNames'),
        ));
      }
    }
  }

  // ── 증거 제시 ───────────────────────────────────────────────────────────────
  Future<void> presentEvidence() async {
    final evidence = await showEvidencePresentModal(context);
    if (evidence != null && mounted) {
      setState(() {
        prefillEvidenceId = null;
        prefillEvidenceTitle = null;
        prefillQuestionType = null;
      });
      await sendMessage(
        '이 증거를 제시합니다: ${evidence.name}',
        evidenceId: evidence.id,
        questionType: QuestionType.evidencePresented,
      );
    }
  }

  // ── chip prefill (전송 금지) ─────────────────────────────────────────────────
  void onChipPrefill(SuggestedQuestionInfo sq) {
    setState(() {
      inputCtrl.text = sq.question;
      inputCtrl.selection = TextSelection.collapsed(offset: inputCtrl.text.length);
      prefillEvidenceId = sq.presentedEvidenceId?.toString();
      prefillEvidenceTitle = sq.presentedEvidenceId != null ? sq.targetName : null;

      prefillQuestionType = sq.questionType as QuestionType?;
    });
  }

  // ── 스크롤 ──────────────────────────────────────────────────────────────────
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollCtrl.hasClients) return;
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: AppMotion.dur3,
          curve: AppMotion.easeOut,
        );
      });
    });
  }
}