import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'api.dart';

class TransaksiScreen extends StatefulWidget {
  @override
  _TransaksiScreenState createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final List<String> bulanList = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  String selectedBulan = '';
  String selectedPelanggan = '';
  String namaPelanggan = '';
  String statusPelanggan = '';
  int meterAwal = 0;
  int hasilMeter = 0;
  double hargaMeter = 0.0;
  double abonemen = 0.0;
  double totalHarga = 0.0;
  TextEditingController textEditingController = TextEditingController();
  TextEditingController meterAkhirController = TextEditingController();
  List<Map<String, dynamic>> pelangganList = [];
  File? image;
  http.MultipartRequest? request;

  Future<void> fetchData() async {
    var url = Uri.parse(Api.getPelangganUrl());

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        pelangganList = data.cast<Map<String, dynamic>>();
        setState(() {});
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchMeterAwal(String idPelanggan) async {
    var url = Uri.parse(Api.getMeterAwalUrl(idPelanggan));

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          meterAwal = data['meter_awal'];
        });
      } else {
        throw Exception('Gagal mengambil meter awal');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double lat = position.latitude;
      double lng = position.longitude;

      // Pastikan request tidak null sebelum mengakses fields
      request?.fields['lat'] = lat.toString();
      request?.fields['lng'] = lng.toString();
    } catch (e) {
      print('Gagal mendapatkan lokasi: $e');
    }
  }

  Future<void> fetchHargaAbonemen(String status) async {
    var url = Uri.parse(Api.getHargaAbonemenUrl(status));

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          hargaMeter = double.parse(data['harga'].toString());
          abonemen = double.parse(data['abonemen'].toString());
        });
      } else {
        throw Exception('Gagal mengambil harga dan abonemen');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> calculateHarga() async {
    try {
      var url = Api.getHargaUrl(statusPelanggan);
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        double? fetchedHarga =
            data['harga'] != null ? double.parse(data['harga']) : null;

        if (fetchedHarga != null) {
          double harga = hasilMeter * fetchedHarga;

          setState(() {
            hargaMeter = harga;
            calculateTotalHarga();
          });
        } else {
          setState(() {
            hargaMeter = 0.0;
            totalHarga = abonemen;
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content:
                  Text('Harga tidak ditemukan untuk status pelanggan ini.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Gagal memuat data: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void updatePelangganData(String pelangganId) {
    var selectedData = pelangganList
        .firstWhere((element) => element['id_pelanggan'] == pelangganId);
    setState(() {
      namaPelanggan = selectedData['nama'];
      statusPelanggan = selectedData['status'];
      selectedPelanggan = pelangganId;
      fetchMeterAwal(pelangganId);
      fetchHargaAbonemen(statusPelanggan);
    });
  }

  Future<void> pickImage() async {
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return;

      final imageTemp = File(pickedImage.path);

      if (pickedImage.path.endsWith('.png')) {
        final imageBytes = await imageTemp.readAsBytes();
        final decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          final jpgImageBytes = img.encodeJpg(decodedImage);
          final jpgImageFile =
              await File('${pickedImage.path}.jpg').writeAsBytes(jpgImageBytes);
          setState(() => image = jpgImageFile);
        } else {
          setState(() => image = imageTemp);
        }
      } else {
        setState(() => image = imageTemp);
      }
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    } catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> _submitData() async {
    String tahun = textEditingController.text;
    String meterAkhir = meterAkhirController.text;

    double? lat;
    double? lng;

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      print('Gagal mendapatkan lokasi: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Gagal mendapatkan lokasi: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedBulan.isEmpty ||
        selectedPelanggan.isEmpty ||
        tahun.isEmpty ||
        meterAkhir.isEmpty ||
        image == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Peringatan'),
          content: Text('Pastikan semua input terisi dan foto dipilih.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await getLocation();

    int meterAwalValue = meterAwal;
    int meterAkhirValue = int.parse(meterAkhir);
    int hasilMeter = meterAkhirValue - meterAwalValue;
    double totalTagihan = hargaMeter + abonemen;

    var url = Api.getUploadTransaksiUrl();
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['id_pelanggan'] = selectedPelanggan;
    request.fields['bulan'] = selectedBulan;
    request.fields['tahun'] = tahun;
    request.fields['meter_awal'] = meterAwalValue.toString();
    request.fields['meter_akhir'] = meterAkhirValue.toString();
    request.fields['volume'] = hasilMeter.toString();
    request.fields['tagihan'] = hargaMeter.toString();
    request.fields['abonemen'] = abonemen.toString();
    request.fields['total_tagihan'] = totalTagihan.toString();
    request.fields['status'] = '0';
    request.fields['nama_pelanggan'] = namaPelanggan;
    request.fields['status_pelanggan'] = statusPelanggan;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();

    var fileStream = http.ByteStream(image!.openRead());
    var length = await image!.length();
    var multipartFile = http.MultipartFile(
      'foto',
      fileStream,
      length,
      filename: image!.path.split('/').last,
    );

    request.files.add(multipartFile);

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseData);

      print('Response Data: $decodedResponse');

      if (response.statusCode == 201) {
        if (decodedResponse['status'] == 'success') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Sukses'),
              content: Text('Data transaksi berhasil disimpan.'),
              actions: [
                TextButton(
                  onPressed: () {
                    resetForm();
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Cetak pesan kesalahan dari server jika ada
          print(
              'Server responded with an error: ${decodedResponse['message']}');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text(
                  'Gagal menyimpan data transaksi: ${decodedResponse['message']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Handle HTTP error
        print('HTTP Error: ${response.reasonPhrase}');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(
                'Gagal menyimpan data transaksi: ${response.reasonPhrase}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cetak exception untuk membantu debugging
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Gagal menyimpan data transaksi: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Bulan dan Pelanggan'),
      ),
      body: pelangganList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    DropdownButton<String>(
                      value: selectedBulan.isEmpty ? null : selectedBulan,
                      hint: Text('Pilih Bulan'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBulan = newValue ?? '';
                        });
                      },
                      items: bulanList.map<DropdownMenuItem<String>>(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(),
                    ),
                    SizedBox(height: 20),
                    DropdownButton<String>(
                      value:
                          selectedPelanggan.isEmpty ? null : selectedPelanggan,
                      hint: Text('Pilih Pelanggan'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPelanggan = newValue ?? '';
                          updatePelangganData(selectedPelanggan);
                        });
                      },
                      items: pelangganList.map<DropdownMenuItem<String>>(
                        (Map<String, dynamic> pelanggan) {
                          return DropdownMenuItem<String>(
                            value: pelanggan['id_pelanggan'],
                            child: Text(
                                '${pelanggan['nama']} - ${pelanggan['status']}'),
                          );
                        },
                      ).toList(),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: textEditingController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan Tahun',
                        labelText: 'Tahun',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: namaPelanggan),
                      decoration: InputDecoration(
                        labelText: 'Nama Pelanggan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: statusPelanggan),
                      decoration: InputDecoration(
                        labelText: 'Status Pelanggan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller:
                          TextEditingController(text: meterAwal.toString()),
                      decoration: InputDecoration(
                        labelText: 'Meter Awal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: image == null
                            ? Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey[700],
                                ),
                              )
                            : Image.file(
                                image!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Foto Laporan',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: meterAkhirController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan Meter Akhir',
                        labelText: 'Meter Akhir',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        // Calculate hasilMeter
                        calculateHasilMeter();
                      },
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller:
                          TextEditingController(text: hasilMeter.toString()),
                      decoration: InputDecoration(
                        labelText: 'Hasil Meter',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                          text: hargaMeter.toStringAsFixed(2)),
                      decoration: InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller:
                          TextEditingController(text: abonemen.toString()),
                      decoration: InputDecoration(
                        labelText: 'Abonemen',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                          text: totalHarga.toStringAsFixed(2)),
                      decoration: InputDecoration(
                        labelText: 'Total Harga',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitData,
                      child: Text('Simpan Transaksi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void calculateHasilMeter() {
    if (meterAkhirController.text.isEmpty) {
      setState(() {
        hasilMeter = 0;
        hargaMeter = 0.0;
        totalHarga = 0.0;
      });
    } else {
      int meterAkhirValue = int.tryParse(meterAkhirController.text) ?? 0;
      hasilMeter = meterAkhirValue - meterAwal;

      if (hasilMeter > 0) {
        calculateHarga();
      } else {
        setState(() {
          hargaMeter = 0.0;
          totalHarga = abonemen;
        });
      }
    }
  }

  void resetForm() {
    setState(() {
      selectedBulan = '';
      selectedPelanggan = '';
      namaPelanggan = '';
      statusPelanggan = '';
      meterAwal = 0;
      hasilMeter = 0;
      hargaMeter = 0.0;
      abonemen = 0.0;
      totalHarga = 0.0;
      textEditingController.text = '';
      meterAkhirController.text = '';
      image = null;
    });
  }

  void calculateTotalHarga() {
    setState(() {
      totalHarga = hargaMeter + abonemen;
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    meterAkhirController.dispose();
    super.dispose();
  }
}
