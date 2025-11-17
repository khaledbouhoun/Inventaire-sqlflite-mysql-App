import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:get/route_manager.dart';

class Dialogfun {
  void showErrorDialog(String title, String message, Function()? onTap) {
    _showModernDialog(Get.context!, onTap, title, message, DialogType.error);
  }

  void showSuccessDialog(String title, String message, Function()? onTap) {
    _showModernDialog(Get.context!, onTap, title, message, DialogType.success);
  }

  void showWarningDialog(String title, String message, Function()? onTap) {
    _showModernDialog(Get.context!, onTap, title, message, DialogType.warning);
  }

  void showInfoDialog(String title, String message, Function()? onTap) {
    _showModernDialog(Get.context!, onTap, title, message, DialogType.info);
  }

  void showSnackSuccess(String title, String message) {
    _showModernSnackbar(Get.context!, title, message, SnackType.success);
  }

  void showSnackError(String title, String message) {
    _showModernSnackbar(Get.context!, title, message, SnackType.error);
  }

  void showSnackWarning(String title, String message) {
    _showModernSnackbar(Get.context!, title, message, SnackType.warning);
  }

  void showSnackInfo(String title, String message) {
    _showModernSnackbar(Get.context!, title, message, SnackType.info);
  }

  Future _showModernSnackbar(BuildContext context, String title, String message, SnackType type) async {
    final config = _getSnackConfig(type);

    return Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: config.backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 800),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Icon(config.icon, color: Colors.white, size: 24),
      ),
      boxShadows: [BoxShadow(color: config.shadowColor, blurRadius: 20, offset: const Offset(0, 8), spreadRadius: 0)],
      borderColor: config.borderColor,
      borderWidth: 1,
      shouldIconPulse: true,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  Future _showModernDialog(BuildContext context, Function()? onTap, String title, String message, DialogType type) async {
    final config = _getDialogConfig(type);

    return await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey.shade50]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient and icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: config.gradient,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Icon(config.icon, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 20, height: 1.5, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 32),

                      // Modern button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: config.gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: config.shadowColor, blurRadius: 15, offset: const Offset(0, 8), spreadRadius: 0)],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).pop();
                              if (onTap != null) onTap();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "got_it".tr,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
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
      },
    );
  }

  DialogConfig _getDialogConfig(DialogType type) {
    switch (type) {
      case DialogType.success:
        return DialogConfig(
          icon: Icons.check_circle,
          gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF45A049)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          shadowColor: Color(0xFF4CAF50).withOpacity(0.3),
        );
      case DialogType.error:
        return DialogConfig(
          icon: Icons.error,
          gradient: LinearGradient(colors: [Color(0xFFE53E3E), Color(0xFFD53F8C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          shadowColor: Color(0xFFE53E3E).withOpacity(0.3),
        );
      case DialogType.warning:
        return DialogConfig(
          icon: Icons.warning,
          gradient: LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFF5722)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          shadowColor: Color(0xFFFF9800).withOpacity(0.3),
        );
      case DialogType.info:
        return DialogConfig(
          icon: Icons.info,
          gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          shadowColor: Color(0xFF2196F3).withOpacity(0.3),
        );
    }
  }

  SnackConfig _getSnackConfig(SnackType type) {
    switch (type) {
      case SnackType.success:
        return SnackConfig(
          icon: Icons.check_circle,
          backgroundColor: Color(0xFF4CAF50),
          borderColor: Color(0xFF45A049),
          shadowColor: Color(0xFF4CAF50).withOpacity(0.3),
        );
      case SnackType.error:
        return SnackConfig(
          icon: Icons.error,
          backgroundColor: Color(0xFFE53E3E),
          borderColor: Color(0xFFD53F8C),
          shadowColor: Color(0xFFE53E3E).withOpacity(0.3),
        );
      case SnackType.warning:
        return SnackConfig(
          icon: Icons.warning,
          backgroundColor: Color(0xFFFF9800),
          borderColor: Color(0xFFFF5722),
          shadowColor: Color(0xFFFF9800).withOpacity(0.3),
        );
      case SnackType.info:
        return SnackConfig(
          icon: Icons.info,
          backgroundColor: Color(0xFF2196F3),
          borderColor: Color(0xFF1976D2),
          shadowColor: Color(0xFF2196F3).withOpacity(0.3),
        );
    }
  }
}

enum DialogType { success, error, warning, info }

enum SnackType { success, error, warning, info }

class DialogConfig {
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;

  DialogConfig({required this.icon, required this.gradient, required this.shadowColor});
}

class SnackConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  SnackConfig({required this.icon, required this.backgroundColor, required this.borderColor, required this.shadowColor});
}
