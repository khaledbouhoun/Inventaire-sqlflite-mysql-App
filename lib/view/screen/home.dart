import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/model/user_model.dart';
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
            centerTitle: true,
            title: Text(
              '${controller.user?.usrPntgNom ?? ''} / ${controller.user?.usrLempNom ?? ''}',
              style: TextStyle(
                color: AppColor.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: Get.width * 0.042,
              ),
            ),
            backgroundColor: AppColor.background,
            toolbarHeight: 80,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: PopupMenuButton<String>(
              icon: Icon(Icons.menu, color: AppColor.primaryColor, size: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColor.background,
              elevation: 5,
              padding: EdgeInsets.symmetric(vertical: 5),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: AppColor.primaryColor),
                      SizedBox(width: 10),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColor.primaryColor),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'refresh') {
                  controller.onRefresh();
                } else if (value == 'logout') {
                  controller.onLogout();
                }
              },
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
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.primaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : // Show settings widget at the top
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              GotoWidget(
                                text: "Liste Inventaire",
                                onTap: controller.goToInventaireList,
                              ),
                              GotoWidget(
                                text: "Génération Code Qr",
                                onTap: controller.goToQrCodeSettings,
                              ),
                            ],
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
