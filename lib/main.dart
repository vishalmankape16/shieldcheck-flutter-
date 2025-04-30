import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'dart:convert';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Website Security Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SecurityCheckerScreen(),
    );
 }
}

class SecurityCheckerScreen extends StatefulWidget {
  const SecurityCheckerScreen({super.key});

  @override
  State<SecurityCheckerScreen> createState() => _SecurityCheckerScreenState();
}

class _SecurityCheckerScreenState extends State<SecurityCheckerScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _securityResults;
  String? _error;

  Future<void> _checkSecurity(String url) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _securityResults = null;
    });

    try {
      // Basic URL validation
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final response = await http.get(Uri.parse(url));

      // Sample security checks
      Map<String, dynamic> results = {
        'status_code': response.statusCode,
        'https': url.startsWith('https://'),
        'headers': {
          'content_security_policy': response.headers['content-security-policy'] ?? 'Not found',
          'x_frame_options': response.headers['x-frame-options'] ?? 'Not found',
          'x_content_type_options': response.headers['x-content-type-options'] ?? 'Not found',
          'strict_transport_security': response.headers['strict-transport-security'] ?? 'Not found',
        },
      };

      setState(() {
        _securityResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error checking website: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _openCameraAndScan() async {
    bool isBarcodeFound = false;


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileScanner(
          controller:  MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
          ),
          onDetect: (capture) {
            if(isBarcodeFound){
              return;
            }
            final List<Barcode> barcodes = capture.barcodes;

            for (final barcode in barcodes) {
              if (barcode.type == BarcodeType.url || barcode.type == BarcodeType.text) {
                setState(() {
                  _urlController.text = barcode.rawValue!;
                  isBarcodeFound = true;

                });
                Navigator.pop(context);

              }
              isBarcodeFound = true;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: const Text('Website Security Checker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:  Padding(
        padding: const EdgeInsets.all(16.0),
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter Website URL',
                hintText: 'example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: Row(
                  mainAxisSize:  MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _openCameraAndScan,
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (_urlController.text.isNotEmpty) _checkSecurity(_urlController.text);
                      },
                    ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _checkSecurity(value);
                 }
              },
            ),
            const  SizedBox(height: 20),
            if (_isLoading)
               Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                 child: Card(
                  color: Colors.red.shade100,
                  child:  Padding(
                    padding:  EdgeInsets.all(16.0),
                    child:  Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ),
              )
            else if (_securityResults != null)
              Expanded(
                 child: SingleChildScrollView(
                  child:  Card(
                    child:  Padding(
                      padding:  EdgeInsets.all(12.0),
                      child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResultItem('HTTPS', 
                            _securityResults!['https'] ? '✅ Enabled' : '❌ Not enabled',
                            _securityResults!['https'] ? Colors.green : Colors.red
                          ),
                          _buildResultItem('Status Code',
                            '${_securityResults!['status_code']}',
                            _securityResults!['status_code'] == 200 ? Colors.green : Colors.orange
                          ),
                          const Divider(),
                          const Text('Security Headers:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 10),
                          _buildHeaderItem('Content-Security-Policy', 
                            _securityResults!['headers']['content_security_policy']
                          ),
                          _buildHeaderItem('X-Frame-Options', 
                            _securityResults!['headers']['x_frame_options']
                          ),
                          _buildHeaderItem('X-Content-Type-Options', 
                            _securityResults!['headers']['x_content_type_options']
                          ),
                          _buildHeaderItem('Strict-Transport-Security', 
                            _securityResults!['headers']['strict_transport_security']
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

   Widget _buildResultItem(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:  Row(
        children: [
           Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

   Widget _buildHeaderItem(String header, String value) {
    return  Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            header,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(
              color: value == 'Not found' ? Colors.red : Colors.green,
            )
          ), 
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}