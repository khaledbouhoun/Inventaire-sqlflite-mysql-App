import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/fonctions/alertexitapp.dart';
import 'package:invontaire_local/view/widget/Goto_widget.dart';
import 'package:invontaire_local/view/widget/onlinewidget.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColor.background,
          appBar: AppBar(
            backgroundColor: AppColor.background,
            toolbarHeight: 80,
            leadingWidth: 200,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.onRefresh,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          border: Border.all(color: AppColor.primaryColor.withOpacity(0.3), width: 1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.refresh_outlined, color: AppColor.primaryColor, size: 24),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.onLogout,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          border: Border.all(color: AppColor.primaryColor.withOpacity(0.3), width: 1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.logout_outlined, color: AppColor.primaryColor, size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [OnlineWidget()],
          ),
          body: WillPopScope(
            onWillPop: alertExitApp,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: controller.onRefresh,
                color: AppColor.primaryColor,
                backgroundColor: AppColor.background,
                child: Obx(() {
                  return controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator(color: AppColor.primaryColor, strokeWidth: 2))
                      : // Show settings widget at the top
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [GotoWidget(text: "Génération Code Qr", onTap: controller.goToQrCodeSettings)],
                          ),
                        );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
