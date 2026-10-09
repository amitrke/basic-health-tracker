import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen barcode scanner. Pops with the first barcode it reads.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null) return;
    _done = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Camera access is off. Enable it in system settings to '
                        'scan barcodes.'
                  : 'The camera is not available.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
