import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kurir_pos/View/tools/custom_toast.dart';
import 'package:kurir_pos/view-model-flutter/barang_controller.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import '../api_config.dart';

Future<String?> createqris(int amount, BuildContext context) async {
  try {
    final qrData = {
      'amount': amount,
      'callback_url': "https://yourcallbackurl.com",
    };
    final url = '${ApiConfig().baseUrl}/xendit/create-qris';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(qrData),
    );
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseData['qrCodeUrl'];
    } else {
      showToast(context, "Gagal menampilkan QR");
      print('HTTP Error: ${response.statusCode}');
      return "";
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
}

void createInvoice(String external_id, int amount, String payer_email,
    String description, BuildContext context) async {
  try {
    final InvoiceData = {
      'external_id': external_id,
      'amount': amount,
      'payer_email': payer_email,
      'description': description,
    };
    final url = '${ApiConfig().baseUrl}/xendit/create-qris';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(InvoiceData),
    );

    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menampilkan Invoice');
    } else {
      showToast(context, "Gagal menampilkan Invoice");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
}

Future<Map<String, dynamic>?> addTrans(
  String payment_method,
  bool delivery,
  String desc,
  List<Map<String, dynamic>> items,
  String status,
  double grand_total,
  BuildContext context,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  DateTime trans_date = DateTime.now();

  try {
    for (var cartItem in items) {
      String id_barang = cartItem['id_reference'];
      String id_satuan = cartItem['id_satuan'];
      int quantity = cartItem['trans_qty'];
      updatejumlahSatuan(id_barang, id_satuan, quantity, 'kurang', context);
    }

    // Prepare transaction data
    final transData = {
      'id_cabang': id_cabang,
      'trans_date':
          trans_date.toIso8601String(), // Ensure date is properly formatted
      'payment_method': payment_method,
      'delivery': delivery,
      'desc': desc,
      'status': status,
      'grand_total': grand_total,
      'Items': items,
    };

    // Send the transaction data to the server
    final url = '${ApiConfig().baseUrl}/transaksi/addtrans/$id_cabang';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transData),
    );

    // Handle the server response
    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }

  return null; // Return null in case of an error
}

//update transaction status after delivery
Future<Map<String, dynamic>?> updateTransStatus(
  BuildContext context,
  String id_transaksi,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final request = Uri.parse(
      '${ApiConfig().baseUrl}/transaksi/updateTransStatus/$id_cabang/$id_transaksi');

  try {
    final response = await http.put(
      request,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      showToast(context, "Transaction status updated successfully");
      return jsonData; // Return the updated transaction data
    } else if (response.statusCode == 404) {
      showToast(context, "Transaction not found");
    } else {
      showToast(context,
          "Failed to update transaction status: ${response.statusCode}");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }

  return null; // Return null in case of an error
}

//show alltrans in cabang
Future<List<Map<String, dynamic>>> getTrans() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final request =
      Uri.parse('${ApiConfig().baseUrl}/transaksi/translist/$id_cabang');
  final response = await http.get(request);
  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    print("ini data transaksi dari cabang: $data");
    return data.cast<Map<String, dynamic>>();
  } else {
    CustomToast(message: "Failed to load data: ${response.statusCode}");
    return [];
  }
}

// Get specific transaction by id
Future<Map<String, dynamic>?> getTransById(String trans_id) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');

  final request = Uri.parse(
      '${ApiConfig().baseUrl}/transaksi/translist/$id_cabang/$trans_id');
  final response = await http.get(request);

  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    final Map<String, dynamic>? transactionData = jsonData["data"];

    if (transactionData != null) {
      print("Transaction data: $transactionData");
      return transactionData;
    } else {
      print("Transaction not found.");
      return null;
    }
  } else {
    CustomToast(message: "Failed to load data: ${response.statusCode}");
    return null;
  }
}

//add delivery
Future<Map<String, dynamic>?> addDelivery(
  String alamat_tujuan,
  String no_telp_cust,
  String transaksi_id,
  BuildContext context,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  DateTime trans_date = DateTime.now();
  try {
    var DeliveryData = {
      'alamat_tujuan': alamat_tujuan,
      'no_telp_cust': no_telp_cust,
      'transaksi_id': transaksi_id,
    };
    final url = '${ApiConfig().baseUrl}/transaksi/addDelivery/$id_cabang';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(DeliveryData),
    );
    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
  return null; // Return null in case of an error
}

//update delivery status with pic
Future<List<dynamic>?> updateDeliveryStatus(
  BuildContext context,
  String id_transaksi, // Transaction ID to update
  String id_delivery,
  XFile? image, // New parameter for the image
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');

  // Prepare the URL
  final url =
      '${ApiConfig().baseUrl}/transaksi/updateDeliveryStatus/$id_cabang/$id_transaksi/$id_delivery';

  // Create a multipart request
  var request = http.MultipartRequest('PUT', Uri.parse(url));

  // Add the image file to the request
  if (image != null) {
    request.files.add(
      await http.MultipartFile.fromPath('deliveryPic', image.path),
    );
  }

  // Send the request
  try {
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);
      showToast(context, 'Berhasil memperbarui status pengiriman');
      return jsonResponse['data'];
    } else if (response.statusCode == 404) {
      showToast(context, "Pengiriman tidak ditemukan");
    } else {
      showToast(context, "Gagal memperbarui status pengiriman");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }

  return null; // Return null in case of an error
}

//delivery with status "In Progress"
Future<List<dynamic>?> showDelivery(
  BuildContext context,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');

  try {
    final url = '${ApiConfig().baseUrl}/transaksi/showDelivery/$id_cabang';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      showToast(context, 'Berhasil mengambil data pengiriman');
      final responseData = jsonDecode(response.body);
      return responseData['data'];
    } else if (response.statusCode == 404) {
      showToast(context, "Tidak ada pengiriman dalam proses");
    } else {
      showToast(context, "Gagal mengambil data pengiriman");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
  return null; // Return null in case of an error
}

//cetak invoice
Future<Map<String, dynamic>> generateInvoice(
    String nama_cabang,
    String alamat,
    String no_telp,
    DateTime date_trans,
    String payment_method,
    String delivery, //true = yes , false = no
    List<Map<String, dynamic>> items,
    BuildContext context) async {
  try {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    String dateinvoice = formatter.format(date_trans);
    final response = await http.post(
      Uri.parse('${ApiConfig().baseUrl}/invoice/generate-invoice'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'nama_cabang': nama_cabang,
        'alamat': alamat,
        'no_telp': no_telp,
        'date_trans': dateinvoice.toString(),
        'payment_method': payment_method,
        'delivery': delivery,
        'items': items,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice Successfully Generated')),
      );
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String invoicePath = responseBody['downloadUrl'];
      return {'success': true, 'invoicePath': invoicePath};
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invoice Failed to Generate')),
      );
      return {'success': false, 'invoicePath': null};
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error occurred while generating invoice: $e")),
    );
    return {'success': false, 'invoicePath': null};
  }
}

Future<bool> sendInvoiceByEmail(
    String invoicePath, String receiverEmail, BuildContext context) async {
  final Uri uri = Uri.parse('${ApiConfig().baseUrl}/invoice/invoice-email');
  try {
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Invoicepath': invoicePath,
        'receiveremail': receiverEmail,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice sent successfully')),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Failed to send invoice')),
      );
      return false;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error occurred while sending invoice: $e")),
    );
    return false;
  }
}
