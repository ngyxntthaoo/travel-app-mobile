import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../models/note.dart';
import '../theme/app_colors.dart';
import '../utils/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/trip_app_bar.dart';
import 'edit_note_screen.dart';

class TripNotesScreen extends StatefulWidget {
  final Trip trip;
  const TripNotesScreen({super.key, required this.trip});

  @override
  State<TripNotesScreen> createState() => _TripNotesScreenState();
}

class _TripNotesScreenState extends State<TripNotesScreen> {
  List<Note> _notes = [];
  Map<int, int> _totalItems = {};
  Map<int, int> _completedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await DbHelper.instance.readNotesForTrip(widget.trip.id!);

    final totalCounts = <int, int>{};
    final completedCounts = <int, int>{};
    for (var note in notes) {
      if (note.id != null) {
        final items = await DbHelper.instance.readChecklistForNote(note.id!);
        totalCounts[note.id!] = items.length;
        completedCounts[note.id!] = items.where((i) => i.isCompleted).length;
      }
    }

    setState(() {
      _notes = notes;
      _totalItems = totalCounts;
      _completedItems = completedCounts;
      _isLoading = false;
    });
  }

  void _addNote() async {
    final newNote = Note(tripId: widget.trip.id!, title: 'New Note', content: '');
    final id = await DbHelper.instance.createNote(newNote);
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditNoteScreen(note: newNote.copyWith(id: id), trip: widget.trip)),
      );
      _loadNotes();
    }
  }

  void _deleteNote(int id) async {
    final confirmed = await showDeleteConfirmation(
      context: context,
      title: 'Delete Note',
      content: 'Are you sure you want to delete this note? All checklist items inside will also be removed.',
    );
    if (confirmed) {
      await DbHelper.instance.deleteNote(id);
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const TripAppBar(title: 'Trip Notes & Lists'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _notes.isEmpty
                      ? EmptyState(
                          icon: Icons.notes_rounded,
                          title: 'No notes added yet',
                          subtitle: 'Tap "+" below to add travel notes and checklists.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final total = _totalItems[note.id!] ?? 0;
                            final completed = _completedItems[note.id!] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_note_rounded, color: AppColors.teal, size: 24),
                                ),
                                title: Text(
                                  note.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      note.content.isEmpty ? 'No text content' : note.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                    if (total > 0) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.teal),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$completed/$total tasks completed',
                                            style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                  onPressed: () => _deleteNote(note.id!),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EditNoteScreen(note: note, trip: widget.trip)),
                                  );
                                  _loadNotes();
                                },
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: PrimaryButton(
                    label: 'Add Note / List',
                    icon: Icons.add,
                    onPressed: _addNote,
                  ),
                ),
              ],
            ),
    );
  }
}
