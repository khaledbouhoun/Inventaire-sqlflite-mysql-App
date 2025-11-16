import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/view/screen/login.dart';

Future<bool> alertExitApp() {
  Get.defaultDialog(
    backgroundColor: AppColor.background,
    title: "الخروج",
    titleStyle: const TextStyle(color: AppColor.redColor, fontWeight: FontWeight.bold),
    middleText: "هل تريد الخروج من التطبيق",
    middleTextStyle: const TextStyle(color: AppColor.redColor, fontWeight: FontWeight.bold, fontSize: 16),
    actions: [
      ElevatedButton(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              side: BorderSide(color: AppColor.redColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          backgroundColor: WidgetStateProperty.all(AppColor.white),
        ),
        onPressed: () {
          Get.offAll(() => Login());
        },
        child: const Text("لا", style: TextStyle(fontSize: 20, color: AppColor.redColor)),
      ),
      ElevatedButton(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              side: BorderSide(color: AppColor.redColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          backgroundColor: WidgetStateProperty.all(AppColor.redColor),
        ),
        onPressed: () {
          exit(0);
        },
        child: const Text("نعم", style: TextStyle(fontSize: 20, color: AppColor.white)),
      ),
    ],
  );
  return Future.value(true);
}
