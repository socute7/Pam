import 'dart:convert';
import 'package:sertif/api.dart';
import 'package:http/http.dart' as http;

class Api {
  static const String _baseUrl = 'http://192.168.67.10/pam';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  static String getPelangganUrl() {
    return '$_baseUrl/get_pelanggan.php';
  }

  static String getMeterAwalUrl(String idPelanggan) {
    return '$_baseUrl/get_meter_awal.php?id_pelanggan=$idPelanggan';
  }

  static String getUploadTransaksiUrl() {
    return '$_baseUrl/upload_transaksi.php';
  }

  static String getHargaUrl(String statusPelanggan) {
    return '$_baseUrl/get_harga.php?status=$statusPelanggan';
  }

  static String getHargaAbonemenUrl(String status) {
    return '$_baseUrl/get_harga.php?status=$status';
  }

  static Future<Map<String, dynamic>> updatePetugas(
      String idPetugas, String nama, String alamat, String telp) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/update_petugas.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_petugas': idPetugas,
        'nama': nama,
        'alamat': alamat,
        'telp': telp,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  static Future<List<dynamic>> getAllTransactions() async {
    final response =
        await http.get(Uri.parse('$_baseUrl/get_all_transactions.php'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }
}
