import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import '../utils/snackbars.dart';
import '../widgets/traveler_avatars.dart';
import '../widgets/trip_app_bar.dart';
import '../widgets/trip_subheader.dart';
import 'shared_trip_screen.dart';
import 'trip_notes_screen.dart';
import 'trip_flights_screen.dart';
import 'trip_accoms_screen.dart';
import 'trip_expenses_screen.dart';
import 'trip_itinerary_tab.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _activeTab = 0;
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  Future<void> _refreshTrip() async {
    final updated = await DbHelper.instance.readTripById(_trip.id!);
    if (updated != null && mounted) {
      setState(() => _trip = updated);
    }
  }

  Future<void> _showShareSheet() async {
    var isPublic = _trip.isPublic;
    var shareToken = _trip.shareToken ?? const Uuid().v4().substring(0, 8);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final link = 'tripplanner://share/$shareToken';

            Future<void> togglePublic(bool value) async {
              setModalState(() => isPublic = value);
              if (value && _trip.shareToken == null) {
                shareToken = const Uuid().v4().substring(0, 8);
              }
              final updated = await DbHelper.instance.setTripSharing(
                _trip.id!,
                isPublic: value,
                shareToken: value ? (_trip.shareToken ?? shareToken) : _trip.shareToken,
              );
              if (mounted) setState(() => _trip = updated);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Share itinerary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Let others view your full trip plan and cost per person for reference.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Make trip public', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Visible in Social tab for all users'),
                    value: isPublic,
                    activeColor: AppColors.teal,
                    onChanged: togglePublic,
                  ),
                  if (isPublic) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SelectableText(
                        link,
                        style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: link));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Link copied to clipboard')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy link'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Share.share(
                              'Check out my trip "${_trip.title}"!\n$link',
                              subject: _trip.title,
                            ),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharedTripScreen(trip: _trip, showCloneButton: false),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview shared view'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
    await _refreshTrip();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: TripAppBar(
        title: _trip.title,
        useCloseIcon: true,
        actions: [
          const TravelerAvatarStack(),
          IconButton(
            icon: Icon(
              _trip.isPublic ? Icons.share_rounded : Icons.ios_share_rounded,
              color: _trip.isPublic ? AppColors.teal : Colors.black87,
              size: 20,
            ),
            onPressed: _showShareSheet,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87, size: 20),
            onPressed: () => showComingSoon(context, 'Edit Trip Info'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TripSubheader(trip: _trip),
          _buildTabsHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTabsHeader() {
    const tabLabels = ['Information', 'Itinerary'];

    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(tabLabels.length, (index) {
          final selected = _activeTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.teal : Colors.grey.shade100,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                ),
                child: Text(
                  tabLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.teal : Colors.grey,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    if (_activeTab == 1) {
      return TripItineraryTab(trip: _trip);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildActiveTabContent(),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildInformationTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInformationTab() {
    final listItems = [
      (icon: Icons.assignment_outlined, label: 'Notes', action: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripNotesScreen(trip: _trip)));
      }),
      (icon: Icons.flight_takeoff_rounded, label: 'Flights', action: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripFlightsScreen(trip: _trip)));
      }),
      (icon: Icons.hotel_outlined, label: 'Accoms', action: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripAccomsScreen(trip: _trip)));
      }),
      (icon: Icons.bookmark_border_rounded, label: 'Saved Places', action: () => showComingSoon(context, 'Saved Places')),
      (icon: Icons.confirmation_number_outlined, label: 'Tickets', action: () => showComingSoon(context, 'Tickets')),
      (icon: Icons.account_balance_wallet_outlined, label: 'Bills', action: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripExpensesScreen(trip: _trip)));
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_trip.isPublic)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This trip is public. Others can view and clone it.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        const Text(
          'Lists',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: listItems.length,
          itemBuilder: (context, index) {
            final item = listItems[index];
            return GestureDetector(
              onTap: item.action,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: AppColors.teal, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
