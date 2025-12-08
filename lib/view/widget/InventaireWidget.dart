import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/data/model/invontaie_model.dart';

class InventaireWidget extends StatelessWidget {
  final Invontaie item;

  const InventaireWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColor.primaryColor.withOpacity(.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Product Name
              Text(
                item.invPrdNom ?? "Product Name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              /// Product Code
              if (item.invPrdNo != null && item.invPrdNo!.isNotEmpty)
                Text(
                  '# ${item.invPrdNo!}',
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color.fromARGB(255, 34, 151, 187),
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 16),

              /// Quantity Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColor.primaryColor.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Quantité :",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          item.invQte!.toStringAsFixed(
                            item.invQte! % 1 == 0 ? 0 : 2,
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Pcs",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// Footer - Expression & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Expression
                  if (item.invExp != null && item.invExp!.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.orange.shade50,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                "Exp:",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.invExp!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  /// Date
                  if (item.invDate != null)
                    Text(
                      DateFormat("dd MMM | HH:mm").format(item.invDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
