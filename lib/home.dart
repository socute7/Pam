import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sertif/api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'transaksi.dart';
import 'akun.dart';
import 'info.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  Position? _currentPosition;
  String? _latitude;
  String? _longitude;
  String _address = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void refreshHomePage() {
    // Implement refresh logic here
    _getCurrentLocation(); // Example: Refreshing location data
    setState(() {
      // Additional state changes if needed
    });
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDisabledDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      setState(() {
        _latitude = _currentPosition!.latitude.toString();
        _longitude = _currentPosition!.longitude.toString();
        _address = placemarks[0].name.toString() +
            ', ' +
            placemarks[0].subLocality.toString() +
            ', ' +
            placemarks[0].locality.toString() +
            ', ' +
            placemarks[0].administrativeArea.toString() +
            ', ' +
            placemarks[0].country.toString() +
            ', ' +
            placemarks[0].postalCode.toString();
      });
    } catch (e) {
      print(e);
    }
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Layanan Lokasi Tidak Aktif'),
        content: Text(
            'Silakan aktifkan layanan lokasi untuk menggunakan aplikasi ini.'),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Izin Lokasi Ditolak'),
        content: Text(
            'Anda harus mengizinkan akses lokasi untuk menggunakan aplikasi ini.'),
        actions: <Widget>[
          TextButton(
            child: Text('Buka Pengaturan'),
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
          ),
          TextButton(
            child: Text('Tutup'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            currentPosition: _currentPosition,
            latitude: _latitude,
            longitude: _longitude,
            address: _address,
            refreshHomePage: refreshHomePage,
          ),
          TransaksiScreen(),
          AkunScreen(),
          InfoScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 222, 18, 18),
        unselectedItemColor: Color.fromARGB(179, 0, 0, 0),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Position? currentPosition;
  final String? latitude;
  final String? longitude;
  final String address;
  final Function refreshHomePage;

  const HomeScreen({
    Key? key,
    required this.currentPosition,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.refreshHomePage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Profile Petugas',
              style: TextStyle(
                fontSize: 24,
                color: Colors.orange,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lokasi Saat Ini',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (currentPosition != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Lat: ${latitude ?? ''}'),
                Text('Lng: ${longitude ?? ''}'),
                SizedBox(height: 10),
                Text(
                  'Address: $address',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Center(
              child: CircularProgressIndicator(),
            ),
          SizedBox(height: 40),
          Text(
            'Data Petugas',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('ID Petugas: ${user['id_petugas']}'),
          SizedBox(height: 8),
          Text('Nama: ${user['nama']}'),
          SizedBox(height: 8),
          Text('Email: ${user['email']}'),
          SizedBox(height: 8),
          Text('Alamat: ${user['alamat']}'),
          SizedBox(height: 8),
          Text('Telepon: ${user['telp']}'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              ).then((value) {
                if (value != null && value) {
                  refreshHomePage();
                }
              });
            },
            child: Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['nama']);
    _addressController = TextEditingController(text: widget.user['alamat']);
    _phoneController = TextEditingController(text: widget.user['telp']);
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await Api.updatePetugas(
          widget.user['id_petugas'],
          _nameController.text,
          _addressController.text,
          _phoneController.text,
        );

        if (response['status'] == 'success') {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Alamat'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Telepon'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
