import 'dart:math';

import '../models/itinerary_place.dart';

/// Haversine distance in kilometers between two coordinates.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRad(double deg) => deg * pi / 180;

class RouteOptimizer {
  /// Distance in km between two places (both must have coordinates).
  static double haversineKmBetween(ItineraryPlace a, ItineraryPlace b) =>
      haversineKm(a.lat!, a.lng!, b.lat!, b.lng!);

  /// Orders places using nearest-neighbor heuristic starting from the earliest start time.
  static List<ItineraryPlace> optimize(List<ItineraryPlace> places) {
    final withCoords = places.where((p) => p.lat != null && p.lng != null).toList();
    if (withCoords.length < 2) return withCoords;

    withCoords.sort((a, b) {
      final timeCmp = a.startTime.compareTo(b.startTime);
      if (timeCmp != 0) return timeCmp;
      return a.sortOrder.compareTo(b.sortOrder);
    });

    final result = <ItineraryPlace>[withCoords.first];
    final remaining = List<ItineraryPlace>.from(withCoords.sublist(1));

    while (remaining.isNotEmpty) {
      final current = result.last;
      remaining.sort((a, b) {
        final distA = haversineKm(current.lat!, current.lng!, a.lat!, a.lng!);
        final distB = haversineKm(current.lat!, current.lng!, b.lat!, b.lng!);
        return distA.compareTo(distB);
      });
      result.add(remaining.removeAt(0));
    }

    return result;
  }

  /// Current itinerary order (by sort_order then start_time).
  static List<ItineraryPlace> currentOrder(List<ItineraryPlace> places) {
    final withCoords = places.where((p) => p.lat != null && p.lng != null).toList();
    withCoords.sort((a, b) {
      final orderCmp = a.sortOrder.compareTo(b.sortOrder);
      if (orderCmp != 0) return orderCmp;
      return a.startTime.compareTo(b.startTime);
    });
    return withCoords;
  }

  static double routeDistanceKm(List<ItineraryPlace> ordered) {
    if (ordered.length < 2) return 0;
    var total = 0.0;
    for (var i = 0; i < ordered.length - 1; i++) {
      total += haversineKm(
        ordered[i].lat!,
        ordered[i].lng!,
        ordered[i + 1].lat!,
        ordered[i + 1].lng!,
      );
    }
    return total;
  }

  // ───────────────────────────────────────────────────────────
  // Key-stop recommendation
  //
  // Groups nearby places into clusters and keeps only the most
  // "important" place per cluster as a key stop. The remaining
  // places become satellites attached to the nearest key stop.
  // Example: a 9-place trip may collapse to 5 key stops, with the
  // other 4 shown as minor points near their key stop.
  // ───────────────────────────────────────────────────────────

  /// Auto grouping radius (km): scaled from the median nearest-neighbor
  /// spacing so that only genuinely close places get merged.
  static double autoRadiusKm(List<ItineraryPlace> places) {
    final pts = places.where((p) => p.lat != null && p.lng != null).toList();
    if (pts.length < 2) return 0.5;

    final nnDistances = <double>[];
    for (var i = 0; i < pts.length; i++) {
      var best = double.infinity;
      for (var j = 0; j < pts.length; j++) {
        if (i == j) continue;
        final d = haversineKm(pts[i].lat!, pts[i].lng!, pts[j].lat!, pts[j].lng!);
        if (d < best) best = d;
      }
      if (best.isFinite) nnDistances.add(best);
    }
    if (nnDistances.isEmpty) return 0.5;
    nnDistances.sort();
    final median = nnDistances[nnDistances.length ~/ 2];
    return (median * 1.8).clamp(0.2, 8.0);
  }

  /// Importance score used to elect the representative of a cluster.
  /// Higher cost, longer visits and sightseeing/accommodation rank higher.
  static double placeImportance(ItineraryPlace p) {
    var score = p.cost / 100.0;
    final start = _minutesFromHHmm(p.startTime);
    final end = _minutesFromHHmm(p.endTime);
    if (start != null && end != null && end > start) {
      score += (end - start) / 60.0 * 5.0;
    }
    score += _kindWeight(p.kind);
    return score;
  }

  static double _kindWeight(PlaceKind kind) {
    switch (kind) {
      case PlaceKind.sights:
        return 5.0;
      case PlaceKind.accomms:
        return 4.0;
      case PlaceKind.food:
        return 2.0;
      case PlaceKind.shopping:
        return 1.5;
      case PlaceKind.flights:
        return 3.0;
      case PlaceKind.transport:
        return 0.5;
      case PlaceKind.others:
        return 1.0;
    }
  }

  static int? _minutesFromHHmm(String value) {
    if (value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Builds a key-stop recommendation. When [radiusKm] is null an automatic
  /// radius is derived from the place spacing.
  static RouteRecommendation recommendKeyStops(
    List<ItineraryPlace> places, {
    double? radiusKm,
  }) {
    final withCoords = places.where((p) => p.lat != null && p.lng != null).toList();
    if (withCoords.length <= 1) {
      return RouteRecommendation(
        keyStops: withCoords,
        satellites: {for (final p in withCoords) p: <ItineraryPlace>[]},
        originalCount: withCoords.length,
        radiusKm: radiusKm ?? 0.5,
        fullDistanceKm: 0,
        keyDistanceKm: 0,
      );
    }

    final radius = radiusKm ?? autoRadiusKm(withCoords);

    // Elect key stops greedily, most important first.
    final byImportance = [...withCoords]
      ..sort((a, b) {
        final cmp = placeImportance(b).compareTo(placeImportance(a));
        if (cmp != 0) return cmp;
        return a.startTime.compareTo(b.startTime);
      });

    final keys = <ItineraryPlace>[];
    final satellites = <ItineraryPlace, List<ItineraryPlace>>{};

    for (final p in byImportance) {
      ItineraryPlace? nearestKey;
      var bestDist = double.infinity;
      for (final k in keys) {
        final d = haversineKm(k.lat!, k.lng!, p.lat!, p.lng!);
        if (d <= radius && d < bestDist) {
          bestDist = d;
          nearestKey = k;
        }
      }
      if (nearestKey == null) {
        keys.add(p);
        satellites[p] = <ItineraryPlace>[];
      } else {
        satellites[nearestKey]!.add(p);
      }
    }

    final orderedKeys = optimize(keys);

    return RouteRecommendation(
      keyStops: orderedKeys,
      satellites: satellites,
      originalCount: withCoords.length,
      radiusKm: radius,
      fullDistanceKm: routeDistanceKm(currentOrder(withCoords)),
      keyDistanceKm: routeDistanceKm(orderedKeys),
    );
  }
}

/// Result of a key-stop recommendation.
class RouteRecommendation {
  final List<ItineraryPlace> keyStops; // ordered main stops
  final Map<ItineraryPlace, List<ItineraryPlace>> satellites; // key → nearby minor stops
  final int originalCount;
  final double radiusKm;
  final double fullDistanceKm;
  final double keyDistanceKm;

  const RouteRecommendation({
    required this.keyStops,
    required this.satellites,
    required this.originalCount,
    required this.radiusKm,
    required this.fullDistanceKm,
    required this.keyDistanceKm,
  });

  int get keyCount => keyStops.length;

  int get mergedCount => originalCount - keyCount;

  double get savingsPercent => fullDistanceKm > 0
      ? ((1 - keyDistanceKm / fullDistanceKm) * 100).clamp(0, 99).toDouble()
      : 0;

  List<ItineraryPlace> satellitesFor(ItineraryPlace key) => satellites[key] ?? const [];
}
