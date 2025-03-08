import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text(
          'مسح رمز QR',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              controller.toggleTorch();
            },
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () {
              controller.switchCamera();
            },
            icon: const Icon(Icons.flip_camera_android),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && _isScanning) {
                        _isScanning = false;
                        final String walletAddress =
                            barcodes.first.rawValue ?? '';

                        // Provide visual feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم مسح العنوان بنجاح'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 1),
                          ),
                        );

                        // Return the wallet address to the calling screen
                        Navigator.of(context).pop(walletAddress);
                      }
                    },
                  ),

                  // Scanner overlay for better UX
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.deepPurpleAccent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                  ),

                  // Instruction text below the scanner area
                  Positioned(
                    bottom: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'وجه الكاميرا نحو رمز QR لعنوان المحفظة',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
