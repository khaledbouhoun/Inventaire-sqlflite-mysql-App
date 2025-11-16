import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/details_controller.dart';
import 'package:invontaire_local/view/widget/inventaired_widget.dart';
import 'package:invontaire_local/data/model/inventaired.dart';

class Details extends StatelessWidget {
  const Details({super.key});

  // final GlobalKey _listTargetKey = GlobalKey();
  // final GlobalKey _cardStartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DetailsController>(
      init: DetailsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColor.background,
          appBar: AppBar(
            backgroundColor: AppColor.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              'Inventory #${controller.inventaire?.ineno ?? ''}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
            ),
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_ios_new, color: AppColor.primaryColor),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: Obx(() {
                return controller.isLoading.value
                    ? CircularProgressIndicator(color: AppColor.primaryColor, strokeWidth: 2)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation), child: child),
                          );
                        },
                        child: SingleChildScrollView(
                          controller: controller.scrollController,
                          // key: ValueKey(controller.inventaireDetaileList.isEmpty ? 'empty' : 'content'),
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Visibility(visible: controller.selectedArticle.value != null, child: _buildSelectedArticleCard(controller)),
                              const SizedBox(height: 24),
                              controller.inventaireDetaileList.isEmpty
                                  ? _buildEmptyState(context, controller)
                                  : ListView.builder(
                                      // key: _listTargetKey,
                                      itemBuilder: (_, index) {
                                        return InventairedWidget(item: controller.inventaireDetaileList[index]);
                                      },
                                      itemCount: controller.inventaireDetaileList.length,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                    ),
                            ],
                          ),
                        ),
                      );
              }),
            ),
          ),

          resizeToAvoidBottomInset: false,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16.0),
            child: GetBuilder<DetailsController>(
              builder: (controller) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'searchByName',
                      onPressed: () => controller.showSearchDialog(context, controller),

                      backgroundColor: AppColor.primaryColor,
                      icon: const Icon(Icons.person_search, color: AppColor.white),
                      label: const Text(
                        'Sherch par Nom / Ref°',
                        style: TextStyle(color: AppColor.white, fontWeight: FontWeight.w400),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'searchByQR',
                      onPressed: () => controller.scanQRCode(),

                      backgroundColor: AppColor.primaryColor,
                      child: const Icon(Icons.qr_code_scanner, color: AppColor.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColor.primaryColor.withOpacity(0.1), AppColor.primaryColor.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColor.primaryColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: AppColor.primaryColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(color: AppColor.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String quantityHideText = '',
    required String label,
    required IconData icon,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        autofocus: true,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          return null;
        },
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[-+]?\d*\.?\d{0,2}$'))],
        cursorColor: AppColor.primaryColor,

        style: const TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          hint: Text(
            quantityHideText,
            style: TextStyle(color: const Color.fromARGB(255, 143, 175, 185), fontWeight: FontWeight.w600, fontSize: 16),
          ),
          labelText: label,
          suffixText: suffix,
          suffixStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.6), fontWeight: FontWeight.w500),
          labelStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.7), fontWeight: FontWeight.w500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColor.primaryColor.withOpacity(0.15), AppColor.primaryColor.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColor.primaryColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColor.primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColor.primaryColor.withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColor.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: AppColor.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSelectedArticleCard(DetailsController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 30),
      // key: _cardStartKey, // 👈 هنا
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColor.primaryColor, blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article header with close button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.selectedArticle.value?.artnom ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                    ),
                    if (controller.selectedArticle.value?.artno != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Article N°: ${controller.selectedArticle.value?.artno}',
                        style: TextStyle(fontSize: 14, color: AppColor.primaryColor.withOpacity(0.6)),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.clearSelection(),
                icon: const Icon(Icons.close_rounded),
                color: AppColor.primaryColor,
                style: IconButton.styleFrom(backgroundColor: AppColor.primaryColor.withOpacity(0.1)),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColor.primaryColor.withOpacity(0.1)),
          const SizedBox(height: 20),

          // References
          if ((controller.selectedArticle.value?.artref != null ||
                  controller.selectedArticle.value?.artref2 != null ||
                  controller.selectedArticle.value?.artref3 != null) &&
              (controller.selectedArticle.value!.artref!.isNotEmpty ||
                  controller.selectedArticle.value!.artref2!.isNotEmpty ||
                  controller.selectedArticle.value!.artref3!.isNotEmpty)) ...[
            const Text(
              'References',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.primaryColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (controller.selectedArticle.value?.artref != null && controller.selectedArticle.value!.artref!.isNotEmpty)
                  _buildInfoChip('Ref 1', controller.selectedArticle.value!.artref!, Icons.tag),
                if (controller.selectedArticle.value?.artref2 != null && controller.selectedArticle.value!.artref2!.isNotEmpty)
                  _buildInfoChip('Ref 2', controller.selectedArticle.value!.artref2!, Icons.tag),
                if (controller.selectedArticle.value?.artref3 != null && controller.selectedArticle.value!.artref3!.isNotEmpty)
                  _buildInfoChip('Ref 3', controller.selectedArticle.value!.artref3!, Icons.tag),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Barcode
          if (controller.selectedArticle.value?.artcab != null && controller.selectedArticle.value!.artcab!.isNotEmpty) ...[
            const Text(
              'Barcode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.primaryColor),
            ),
            const SizedBox(height: 12),
            _buildInfoChip('Code', controller.selectedArticle.value!.artcab!, Icons.qr_code_2),
            const SizedBox(height: 20),
          ],

          // Input fields
          const Text(
            'Measurements',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.primaryColor),
          ),
          const SizedBox(height: 12),
          Form(
            key: controller.formState,

            child: _buildInputField(
              controller: controller.quantityController,
              quantityHideText: controller.quantityHideText,
              label: 'Quantity',
              icon: Icons.inventory,
              suffix: 'units',
            ),
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: controller.selectedArticle.value != null && controller.selectedArticle.value!.artvtepar != 0,
            child: Row(
              children: [
                Expanded(
                  child: _buildInputField(controller: controller.longController, label: 'Long', icon: Icons.straighten, suffix: 'm'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(controller: controller.largController, label: 'Larg', icon: Icons.square_foot, suffix: 'm'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button with animation
          Builder(
            builder: (context) => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // _handleSaveWithAnimation(context, controller, startKey: _cardStartKey, endKey: _listTargetKey);
                  if (controller.formState.currentState!.validate()) {
                    if (controller.updateMethode) {
                      Get.defaultDialog(
                        backgroundColor: AppColor.white,
                        title: "Modifier ou Remplacer",
                        titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                        middleText: "Voulez-vous remplacer la valeur ou simplement la modifier ?",
                        middleTextStyle: TextStyle(fontSize: 16, color: AppColor.primaryColor.withOpacity(0.8)),
                        textConfirm: "Remplacer",
                        textCancel: "Modifier",
                        confirmTextColor: Colors.white,
                        cancelTextColor: AppColor.primaryColor,
                        buttonColor: AppColor.primaryColor,
                        barrierDismissible: true,
                        titlePadding: EdgeInsets.all(20),
                        radius: 12,
                        onConfirm: () async {
                          // await controller.saveInventoryItem(true);
                          // Get.back();
                          // controller.clearSelection();
                          // await controller.fetchInventaired();
                        },
                        onCancel: () async {
                          // await controller.saveInventoryItem(false);
                          // controller.clearSelection();
                          // await controller.fetchInventaired();
                        },
                      );
                    } else {
                      // await controller.saveInventoryItem(false);
                      // controller.clearSelection();
                      // await controller.fetchInventaired();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Obx(
                  () => controller.isSaving.value
                      ? const CircularProgressIndicator(color: AppColor.white, strokeWidth: 2)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Save Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DetailsController controller) {
    return Container(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primaryColor.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColor.primaryColor.withOpacity(0.1), AppColor.primaryColor.withOpacity(0.05)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: AppColor.primaryColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          const Text(
            'La liste est vide',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
          ),
        ],
      ),
    );
  }
}
