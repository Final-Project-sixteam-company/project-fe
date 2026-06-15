// lib/models/play_timeline_models.dart

class PlayTimelineEvent {
  const PlayTimelineEvent({
    required this.time,
    required this.title,
    this.description,
    this.eventType,
    this.relatedEvidenceId,
  });

  final String time;
  final String title;
  final String? description;
  final String? eventType;
  final int? relatedEvidenceId;

  factory PlayTimelineEvent.fromJson(Map<String, dynamic> j) =>
      PlayTimelineEvent(
        time: j['time'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        eventType: j['eventType'] as String?,
        relatedEvidenceId: (j['relatedEvidenceId'] as num?)?.toInt(),
      );
}
