import 'dart:convert';
import 'package:http/http.dart' as http;

class PhotonService {
  static const String photonUrl = "https://photon.komoot.io/api/";

  // Search for places by name (forward geocoding)
  Future<List<dynamic>> searchLocation(String query) async {
    final url = "$photonUrl?q=$query";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['features'];
    } else {
      throw Exception('Failed to load locations');
    }
  }

  // Reverse geocoding (latitude and longitude to address)
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    final url = "$photonUrl/reverse?lat=$lat&lon=$lon";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['features'][0];
    } else {
      throw Exception('Failed to reverse geocode');
    }
  }
}
