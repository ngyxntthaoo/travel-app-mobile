import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../models/note.dart';
import '../models/note_checklist_item.dart';
import '../theme/app_colors.dart';

class EditNoteScreen extends StatefulWidget {
  final Note note;
  final Trip trip;
  const EditNoteScreen({super.key, required this.note, required this.trip});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<NoteChecklistItem> _checklistItems = [];
  final TextEditingController _newItemController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _loadChecklistItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklistItems() async {
    if (widget.note.id != null) {
      final items = await DbHelper.instance.readChecklistForNote(widget.note.id!);
      setState(() {
        _checklistItems = items;
      });
    }
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    final updatedNote = widget.note.copyWith(
      title: _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim(),
      content: _contentController.text,
    );
    await DbHelper.instance.updateNote(updatedNote);
    setState(() => _isSaving = false);
  }

  Future<void> _addChecklistItem() async {
    final title = _newItemController.text.trim();
    if (title.isEmpty || widget.note.id == null) return;

    final newItem = NoteChecklistItem(
      noteId: widget.note.id!,
      title: title,
    );

    await DbHelper.instance.createNoteChecklistItem(newItem);
    _newItemController.clear();
    _loadChecklistItems();
  }

  Future<void> _toggleChecklistItem(NoteChecklistItem item) async {
    final updated = item.copyWith(isCompleted: !item.isCompleted);
    await DbHelper.instance.updateNoteChecklistItem(updated);
    _loadChecklistItems();
  }

  Future<void> _deleteChecklistItem(int id) async {
    await DbHelper.instance.deleteNoteChecklistItem(id);
    _loadChecklistItems();
  }

  @override
  Widget build(BuildContext context) {
    final startDateStr = DateFormat('dd MMM').format(widget.trip.startDate);
    final endDateStr = DateFormat('dd MMM, yyyy').format(widget.trip.endDate);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () async {
            await _saveNote();
            if (mounted) Navigator.pop(context);
          },
        ),
        title: Text(
          widget.trip.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    const Positioned(
                      right: 18,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=50&auto=format&fit=crop'),
                      ),
                    ),
                    const Positioned(
                      right: 6,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&auto=format&fit=crop'),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.green.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          await _saveNote();
          return true;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top trip subheader details matching trips_notes.jpeg
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$startDateStr - $endDateStr',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.trip.mainDestination,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Persistent Tab Indicator mockup matching trips_notes.jpeg
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF37849D), width: 2.5),
                        ),
                      ),
                      child: const Text(
                        'Information',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF37849D), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                        ),
                      ),
                      child: const Text(
                        'Itinerary',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The Notepad Editor Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button to list below tabs
                    InkWell(
                      onTap: () async {
                        await _saveNote();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF37849D)),
                          SizedBox(width: 6),
                          Text(
                            'Notes',
                            style: TextStyle(
                              color: Color(0xFF37849D),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Note Title Text Input (Editable)
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Note Title (e.g. Bali Flight Prices)',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _saveNote(),
                    ),
                    const SizedBox(height: 10),
                    // Note content free text area matching the typewriter look in trips_notes.jpeg
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start writing your details here...',
                        hintStyle: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _saveNote(),
                    ),
                    const Divider(height: 40),
                    // Checklist Items title
                    const Text(
                      'Interactive Checklist',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Checkbox items for this specific note
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _checklistItems.length,
                      itemBuilder: (context, index) {
                        final item = _checklistItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.isCompleted,
                                activeColor: AppColors.teal,
                                onChanged: (_) => _toggleChecklistItem(item),
                              ),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    color: item.isCompleted ? Colors.grey : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                                onPressed: () => _deleteChecklistItem(item.id!),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Add new checklist item input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newItemController,
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Add checklist item (e.g. Passport)...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade100),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.teal, width: 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF37849D), size: 30),
                          onPressed: _addChecklistItem,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
