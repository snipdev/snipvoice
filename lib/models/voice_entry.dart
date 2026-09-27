class VoiceEntry {
  final String id;
  final String path; // local path or supabase url
  final DateTime createdAt;
  final int durationSec;
  final String sessionLabel;
  final String? note;
  final bool uploaded;

  /// Badge key: built-in enum name ('favorite') or a custom badge id
  /// ('custom:xxxxxxxx'). 'none' means no badge.
  final String badgeId;

  /// Recording found on disk but not playable (truncated/corrupt).
  /// Not playable; shown flagged to the user, who can delete it.
  final bool broken;

  /// Local file paths of the images attached to the entry (device only for now).
  final List<String> images;

  const VoiceEntry({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.durationSec,
    required this.sessionLabel,
    this.note,
    this.uploaded = false,
    this.badgeId = 'none',
    this.broken = false,
    this.images = const [],
  });

  VoiceEntry copyWith({
    String? id,
    String? path,
    DateTime? createdAt,
    int? durationSec,
    String? sessionLabel,
    String? note,
    bool clearNote = false,
    bool? uploaded,
    String? badgeId,
    bool? broken,
    List<String>? images,
  }) =>
      VoiceEntry(
        id: id ?? this.id,
        path: path ?? this.path,
        createdAt: createdAt ?? this.createdAt,
        durationSec: durationSec ?? this.durationSec,
        sessionLabel: sessionLabel ?? this.sessionLabel,
        note: clearNote ? null : (note ?? this.note),
        uploaded: uploaded ?? this.uploaded,
        badgeId: badgeId ?? this.badgeId,
        broken: broken ?? this.broken,
        images: images ?? this.images,
      );

  Map<String, dynamic> toSupabase(String storagePath) => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'duration_sec': durationSec,
        'session_label': sessionLabel,
        'note': note,
        'storage_path': storagePath,
        'badge': badgeId,
      };

  String get dayKey =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

  String get durationLabel {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
