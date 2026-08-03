class ChecklistItem {
  final int? id;
  final int tripId;
  final String title;
  final bool isCompleted;
  final String? localFilePath;

  ChecklistItem({
    this.id,
    required this.tripId,
    required this.title,
    this.isCompleted = false,
    this.localFilePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'local_file_path': localFilePath,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      localFilePath: map['local_file_path'] as String?,
    );
  }

  ChecklistItem copyWith({
    int? id,
    int? tripId,
    String? title,
    bool? isCompleted,
    String? localFilePath,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
