import 'package:flutter/material.dart';
import 'package:sertif/api.dart'; // Import API untuk logout (jika diperlukan)

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Info Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/');
          },
          child: Text('Logout'),
        ),
      ),
    );
  }
}
