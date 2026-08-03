import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({
    super.key,
    required this.cityName,
    required this.gradientColors,
  });

  final String cityName;
  final List<Color> gradientColors;

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  int _infoTab = 0;

  static const _locationCards = [
    _LocationCard(
      name: 'The Beauchamp',
      address: '24-27 Bedford Place',
      rating: 4.9,
      tag: 'Food',
      gradientColors: AppColors.gradientBrown,
    ),
    _LocationCard(
      name: 'South Banks',
      address: 'Park Plaza London',
      rating: 4.8,
      tag: 'Food',
      gradientColors: AppColors.gradientBlue,
    ),
    _LocationCard(
      name: 'Hyde Park Corner',
      address: 'Westminster, London',
      rating: 4.7,
      tag: 'Sights',
      gradientColors: AppColors.gradientGreen,
    ),
  ];

  static const _activityCards = [
    _LocationCard(
      name: 'The Beauchamp',
      address: '24-27 Bedford Place',
      rating: 4.9,
      tag: 'Food',
      gradientColors: AppColors.gradientBrown,
    ),
    _LocationCard(
      name: 'South Banks',
      address: 'Park Plaza London',
      rating: 4.9,
      tag: 'Food',
      gradientColors: AppColors.gradientBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.cityName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildSectionTitle('Location info'),
            const SizedBox(height: 12),
            _buildInfoTabs(),
            const SizedBox(height: 24),
            _buildSectionTitle('Categories'),
            const SizedBox(height: 12),
            _buildCategories(),
            const SizedBox(height: 24),
            _buildSectionTitle('Popular Locations'),
            const SizedBox(height: 12),
            _buildHorizontalCards(_locationCards),
            const SizedBox(height: 24),
            _buildSectionTitle('To Do Activities'),
            const SizedBox(height: 12),
            _buildHorizontalCards(_activityCards),
            const SizedBox(height: 24),
            _buildSectionTitle('Favorite Places'),
            const SizedBox(height: 12),
            _buildHorizontalCards(_locationCards),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textHint, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search in ${widget.cityName}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoTabs() {
    const tabs = [
      (icon: Icons.description_outlined, label: 'General'),
      (icon: Icons.info_outline_rounded, label: 'Info for\nTravellers'),
      (icon: Icons.directions_bus_outlined, label: 'Commute'),
    ];

    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _infoTab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _infoTab = i),
            child: Container(
              margin: EdgeInsets.only(right: i < tabs.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(
                  color: selected ? AppColors.teal : AppColors.divider,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tabs[i].icon, color: AppColors.teal, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    tabs[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? AppColors.teal : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategories() {
    const categories = [
      (icon: Icons.directions_run_rounded, label: 'Activities'),
      (icon: Icons.hotel_outlined, label: 'Accoms'),
      (icon: Icons.fastfood_outlined, label: 'Food'),
      (icon: Icons.photo_camera_outlined, label: 'Sights'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(cat.icon, color: Colors.black87, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              cat.label,
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalCards(List<_LocationCard> cards) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Container(
            width: 155,
            margin: EdgeInsets.only(right: index < cards.length - 1 ? 12 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: card.gradientColors,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              card.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _TagBadge(label: card.tag),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    color: AppColors.cardBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 10, color: Colors.grey),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                card.address,
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  card.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data model
// ---------------------------------------------------------------------------

class _LocationCard {
  const _LocationCard({
    required this.name,
    required this.address,
    required this.rating,
    required this.tag,
    required this.gradientColors,
  });

  final String name;
  final String address;
  final double rating;
  final String tag;
  final List<Color> gradientColors;
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
      color: AppColors.tagOverlay,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.restaurant, color: Colors.white, size: 9),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
