import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sertif/api.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    try {
      List<dynamic> response = await Api.getAllTransactions();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching transactions: $e');
      return []; // Return empty list or handle error accordingly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Transaksi'),
      ),
      body: FutureBuilder(
        future: fetchTransactions(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            // Data successfully loaded
            List<Map<String, dynamic>> transactions = snapshot.data!;
            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                String statusText = transactions[index]['status'] == 1
                    ? 'Sudah Dibayar'
                    : 'Belum Dibayar';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(
                        'ID Transaksi: ${transactions[index]['id_transaksi']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'ID Pelanggan: ${transactions[index]['id_pelanggan']}'),
                        Text('Bulan: ${transactions[index]['bulan']}'),
                        Text('Tahun: ${transactions[index]['tahun']}'),
                        Text(
                            'Meter Awal: ${transactions[index]['meter_awal']}'),
                        Text(
                            'Meter Akhir: ${transactions[index]['meter_akhir']}'),
                        Text('Volume: ${transactions[index]['volume']}'),
                        Text('Tagihan: ${transactions[index]['tagihan']}'),
                        Text('Abonemen: ${transactions[index]['abonemen']}'),
                        Text(
                            'Total Tagihan: ${transactions[index]['total_tagihan']}'),
                        Text('Status: $statusText'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
