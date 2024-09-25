import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kurir_pos/View/tools/websocket_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:kurir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

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
                            telp_number: "#",
                            id_transaksi: "#",
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
                                  telp_number: "${delivery["no_telp_cust"]}",
                                  id_transaksi: "${delivery["_id"]}",
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
  final String telp_number;
  final String id_transaksi;

  MapScreen(
      {required this.currentLocation,
      required this.destinationAddress,
      required this.telp_number,
      required this.id_transaksi});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> polylinePoints = [];
  LatLng? currentPosition;
  bool isDelivering = false;
  late WebSocketService _webSocketService;
  StreamSubscription<Position>? positionStreamSubscription;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _getDestinationCoordinates(widget.destinationAddress);

    currentPosition = LatLng(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
    );

    _webSocketService = WebSocketService('ws://192.168.1.197:8080/ws');

    // Listen for live location updates from the WebSocket server
    _webSocketService.onMessage.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'live_location_update') {
        print(
            'Received live position: Latitude: ${data['latitude']}, Longitude: ${data['longitude']}');
        // Update current position to reflect the received data
        setState(() {
          currentPosition = LatLng(data['latitude'], data['longitude']);
        });
      }
    });
  }

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    _webSocketService.close(); // Close WebSocket connection
    super.dispose();
  }

  // Get destination coordinates
  Future<void> _getDestinationCoordinates(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        double destinationLat = locations.first.latitude;
        double destinationLng = locations.first.longitude;
        await _fetchDirections(destinationLng, destinationLat);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not find destination address.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not find destination address.'),
      ));
    }
  }

  // Fetch route directions
  Future<void> _fetchDirections(
      double destinationLng, double destinationLat) async {
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
      throw Exception('Failed to load directions');
    }
  }

// Start delivery and track live location
  void _startDelivery() {
    // Start sending the initial location to the server
    _sendLocationToServer(
        widget.currentLocation.latitude, widget.currentLocation.longitude);

    // Listen for live location updates
    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Updates every 2 meters
      ),
    ).listen((Position position) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
      // Send updated position to the server
      _sendLocationToServer(position.latitude, position.longitude);
    });

    setState(() {
      isDelivering = true; // Change state to indicate delivery has started
    });
  }

  // Send location to the WebSocket server
  void _sendLocationToServer(double latitude, double longitude) {
    _webSocketService.sendMessage(jsonEncode({
      'id_transaksi': widget.id_transaksi,
      'latitude': latitude,
      'longitude': longitude,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directions'),
      ),
      body: SlidingUpPanel(
        panel: _buildSlidingPanel(context),
        minHeight: 100,
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                // Current position marker (live location)
                Marker(
                  point: currentPosition ??
                      LatLng(widget.currentLocation.latitude,
                          widget.currentLocation.longitude),
                  width: 80,
                  height: 80,
                  child: Icon(
                    isDelivering
                        ? Icons.motorcycle
                        : Icons
                            .place, // Use motorcycle icon if delivering, otherwise a generic marker icon
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                // Destination marker
                if (polylinePoints.isNotEmpty)
                  Marker(
                    point: LatLng(polylinePoints.last.latitude,
                        polylinePoints.last.longitude),
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
      ),
    );
  }

  // Sliding panel for delivery information
  Widget _buildSlidingPanel(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            'Delivery Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Alamat Customer: ${widget.destinationAddress}'),
          SizedBox(height: 8),
          Text('ID Transaksi: ${widget.id_transaksi}'),
          SizedBox(height: 8),
          Text('No. Telepon: ${widget.telp_number}'),
          SizedBox(height: 32),
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (isDelivering) {
                    _startDelivery();
                  } else {
                    setState(() {
                      isDelivering = true;
                    });
                  }
                },
                child: Text(isDelivering ? 'Delivering...' : 'Start Delivery'),
              ),
              if (isDelivering)
                ElevatedButton(
                  onPressed: () {
                    _showFinishDeliveryDialog(); // Correctly calling the dialog method
                  },
                  child: Text("Finish Delivery"),
                ),
            ],
          )),
        ],
      ),
    );
  }

  // Method to show the finish delivery dialog
  void _showFinishDeliveryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FinishDeliveryDialog(
          image: _image, // Pass the current image
          onImageTaken: (newImage) {
            setState(() {
              _image = newImage; // Update the image taken in parent state
            });
          },
        );
      },
    );
  }
}

class FinishDeliveryDialog extends StatefulWidget {
  final XFile? image;
  final Function(XFile?) onImageTaken;

  FinishDeliveryDialog({required this.image, required this.onImageTaken});

  @override
  _FinishDeliveryDialogState createState() => _FinishDeliveryDialogState();
}

class _FinishDeliveryDialogState extends State<FinishDeliveryDialog> {
  late XFile? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.image; // Initialize the image from widget
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Finish Delivery'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_image != null) ...[
            Image.file(
              File(_image!.path),
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _image = null; // Reset image to null
                });
                widget.onImageTaken(null); // Notify parent to delete the photo
              },
              child: Text('Delete Photo'),
            ),
          ] else ...[
            Text('No photo taken.'),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final pickedFile = await ImagePicker().pickImage(
              source: ImageSource.camera,
            );
            if (pickedFile != null) {
              setState(() {
                _image = pickedFile; // Update local state
              });
              widget.onImageTaken(
                  pickedFile); // Notify parent about the new photo
            }
          },
          child: Text('Take Photo'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Finish'),
        ),
      ],
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
