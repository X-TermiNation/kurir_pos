import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:kurir_pos/view-model-flutter/transaksi_controller.dart';

class CourierDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Courier Delivery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _deliveries = [];
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDeliveries();
  }

  Future<void> fetchDeliveries() async {
    List<dynamic>? deliveries = await showDelivery(context); // Fetch deliveries
    if (deliveries != null) {
      setState(() {
        _deliveries = deliveries;
      });
    }
  }

  Future<Position?> fetchCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courier Delivery'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Enter Address',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () async {
                    String address = _addressController.text;
                    Position? currentLocation = await fetchCurrentLocation();
                    if (currentLocation != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            currentLocation: currentLocation,
                            destinationAddress: address,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Could not access location.'),
                      ));
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _deliveries.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _deliveries.length,
                    itemBuilder: (context, index) {
                      var delivery = _deliveries[index];
                      return ListTile(
                        title: Text('Delivery #${delivery["_id"]}'),
                        subtitle: Text(
                            'Status: ${delivery["status"]}\nAlamat Customer: ${delivery["alamat_tujuan"]} \nNo.Telepon Customer: ${delivery["no_telp_cust"]} \nID Transaksi: ${delivery["transaksi_id"]}'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () async {
                          Position? currentLocation =
                              await fetchCurrentLocation();
                          if (currentLocation != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapScreen(
                                  currentLocation: currentLocation,
                                  destinationAddress:
                                      "${delivery["alamat_tujuan"]}",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Could not access location.'),
                            ));
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final Position currentLocation;
  final String destinationAddress;

  MapScreen({required this.currentLocation, required this.destinationAddress});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> polylinePoints = [];

  @override
  void initState() {
    super.initState();
    _getDestinationCoordinates(widget.destinationAddress);
  }

  Future<void> _getDestinationCoordinates(String address) async {
    try {
      print('Searching for address: $address'); // Debugging
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        double destinationLat = locations.first.latitude;
        double destinationLng = locations.first.longitude;
        await _fetchDirections(destinationLng, destinationLat);
      } else {
        print('No locations found for the address.'); // Debugging
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not find destination address.'),
        ));
      }
    } catch (e) {
      print('Error: $e'); // Debugging
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not find destination address.'),
      ));
    }
  }

  Future<void> _fetchDirections(
      double destinationLng, double destinationLat) async {
    print('Fetching directions...');
    print(
        'Start: (${widget.currentLocation.longitude}, ${widget.currentLocation.latitude}), End: ($destinationLng, $destinationLat)');

    // Replace 'YOUR_API_KEY' with your actual OpenRouteService API key
    final String apiKey =
        '5b3ce3597851110001cf6248e4d9fd9aea234edf85a286746755089e';

    final response = await http.get(Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?start=${widget.currentLocation.longitude},${widget.currentLocation.latitude}&end=$destinationLng,$destinationLat&api_key=$apiKey'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<LatLng> points = [];
      for (var point in data['features'][0]['geometry']['coordinates']) {
        points.add(LatLng(point[1], point[0]));
      }
      setState(() {
        polylinePoints = points;
      });
    } else {
      print(
          'Failed to load directions: ${response.statusCode} ${response.body}'); // Added logging
      throw Exception('Failed to load directions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directions'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(widget.currentLocation.latitude,
              widget.currentLocation.longitude),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(widget.currentLocation.latitude,
                    widget.currentLocation.longitude),
                width: 80,
                height: 80,
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              if (polylinePoints
                  .isNotEmpty) // Check if polylinePoints is not empty
                Marker(
                  point: LatLng(polylinePoints.last.latitude,
                      polylinePoints.last.longitude), // Destination marker
                  width: 80,
                  height: 80,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Courier Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Name: John Doe'),
            SizedBox(height: 16),
            Text('Email: johndoe@example.com'),
            SizedBox(height: 16),
            Text('Phone: +123 456 7890'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
