import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/data/model/invontaie_model.dart';
import 'package:math_expressions/math_expressions.dart';
// Note: Assuming these imports exist in the original project structure
// import 'package:invontaire_local/constant/color.dart';
// import 'package:invontaire_local/data/model/invontaie_model.dart';

// Mocking external dependencies for completeness in this file

class InventaireWidget extends StatelessWidget {
  final Invontaie item;

  const InventaireWidget({super.key, required this.item});

  // ***************************************************************
  // * تحسين دالة الحساب باستخدام التعابير النمطية للتعامل مع الأرقام العشرية (Doubles)
  // * وهي مخصصة فقط للجمع والطرح (كما كان في الكود الأصلي).
  // ***************************************************************
  String safeCalculate(String expr) {
    try {
      // 1. إنشاء Parser (محلل)
      Parser p = Parser();

      // 2. تحليل التعبير إلى شجرة (Expression object)
      Expression exp = p.parse(expr);

      // 3. إنشاء ContextModel (للمتغيرات إن وجدت، هنا لا نحتاجها)
      ContextModel cm = ContextModel();

      // 4. تقييم التعبير. يتم تطبيق أسبقية العمليات تلقائيًا.
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      return eval.toStringAsFixed(2);
    } catch (e) {
      // معالجة الأخطاء (مثل تعبير غير صالح)
      print("Evaluation Error: $e");
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    // يجب التعامل مع حالة قيمة التعبير فارغة هنا لتجنب المشاكل
    final calculatedValue = item.invExp != null && item.invExp!.isNotEmpty
        ? safeCalculate(item.invExp!)
        : '0.00';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: AppColor.white,
      // تصميم أكثر عصرية باستخدام ظلال متعددة
      elevation: 8,
      shadowColor: AppColor.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColor.lightGrey.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: InkWell(
        // إضافة تأثير التفاعل عند الضغط
        onTap: () {
          // Add your navigation or detail viewing logic here
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with product name and number (more compact and stylish)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    value: item.invPrdNom ?? 'Product Name',
                    icon: Icons.inventory,
                  ),
                  _buildInfoChip(
                    value: item.invPrdNo ?? '',
                    icon: Icons.numbers_outlined,
                    isSecondary: true, // تغيير في تصميم الشريحة الثانية
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quantity Card (main focus)
              Row(
                children: [
                  Expanded(
                    child: _buildQuantityCard(
                      label: 'Total Calculated Quantity',
                      expression: item.invExp ?? 'N/A',
                      value: calculatedValue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Footer with additional info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Exp: [${item.invExp ?? ''}]',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (item.invDate != null)
                    Expanded(
                      flex: 1,
                      child: Text(
                        DateFormat(
                          'HH:mm  |  yyyy-MM-dd',
                        ).format(item.invDate ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
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

  // تحديث تصميم الشريحة (Chip)
  Widget _buildInfoChip({
    required String value,
    required IconData icon,
    bool isSecondary = false,
  }) {
    final color = isSecondary ? AppColor.accentColor : AppColor.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value.trim(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // تحديث تصميم بطاقة الكمية
  Widget _buildQuantityCard({
    required String label,
    required String value,
    required String expression,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        // استخدام تدرج لوني خفيف للخلفية
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor.withOpacity(0.05),
            AppColor.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.primaryColor.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32, // خط أكبر
                  fontWeight: FontWeight.w900,
                  color: AppColor.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'pieces', // إضافة وحدة (افتراضية)
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
