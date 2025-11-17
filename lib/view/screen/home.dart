import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/fonctions/alertexitapp.dart';
import 'package:invontaire_local/view/widget/Goto_widget.dart';

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
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,

            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
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
                padding: const EdgeInsets.only(right: 16, top: 8),
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
          body: WillPopScope(
            onWillPop: alertExitApp,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: controller.onRefresh,
                color: AppColor.primaryColor,
                backgroundColor: AppColor.background,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
                  child: Obx(() {
                    return controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator(color: AppColor.primaryColor, strokeWidth: 2))
                        : Column(
                            children: [
                              GotoWidget(text: "Gérer les inventaires", onTap: controller.goToInventaireList),
                              GotoWidget(text: "Paramètres de l'application", onTap: controller.goToQrCodeSettings),
                              // Constrain the ListView by wrapping the FutureBuilder in Expanded
                              Expanded(
                                child: FutureBuilder(
                                  future: DBHelper().getAll(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                                      return const Center(child: Text('No products available'));
                                    }

                                    final products = snapshot.data!;
                                    return ListView.builder(
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final p = products[index];
                                        return ListTile(
                                          title: Text(p['prd_nom'] + ' ' + (p['prd_no'] ?? '')),
                                          subtitle: Text('QR: ${p['prd_qr'] ?? ""} + ${p['uploaded'] ?? ""}'),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
