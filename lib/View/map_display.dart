// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class MapScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('OpenStreetMap with Flutter'),
//       ),
//       body: FlutterMap(
//         options: MapOptions(
//           center: LatLng(51.5, -0.09), // Coordinates for initial map center
//           zoom: 13.0,
//         ),
//         layers: [
//           TileLayerOptions(
//             urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//             subdomains: ['a', 'b', 'c'],
//           ),
//           MarkerLayerOptions(
//             markers: [
//               Marker(
//                 width: 80.0,
//                 height: 80.0,
//                 point: LatLng(51.5, -0.09),
//                 builder: (ctx) => Container(
//                   child: FlutterLogo(),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
