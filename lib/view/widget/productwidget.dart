import 'package:flutter/material.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProductWidget extends StatelessWidget {
  final Product item;
  final VoidCallback? onTap;

  const ProductWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool qrExists = (item.prdQr != null && item.prdQr!.isNotEmpty);

    return Card(
      color: AppColor.white,
      elevation: 3,
      shadowColor: AppColor.primaryColor.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // QR
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: item.prdQr ?? "", size: 85, backgroundColor: Colors.white),
              ),

              const SizedBox(width: 16),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      item.prdNom ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                    ),

                    const SizedBox(height: 6),

                    // ID
                    Text(
                      "ID: ${item.prdNo ?? ''}",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.primaryColor.withOpacity(0.7)),
                    ),

                    const SizedBox(height: 8),

                    // QR Status
                    Row(
                      children: [
                        Icon(
                          qrExists ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
                          size: 18,
                          color: qrExists ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          qrExists ? "QR Generated" : "QR Not Generated",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: qrExists ? Colors.green : Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // BUTTON ARROW
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColor.primaryColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
