/// Single source of truth for travel group members.
/// All screens import from here — no more copy-pasting avatar URLs.
class Traveler {
  const Traveler({required this.name, required this.avatarUrl});
  final String name;
  final String avatarUrl;
}

const kTravelers = [
  Traveler(
    name: 'Me',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&fit=crop&q=80',
  ),
  Traveler(
    name: 'Claire',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&fit=crop&q=80',
  ),
  Traveler(
    name: 'Celeste',
    avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&fit=crop&q=80',
  ),
  Traveler(
    name: 'Jessica',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&fit=crop&q=80',
  ),
];

/// Lookup avatar URL for a given name (case-insensitive), falls back to 'Me'.
String avatarUrlFor(String name) {
  return kTravelers
      .firstWhere(
        (t) => t.name.toLowerCase() == name.trim().toLowerCase(),
        orElse: () => kTravelers.first,
      )
      .avatarUrl;
}
