import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapboxService {
  // Use the token provided by the user
  static const String _accessToken = 'pk.eyJ1IjoidGhuaHRoYW8iLCJhIjoiY21zMTV1aGRoMDBhZzJ4b2gwOGp2djd1cCJ9.FAfa4g8ZP_B0MrBcLA1mLw';

  /// Fetches the real road route (polyline) between a list of coordinates using Mapbox Directions API.
  /// Mapbox allows a maximum of 25 coordinates per request.
  static Future<List<LatLng>> getRoute(List<LatLng> points) async {
    if (points.length < 2) return points;
    
    // If points > 25, we need to chunk them because of API limits.
    // We'll chunk them in overlapping groups (e.g., 0-24, 24-48) to connect the segments.
    List<LatLng> fullRoute = [];
    
    int i = 0;
    while (i < points.length - 1) {
      int end = (i + 25 <= points.length) ? i + 25 : points.length;
      final chunk = points.sublist(i, end);
      
      final chunkRoute = await _fetchDirectionsChunk(chunk);
      if (chunkRoute.isNotEmpty) {
        // Avoid adding the exact same start point if it's not the first chunk
        if (fullRoute.isNotEmpty && fullRoute.last == chunkRoute.first) {
          fullRoute.addAll(chunkRoute.sublist(1));
        } else {
          fullRoute.addAll(chunkRoute);
        }
      }
      
      i += 24; // overlapping index
    }
    
    // Fallback: If API fails completely, return straight lines.
    return fullRoute.isNotEmpty ? fullRoute : points;
  }
  
  static Future<List<LatLng>> _fetchDirectionsChunk(List<LatLng> points) async {
    try {
      // Mapbox expects: {longitude},{latitude};{longitude},{latitude}
      final coordinatesStr = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/driving/$coordinatesStr'
          '?geometries=geojson&access_token=$_accessToken');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert GeoJSON [lon, lat] to LatLng(lat, lon)
          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }
    } catch (e) {
      print('Mapbox directions error: $e');
    }
    
    // Return empty list on failure
    return [];
  }
}
