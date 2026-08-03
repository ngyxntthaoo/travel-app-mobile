class Note {
  final int? id;
  final int tripId;
  final String title;
  final String content;

  Note({
    this.id,
    required this.tripId,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'content': content,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
    );
  }

  Note copyWith({
    int? id,
    int? tripId,
    String? title,
    String? content,
  }) {
    return Note(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}
