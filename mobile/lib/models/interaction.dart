enum InteractionType { call, text, email, checkIn, careSignal, beacon }

class Interaction {
  final String id;
  final String? targetId;
  final String? type;
  final String? note;
  final DateTime? createdAt;

  const Interaction({
    required this.id,
    this.targetId,
    this.type,
    this.note,
    this.createdAt,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id']?.toString() ?? '',
        targetId: json['target_id'] as String?,
        type: json['type'] as String?,
        note: json['note'] as String? ?? json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}
