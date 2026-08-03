import 'package:flutter/material.dart';
import '../data/travelers.dart';

/// AppBar-style layered avatar stack (fixed two travelers + online indicator).
/// Used in TripDetailScreen and EditNoteScreen.
class TravelerAvatarStack extends StatelessWidget {
  const TravelerAvatarStack({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned(
            right: 18,
            child: CircleAvatar(
              radius: 11,
              backgroundImage: NetworkImage(kTravelers[1].avatarUrl), // Claire
            ),
          ),
          Positioned(
            right: 6,
            child: CircleAvatar(
              radius: 11,
              backgroundImage: NetworkImage(kTravelers[2].avatarUrl), // Celeste
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
    );
  }
}

/// Compact overlapping avatar row shown inside flight/bill cards.
/// [names] is the list of traveler names to display (e.g. ['Me', 'Claire']).
class TravelerAvatarRow extends StatelessWidget {
  const TravelerAvatarRow({super.key, required this.names, this.radius = 10});

  final List<String> names;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: radius * 2 + 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: names.map((name) {
          return Align(
            widthFactor: 0.65,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundImage: NetworkImage(avatarUrlFor(name)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
