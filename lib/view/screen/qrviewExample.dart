import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrText;
  bool isScanning = true;
  bool hasScanned = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {});
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: FutureBuilder<bool?>(
                future: controller?.getFlashStatus(),
                builder: (context, snapshot) {
                  return Icon(
                    snapshot.data == true ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 20,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColor.primaryColor,
              borderRadius: 20,
              borderLength: 40,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.75,
            ),
          ),

          // Animated scanning line
          if (isScanning)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            top:
                                _animation.value *
                                MediaQuery.of(context).size.width *
                                0.75,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColor.primaryColor,
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primaryColor,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // Bottom instruction card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasScanned) ...[
                    // Success state
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QR Code Scanned!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      qrText ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.primaryColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    // Scanning state
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColor.primaryColor.withOpacity(0.1),
                            AppColor.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: AppColor.primaryColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Position QR code within frame',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The scanner will automatically detect and select the product',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.primaryColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (!hasScanned && scanData.code != null && scanData.code!.isNotEmpty) {
        setState(() {
          qrText = scanData.code;
          hasScanned = true;
          isScanning = false;
        });

        controller.pauseCamera();

        // Provide haptic feedback
        // HapticFeedback.mediumImpact();

        print("QR VALUE: ${scanData.code}");

        // Automatically return to previous page with result after a short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          Get.back(result: scanData.code);
        });
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }
}
