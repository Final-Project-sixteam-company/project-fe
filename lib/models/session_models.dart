// lib/models/session_models.dart

class InterrogationLog {
  const InterrogationLog({
    required this.suspectId,
    required this.suspectName,
    required this.question,
    required this.answer,
    required this.askedAt,
    this.presentedEvidenceId,
  });

  final String suspectId;
  final String suspectName;
  final String question;
  final String answer;
  final Duration askedAt;
  final String? presentedEvidenceId;
}
