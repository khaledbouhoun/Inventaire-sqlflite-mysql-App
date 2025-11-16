import 'package:flutter/material.dart';
import 'package:invontaire_local/constant/color.dart';

class GotoWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  const GotoWidget({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.primaryColor.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(fontFamily: "Nunito", fontWeight: FontWeight.w600, fontSize: 20, color: AppColor.black),
          ),
        ),
      ),
    );
  }
}
