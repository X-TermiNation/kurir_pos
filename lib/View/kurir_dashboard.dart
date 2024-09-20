import 'package:flutter/material.dart';
import 'package:kurir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:kurir_pos/View/tools/photon_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart';

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
  //map
  final PhotonService _photonService = PhotonService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  void _searchLocations() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final results = await _photonService.searchLocation(query);
      setState(() {
        _searchResults = results;
      });
    }
  }

  List<dynamic> _deliveries = [];

  @override
  void initState() {
    super.initState();
    fetchDeliveries(); // Fetch the deliveries on screen load
  }

  Future<void> fetchDeliveries() async {
    List<dynamic>? deliveries = await showDelivery(context); // Fetch deliveries
    if (deliveries != null) {
      setState(() {
        _deliveries = deliveries;
      });
    }
  }

  Future<String> fetchPaymentMethod(String transaksiId) async {
    // Assume getTransById is a function that fetches the transaction details
    Map<String, dynamic>? transaction = await getTransById(transaksiId);
    if (transaction != null) {
      return transaction['payment_method'] ?? 'Unknown';
    }
    return 'Unknown';
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
      body: _deliveries.isEmpty
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading spinner while fetching data
          : ListView.builder(
              itemCount: _deliveries.length,
              itemBuilder: (context, index) {
                var delivery = _deliveries[index];

                return FutureBuilder<String>(
                  future: fetchPaymentMethod(delivery['transaksi_id']),
                  builder: (context, snapshot) {
                    String paymentMethod = snapshot.data ?? 'Loading...';

                    return ListTile(
                      title: Text('Delivery #${delivery["_id"]}'),
                      subtitle: Text(
                          'Status: ${delivery["status"]}\nPayment Method: $paymentMethod \nStatus: ${delivery["status"]} \nAlamat Customer: ${delivery["alamat_tujuan"]} \n No.Telepon Customer: ${delivery["no_telp_cust"]} \nID Transaksi: ${delivery["transaksi_id"]}'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class MapScreen extends StatelessWidget {
  // void getLocation() async {
  //   Location location = Location();
  //   bool _serviceEnabled;
  //   PermissionStatus _permissionGranted;

  //   _serviceEnabled = await location.serviceEnabled();
  //   if (!_serviceEnabled) {
  //     _serviceEnabled = await location.requestService();
  //     if (!_serviceEnabled) {
  //       return;
  //     }
  //   }

  //   _permissionGranted = await location.hasPermission();
  //   if (_permissionGranted == PermissionStatus.denied) {
  //     _permissionGranted = await location.requestPermission();
  //     if (_permissionGranted != PermissionStatus.granted) {
  //       return;
  //     }
  //   }

  //   LocationData _locationData = await location.getLocation();
  //   print(
  //       'Latitude: ${_locationData.latitude}, Longitude: ${_locationData.longitude}');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenStreetMap with Flutter'),
      ),
      body: FlutterMap(
        options: MapOptions(
            initialCenter: LatLng(
                1.2878, 103.8666), // Use 'center' instead of 'initialCenter'
            initialZoom: 11, // 'zoom' replaces 'initialZoom'
            interactionOptions: const InteractionOptions(
                flags: ~InteractiveFlag.doubleTapZoom)),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName:
                'com.example.app', // Required in newer versions
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
