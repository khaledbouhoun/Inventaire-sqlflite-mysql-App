import 'package:flutter/material.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/data/model/product_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProductWidget extends StatelessWidget {
  // final bool qrExists;
  final Product item;
  final VoidCallback? onTap;
  // New optional parameter for dynamic content/status indicator from controller
  final Widget? trailingWidget;

  const ProductWidget({
    super.key,
    // required this.qrExists,
    required this.item,
    this.onTap,
    this.trailingWidget, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    final bool qrExists = (item.prdQr != null && item.prdQr!.isNotEmpty);

    // Determine the color based on QR existence for visual feedback
    final Color statusColor = qrExists
        ? Colors.green.shade600
        : Colors.grey.shade500;

    // Extract quantity WITHOUT modifying the original prdNom
    String qtyText = "";
    String cleanName = item.prdNom ?? "No Name";

    if (item.prdNom != null) {
      final qtyRegex = RegExp(
        r'/\s*Qte\s*[:=]?\s*(\d+)\s*$',
        caseSensitive: false,
      );
      final match = qtyRegex.firstMatch(item.prdNom!);
      if (match != null) {
        qtyText = match.group(0) ?? "";
        // Extract clean name without modifying the original
        cleanName = item.prdNom!.replaceAll(qtyRegex, '').trim();
      }
    }

    return Card(
      color: AppColor.white,
      // Use slightly higher elevation for a modern look
      elevation: 0,
      shadowColor: statusColor,

      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16), // Slightly reduced padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. QR or Placeholder Icon
              Container(
                width: 70, // Fixed width
                height: 70, // Fixed height
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: qrExists
                    ? QrImageView(
                        data: item.prdQr!,
                        size: 60, // Smaller QR code within the container
                        backgroundColor: Colors.white,
                        version: QrVersions.auto,
                        errorStateBuilder: (cxt, err) => const Center(
                          child: Icon(Icons.error_outline, color: Colors.red),
                        ),
                      )
                    : Icon(
                        Icons
                            .tag, // Use a generic tag icon for products without QR
                        size: 35,
                        color: Colors.grey.shade400,
                      ),
              ),

              const SizedBox(width: 16),

              // 2. Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: cleanName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "  "),
                          TextSpan(
                            text: qtyText.isNotEmpty ? qtyText : "",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 42, 26),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ID
                    Text(
                      "ID: ${item.prdNo ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColor.primaryColor.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // QR Status
                    Row(
                      children: [
                        Icon(
                          qrExists
                              ? Icons.check_circle_rounded
                              : Icons.info_outline,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          qrExists ? "QR Code Exists" : "Needs QR Generation",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Dynamic Trailing Widget (from QrPage)
              // If the parent provided a widget (e.g., loading spinner), use it.
              // Otherwise, show the default arrow/indicator.
              Icon(
                qrExists ? Icons.qr_code_2_rounded : Icons.add_circle_outline,
                color: qrExists ? Colors.green : AppColor.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
