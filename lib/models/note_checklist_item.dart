class NoteChecklistItem {
  final int? id;
  final int noteId;
  final String title;
  final bool isCompleted;

  NoteChecklistItem({
    this.id,
    required this.noteId,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory NoteChecklistItem.fromMap(Map<String, dynamic> map) {
    return NoteChecklistItem(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  NoteChecklistItem copyWith({
    int? id,
    int? noteId,
    String? title,
    bool? isCompleted,
  }) {
    return NoteChecklistItem(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
