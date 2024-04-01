import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const QRViewExample(),
              ),
            );
          },
          child: const Text('qrView'),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? json;

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (json != null) {
      Navigator.of(context).pop({'data': json});
    }
    return Scaffold(
      body: QRView(
        key: qrKey,
        onQRViewCreated: (QRViewController controller) {
          setState(() {
            this.controller = controller;
          });
          controller.scannedDataStream.listen((scanData) async {
            await controller.pauseCamera();
            final data = jsonDecode(scanData.code.toString());
            final dio = Dio(BaseOptions(
                baseUrl: 'https://swc.iitg.ac.in/test/khokhaEntry/api',
                headers: {'khokha-security-key': 'KhOkHa-DeV'}));
            Map reqBody = {};
            if (data['isExit']) {
              reqBody = {
                'outlookEmail': data['outlookEmail'],
                'name': data['name'],
                'rollNumber': data['rollNumber'],
                'hostel': data['hostel'],
                'program': data['program'],
                'branch': data['branch'],
                'phoneNumber': data['phoneNumber'],
                'roomNumber': data['roomNumber'],
                'destination': data['destination'],
                'connectionId': data['connectionId']
              };
            } else {
              reqBody = {
                'connectionId': data['connectionId'],
                'entryId': data['entryId']
              };
            }
            try {
              Response res;
              if (data['isExit']) {
                res = await dio.post('/newEntry', data: reqBody);
              } else {
                res = await dio.patch('/closeEntry/${reqBody['entryId']}',
                    data: reqBody);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.data['message'].toString())));

              print(res.data);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString()),
                  duration: const Duration(seconds: 20)));
            }
          });
        },
        overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 300),
        onPermissionSet: (ctrl, p) => (context, ctrl, p) {
          log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
          if (!p) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('no Permission')),
            );
          }
        },
      ),
    );
  }
}
