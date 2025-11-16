import 'package:flutter/material.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/data/model/inventaired.dart';

class InventairedWidget extends StatelessWidget {
  final InventairedModel item;
  final VoidCallback? onTap;

  const InventairedWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppColor.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColor.primaryColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and article number
                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children: [
                    _buildInfoChip(value: item.iNDARTNom ?? '', icon: Icons.inventory_sharp),
                    _buildInfoChip(value: item.iNDART ?? 'N/A', icon: Icons.numbers_outlined),
                  ],
                ),
                const SizedBox(height: 16),

                // Measurements section
                if ((item.iNDLONG != null || item.iNDLARG != null) && (item.iNDLONG != 0 || item.iNDLARG != 0)) ...[
                  const Text(
                    'Measurements',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.iNDLONG != null)
                        Expanded(
                          child: _buildMeasurementCard(icon: Icons.straighten, label: 'Length', value: '${item.iNDLONG}', unit: 'm'),
                        ),
                      if (item.iNDLONG != null && item.iNDLARG != null) const SizedBox(width: 8),
                      if (item.iNDLARG != null)
                        Expanded(
                          child: _buildMeasurementCard(icon: Icons.square_foot, label: 'Width', value: '${item.iNDLARG}', unit: 'm'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Quantity section
                Row(
                  children: [
                    Expanded(
                      child: _buildQuantityCard(
                        label: 'Inventory Qty',
                        value: item.iNDQTEINV ?? 0,
                        theoretical: item.iNDQTETHEOR ?? 0,
                        difference: item.iNDQTEDIFF ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Footer with additional info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Created at', style: TextStyle(fontSize: 12, color: AppColor.primaryColor)),
                    if (item.iNDDH != null)
                      Text(_formatDateTime(item.iNDDH!), style: TextStyle(fontSize: 12, color: AppColor.primaryColor)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColor.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            // 👈 make text flexible to respect available space
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.primaryColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard({required IconData icon, required String label, required String value, required String unit}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColor.primaryColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.primaryColor.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.primaryColor.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard({required String label, required double value, required double theoretical, required double difference}) {
    final bool hasDiscrepancy = difference != 0;
    final Color differenceColor = difference > 0
        ? Colors.green
        : difference < 0
        ? Colors.red
        : AppColor.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.primaryColor.withOpacity(0.7)),
              ),
              if (hasDiscrepancy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: differenceColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    difference > 0 ? '+$difference' : '$difference',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: differenceColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Counted', style: TextStyle(fontSize: 12, color: AppColor.primaryColor.withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text(
                      '$value',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColor.primaryColor.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expected', style: TextStyle(fontSize: 12, color: AppColor.primaryColor.withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text(
                      '$theoretical',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.primaryColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}   ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
