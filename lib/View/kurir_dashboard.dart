import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kurir_pos/View/tools/websocket_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kurir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:qr/qr.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

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
  Map<String, Map<String, dynamic>?> _transactions = {};
  // final TextEditingController _addressController = TextEditingController();

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

  Future<void> fetchTransaction(String idTransaction) async {
    Map<String, dynamic>? transactionData =
        await getTransById(idTransaction); // Fetch transaction data
    if (transactionData != null) {
      setState(() {
        _transactions[idTransaction] =
            transactionData; // Store transaction data
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
          //search bar for location testing
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: TextField(
          //     controller: _addressController,
          //     decoration: InputDecoration(
          //       labelText: 'Enter Address',
          //       suffixIcon: IconButton(
          //         icon: Icon(Icons.search),
          //         onPressed: () async {
          //           String address = _addressController.text;
          //           Position? currentLocation = await fetchCurrentLocation();
          //           if (currentLocation != null) {
          //             await Navigator.push(
          //               context,
          //               MaterialPageRoute(
          //                 builder: (context) => MapScreen(
          //                   currentLocation: currentLocation,
          //                   destinationAddress: address,
          //                   telp_number: "#",
          //                   id_transaksi: "#",
          //                 ),
          //               ),
          //             );
          //           } else {
          //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //               content: Text('Could not access location.'),
          //             ));
          //           }
          //         },
          //       ),
          //     ),
          //   ),
          // ),
          Expanded(
            child: _deliveries.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _deliveries.length,
                    itemBuilder: (context, index) {
                      var delivery = _deliveries[index];
                      String transactionId = delivery["transaksi_id"];

                      // Fetch transaction if not already fetched
                      if (!_transactions.containsKey(transactionId)) {
                        fetchTransaction(transactionId);
                      }
                      // Get payment method if transaction data is available

                      String paymentMethod = _transactions[transactionId]
                              ?["payment_method"] ??
                          "N/A";

                      String grandtotal = "N/A";

                      if (_transactions[transactionId]?["grand_total"] !=
                          null) {
                        double grandTotal = double.parse(
                            _transactions[transactionId]?["grand_total"]
                                    .toString() ??
                                "0");
                        grandtotal = grandTotal.toString();
                      }

                      return ListTile(
                        title: Text('Delivery #${delivery["_id"]}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${delivery["status"]}'),
                            Text(
                                'Alamat Customer: ${delivery["alamat_tujuan"]}'),
                            Text(
                                'No.Telepon Customer: ${delivery["no_telp_cust"]}'),
                            Text('ID Transaksi: ${delivery["transaksi_id"]}'),
                            Text('Payment Method: $paymentMethod'),
                          ],
                        ),
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
                                    id_delivery: "${delivery["_id"]}",
                                    telp_number: "${delivery["no_telp_cust"]}",
                                    id_transaksi: "${delivery["transaksi_id"]}",
                                    payment_method: "$paymentMethod",
                                    grand_total: "$grandtotal"),
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
  final String id_delivery;
  final String telp_number;
  final String id_transaksi;
  final String payment_method;
  final String grand_total;

  MapScreen(
      {required this.currentLocation,
      required this.destinationAddress,
      required this.id_delivery,
      required this.telp_number,
      required this.id_transaksi,
      required this.payment_method,
      required this.grand_total});

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
        minHeight: 90,
        maxHeight: MediaQuery.of(context).size.height * 0.5,
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
          Text('Delivery ID : ${widget.id_delivery}'),
          Text('Alamat Customer: ${widget.destinationAddress}'),
          SizedBox(height: 8),
          Text('ID Transaksi: ${widget.id_transaksi}'),
          SizedBox(height: 8),
          Text('No. Telepon: ${widget.telp_number}'),
          SizedBox(
            height: 8,
          ),
          Text('Payment Method: ${widget.payment_method}'),
          SizedBox(height: 15),
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
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return FinishDeliveryDialog(
          image: _image,
          onImageTaken: (newImage) {
            setState(() {
              _image =
                  newImage; // Update the image when photo is taken or deleted
            });
          },
          id_delivery: widget.id_delivery,
          id_transaksi: widget.id_transaksi,
          payment_method: widget.payment_method,
          grand_total: widget.grand_total,
        );
      },
    );
  }
}

class FinishDeliveryDialog extends StatefulWidget {
  final XFile? image;
  final Function(XFile?) onImageTaken;
  final String id_delivery;
  final String id_transaksi;
  final String payment_method;
  final String grand_total;

  FinishDeliveryDialog(
      {required this.image,
      required this.onImageTaken,
      required this.id_delivery,
      required this.id_transaksi,
      required this.payment_method,
      required this.grand_total});

  @override
  _FinishDeliveryDialogState createState() => _FinishDeliveryDialogState();
}

class _FinishDeliveryDialogState extends State<FinishDeliveryDialog> {
  late XFile? _image;
  String? qrCodeUrl;
  bool _isLoading = true;
  String grandTotal = "N/A";
  bool CanFinish = false;
  @override
  void initState() {
    super.initState();
    double grandtotaltemp = double.parse(widget.grand_total);
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'id', symbol: 'Rp.', decimalDigits: 2);
    grandTotal = currencyFormat.format(grandtotaltemp);
    if (widget.payment_method == 'QRIS') {
      _fetchQRCodeUrl();
    }
    _image = widget.image; // Initialize the image from widget
  }

  Future<Uint8List> generateQrImage(String data) async {
    final qr = QrCode(4, QrErrorCorrectLevel.L);
    qr.addData(data);
    qr.make();

    final qrCodeSize = 200.0;
    final size = qrCodeSize.toInt();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(
        pictureRecorder,
        Rect.fromPoints(
            Offset(0, 0), Offset(size.toDouble(), size.toDouble())));

    final paint = Paint()..color = Colors.black;

    for (var x = 0; x < qr.moduleCount; x++) {
      for (var y = 0; y < qr.moduleCount; y++) {
        if (qr.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(
                x * qrCodeSize / qr.moduleCount,
                y * qrCodeSize / qr.moduleCount,
                qrCodeSize / qr.moduleCount,
                qrCodeSize / qr.moduleCount),
            paint,
          );
        }
      }
    }
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _fetchQRCodeUrl() async {
    try {
      final double grandTotalDouble = double.parse(widget.grand_total);
      final url = await createqris(grandTotalDouble.toInt(), context);
      setState(() {
        qrCodeUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        // Make it scrollable
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Pembayaran",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 8),
                  if (widget.payment_method == "QRIS") ...[
                    Center(
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Scan Here",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                FutureBuilder<Uint8List>(
                                  future: generateQrImage(qrCodeUrl!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error generating QR code');
                                    } else {
                                      return SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: Image.memory(snapshot.data!),
                                      );
                                    }
                                  },
                                ),
                                Text(
                                  "a/n xxx xxx xxx",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ] else ...[
                    SizedBox(height: 20),
                    Center(
                      child: Text('Pembayaran Dilakukan Secara Tunai.'),
                    ),
                  ],
                  SizedBox(height: 5),
                  Text(
                    "Grand Total: ${grandTotal}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text("Bukti Pengiriman"),
            ),
            SizedBox(height: 8),
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
                    _image = null;
                    CanFinish = false;
                  });
                  widget.onImageTaken(null);
                },
                child: Text('Delete Photo'),
              ),
            ] else ...[
              Text('No photo taken.'),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final pickedFile = await ImagePicker().pickImage(
              source: ImageSource.camera,
            );
            if (pickedFile != null) {
              setState(() {
                _image = pickedFile;
                CanFinish = true;
              });
              widget.onImageTaken(pickedFile);
            }
          },
          child: Text('Take Photo'),
        ),
        ElevatedButton(
          onPressed: () {
            if (CanFinish) {
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(CanFinish ? 'Finish' : 'Cancel'),
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
