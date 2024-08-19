import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: MyHome()));

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QRViewExample(isProd: true),
                ),
              );
            },
            child: const Text('Scan QR - PROD'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QRViewExample(isProd: false),
                ),
              );
            },
            child: const Text('Scan QR - DEV'),
          ),
        ]),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  final bool isProd;

  const QRViewExample({required this.isProd, super.key});

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
                baseUrl:
                    'https://swc.iitg.ac.in${widget.isProd ? '' : '/test'}/khokhaEntry/api/v1',
                headers: {
                  'khokha-security-key': String.fromEnvironment(
                      widget.isProd ? 'PROD_SECURITY_KEY' : 'DEV_SECURITY_KEY')
                }));
            Map reqBody = {};
            if (data['isExit']) {
              reqBody = {
                'userId': data['userId'],
                'connectionId': data['connectionId'],
                'destination': data['destination'],
                'checkOutGate': 'Faculty Gate',
              };
            } else {
              reqBody = {
                'connectionId': data['connectionId'],
                'checkInGate': 'Faculty Gate',
                'entryId': data['entryId'],
              };
            }
            try {
              late final Response res;
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
              const SnackBar(content: Text('No Permission')),
            );
          }
        },
      ),
    );
  }
}
