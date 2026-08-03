import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../db/db_helper.dart';
import '../models/trip.dart';
import '../models/accommodation.dart';
import '../services/file_service.dart';
import '../theme/app_colors.dart';
import 'map_picker_screen.dart';

class TripAccomsScreen extends StatefulWidget {
  final Trip trip;
  const TripAccomsScreen({super.key, required this.trip});

  @override
  State<TripAccomsScreen> createState() => _TripAccomsScreenState();
}

class _TripAccomsScreenState extends State<TripAccomsScreen> {
  List<Accommodation> _accommodations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccommodations();
  }

  Future<void> _loadAccommodations() async {
    setState(() => _isLoading = true);
    final accoms = await DbHelper.instance.readAccommodationsForTrip(widget.trip.id!);
    setState(() {
      _accommodations = accoms;
      _isLoading = false;
    });
  }

  void _showAddAccommodationDialog({Accommodation? editAccom}) {
    final hotelCtrl = TextEditingController(text: editAccom?.hotelName);
    final confCtrl = TextEditingController(text: editAccom?.confirmationNo == 'N/A' ? '' : editAccom?.confirmationNo);
    final priceCtrl = TextEditingController(text: editAccom != null ? editAccom.price.toStringAsFixed(2) : '');
    
    DateTime? checkInDate = editAccom != null ? DateTime.tryParse(editAccom.checkIn) : null;
    DateTime? checkOutDate = editAccom != null ? DateTime.tryParse(editAccom.checkOut) : null;
    double? pickedLat = editAccom?.lat;
    double? pickedLng = editAccom?.lng;
    var pickedAddress = editAccom?.address ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selectDate(BuildContext context, bool isCheckIn) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isCheckIn ? (checkInDate ?? widget.trip.startDate) : (checkOutDate ?? widget.trip.startDate),
                firstDate: widget.trip.startDate.subtract(const Duration(days: 30)),
                lastDate: widget.trip.endDate.add(const Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF37849D),
                        onPrimary: Colors.white,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setModalState(() {
                  if (isCheckIn) {
                    checkInDate = picked;
                  } else {
                    checkOutDate = picked;
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                editAccom == null ? 'Add Stay / Hotel' : 'Edit Stay / Hotel',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hotelCtrl,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Hotel Name',
                              hintText: 'e.g. Marina Bay Sands',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.map_rounded, color: Color(0xFF37849D), size: 28),
                          onPressed: () async {
                            final result = await Navigator.push<MapPickerResult>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapPickerScreen(destination: widget.trip.mainDestination),
                              ),
                            );
                            if (result != null) {
                              setModalState(() {
                                hotelCtrl.text = result.name;
                                pickedLat = result.lat;
                                pickedLng = result.lng;
                                pickedAddress = result.address;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confCtrl,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Confirmation No.',
                        hintText: 'e.g. CONF-72648',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceCtrl,
                      style: const TextStyle(color: Colors.black87),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Total Price / Cost (\$)',
                        hintText: 'e.g. 350.00',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                checkInDate == null
                                    ? 'Check-In'
                                    : DateFormat('dd MMM').format(checkInDate!),
                                style: TextStyle(
                                  color: checkInDate == null ? Colors.grey.shade400 : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                checkOutDate == null
                                    ? 'Check-Out'
                                    : DateFormat('dd MMM').format(checkOutDate!),
                                style: TextStyle(
                                  color: checkOutDate == null ? Colors.grey.shade400 : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                if (editAccom != null)
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _deleteAccommodation(editAccom.id!);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37849D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final hotel = hotelCtrl.text.trim();
                    final conf = confCtrl.text.trim();
                    final hotelPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                    if (hotel.isEmpty || checkInDate == null || checkOutDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields and pick dates.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final checkInStr = DateFormat('yyyy-MM-dd').format(checkInDate!);
                    final checkOutStr = DateFormat('yyyy-MM-dd').format(checkOutDate!);

                    if (editAccom == null) {
                      final accom = Accommodation(
                        tripId: widget.trip.id!,
                        hotelName: hotel,
                        checkIn: checkInStr,
                        checkOut: checkOutStr,
                        confirmationNo: conf.isEmpty ? 'N/A' : conf,
                        price: hotelPrice,
                        lat: pickedLat,
                        lng: pickedLng,
                        address: pickedAddress,
                      );
                      await DbHelper.instance.createAccommodation(accom);
                    } else {
                      final accom = editAccom.copyWith(
                        hotelName: hotel,
                        checkIn: checkInStr,
                        checkOut: checkOutStr,
                        confirmationNo: conf.isEmpty ? 'N/A' : conf,
                        price: hotelPrice,
                        lat: pickedLat,
                        lng: pickedLng,
                        address: pickedAddress,
                      );
                      await DbHelper.instance.updateAccommodation(accom);
                    }
                    
                    _loadAccommodations();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAccommodation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stay Booking'),
        content: const Text('Are you sure you want to delete this hotel booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper.instance.deleteAccommodation(id);
      _loadAccommodations();
    }
  }

  Future<void> _attachDetail(Accommodation accom) async {
    final localPath = await FileService.instance.pickAndSaveDocument();
    if (localPath != null) {
      final updated = accom.copyWith(localFilePath: localPath);
      await DbHelper.instance.updateAccommodation(updated);
      _loadAccommodations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking detail attached successfully (cached offline).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeDetail(Accommodation accom) async {
    final updated = Accommodation(
      id: accom.id,
      tripId: accom.tripId,
      hotelName: accom.hotelName,
      checkIn: accom.checkIn,
      checkOut: accom.checkOut,
      confirmationNo: accom.confirmationNo,
      localFilePath: null,
      price: accom.price,
    );
    await DbHelper.instance.updateAccommodation(updated);
    _loadAccommodations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Stays & Accoms'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF37849D)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _accommodations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hotel_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                'No stays added yet',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text('Tap "+" below to add stay bookings.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _accommodations.length,
                          itemBuilder: (context, index) {
                            final accom = _accommodations[index];
                            final hasAttachment = accom.localFilePath != null;
                            final fileName = hasAttachment ? p.basename(accom.localFilePath!) : '';
                            
                            final cinDate = DateTime.tryParse(accom.checkIn) ?? DateTime.now();
                            final coutDate = DateTime.tryParse(accom.checkOut) ?? DateTime.now();
                            final stayDuration = coutDate.difference(cinDate).inDays;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              accom.hotelName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${DateFormat('dd MMM').format(cinDate)} - ${DateFormat('dd MMM').format(coutDate)} ($stayDuration Nights)',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF37849D), size: 22),
                                        onPressed: () => _showAddAccommodationDialog(editAccom: accom),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Confirmation No.',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            accom.confirmationNo,
                                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      if (accom.price > 0)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Cost',
                                              style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${accom.price.toStringAsFixed(2)}',
                                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  // Offline Detail Attachment Interface (Just like checklist items attachment flow!)
                                  Row(
                                    children: [
                                      Icon(
                                        hasAttachment ? Icons.attach_file_rounded : Icons.add_to_photos_outlined,
                                        size: 15,
                                        color: hasAttachment ? AppColors.teal : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: hasAttachment
                                            ? InkWell(
                                                onTap: () => FileService.instance.openDocument(accom.localFilePath!),
                                                child: Text(
                                                  fileName,
                                                  style: const TextStyle(
                                                    color: AppColors.teal,
                                                    decoration: TextDecoration.underline,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              )
                                            : Text(
                                                'No hotel Detail attached',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                      ),
                                      if (hasAttachment) ...[
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(40, 24),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () => FileService.instance.openDocument(accom.localFilePath!),
                                          icon: const Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.teal),
                                          label: const Text('Open Detail', style: TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.cancel, size: 16, color: Colors.redAccent),
                                          onPressed: () => _removeDetail(accom),
                                        ),
                                      ] else ...[
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(60, 24),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () => _attachDetail(accom),
                                          icon: const Icon(Icons.upload_file_rounded, size: 14, color: Color(0xFF37849D)),
                                          label: const Text('Attach Detail', style: TextStyle(fontSize: 11, color: Color(0xFF37849D), fontWeight: FontWeight.bold)),
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37849D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _showAddAccommodationDialog(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Stay',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
