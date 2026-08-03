import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../models/checklist_item.dart';
import '../theme/app_colors.dart';
import '../widgets/attachment_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/trip_app_bar.dart';

class TripChecklistScreen extends StatefulWidget {
  final Trip trip;
  const TripChecklistScreen({super.key, required this.trip});

  @override
  State<TripChecklistScreen> createState() => _TripChecklistScreenState();
}

class _TripChecklistScreenState extends State<TripChecklistScreen> {
  List<ChecklistItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshChecklist();
  }

  Future<void> _refreshChecklist() async {
    setState(() => _isLoading = true);
    final items = await DbHelper.instance.readChecklistForTrip(widget.trip.id!);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    await DbHelper.instance.updateChecklistItem(item.copyWith(isCompleted: !item.isCompleted));
    _refreshChecklist();
  }

  Future<void> _attachDocument(ChecklistItem item) async {
    final localPath = await DbHelper.instance.database.then((_) => null); // placeholder — using FileService
    // Delegate to service layer directly in AttachmentRow.onAttach
  }

  Future<void> _removeDocument(ChecklistItem item) async {
    await DbHelper.instance.updateChecklistItem(
      ChecklistItem(
        id: item.id,
        tripId: item.tripId,
        title: item.title,
        isCompleted: item.isCompleted,
        localFilePath: null,
      ),
    );
    _refreshChecklist();
  }

  void _showAddItemDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add Checklist Item', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Enter task or document name...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              await DbHelper.instance.createChecklistItem(ChecklistItem(tripId: widget.trip.id!, title: text));
              if (mounted) {
                Navigator.pop(context);
                _refreshChecklist();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((i) => i.isCompleted).length;
    final total = _items.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const TripAppBar(title: 'Trip Checklist'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Preparation Progress', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('$completed/$total Done', style: const TextStyle(color: AppColors.teal, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Pre-Trip Checklist & Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyState(
                          icon: Icons.check_box_outline_blank_rounded,
                          title: 'Checklist is empty',
                          subtitle: 'Tap "+" to add preparation tasks.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    leading: Checkbox(
                                      value: item.isCompleted,
                                      activeColor: AppColors.teal,
                                      onChanged: (_) => _toggleItem(item),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: TextStyle(
                                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: item.isCompleted ? Colors.grey : AppColors.textPrimary,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                      onPressed: () async {
                                        await DbHelper.instance.deleteChecklistItem(item.id!);
                                        _refreshChecklist();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
                                    child: AttachmentRow(
                                      localFilePath: item.localFilePath,
                                      attachLabel: 'Attach File',
                                      openLabel: 'Open Offline',
                                      onAttach: () async {
                                        final localPath = await item.localFilePath.runtimeType.toString() == 'Null'
                                            ? null
                                            : null;
                                        // Inline here — FileService is called via AttachmentRow's onAttach
                                        // We need to call it ourselves since AttachmentRow delegates back to us:
                                        final _ = await Future(() => null); // no-op — see override below
                                      },
                                      onRemove: () => _removeDocument(item),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
