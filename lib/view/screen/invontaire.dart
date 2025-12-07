import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/invontaire_controller.dart';
import 'package:invontaire_local/view/widget/InventaireWidget.dart';

class Invontaire extends StatelessWidget {
  const Invontaire({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InvontaireController>(
      init: InvontaireController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColor.background,
          appBar: AppBar(
            backgroundColor: AppColor.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              '${controller.user?.usrPntgNom ?? ''} / ${controller.user?.usrLempNom ?? ''}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.primaryColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColor.primaryColor,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: Obx(() {
                return controller.isLoading.value
                    ? CircularProgressIndicator(
                        color: AppColor.primaryColor,
                        strokeWidth: 2,
                      )
                    : SingleChildScrollView(
                        controller: controller.scrollController,
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Visibility(
                              visible: controller.selectedArticle.value != null,
                              child: _buildSelectedArticleCard(controller),
                            ),
                            const SizedBox(height: 24),
                            controller.inventaireDetaileList.isEmpty
                                ? _buildEmptyState(context, controller)
                                : ListView.builder(
                                    itemBuilder: (_, index) {
                                      return InventaireWidget(
                                        item: controller
                                            .inventaireDetaileList[index],
                                      );
                                    },
                                    itemCount:
                                        controller.inventaireDetaileList.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                  ),
                          ],
                        ),
                      );
              }),
            ),
          ),

          resizeToAvoidBottomInset: false,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16.0,
            ),
            child: GetBuilder<InvontaireController>(
              builder: (controller) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'searchByName',
                      onPressed: () => showSearchDialog(context, controller),
                      backgroundColor: AppColor.primaryColor,
                      icon: const Icon(
                        Icons.person_search,
                        color: AppColor.white,
                      ),
                      label: const Text(
                        'Search by Name / Ref',
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'searchByQR',
                      onPressed: () => controller.scanQRCode(),
                      backgroundColor: AppColor.primaryColor,
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColor.white,
                      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        autofocus: true,
        controller: controller,
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          final RegExp decimalExpressionRegex = RegExp(
            r'^[+-]?(\d+(\.\d*)?|\.\d+)([+\-*](\d+(\.\d*)?|\.\d+))*$',
          );
          if (!decimalExpressionRegex.hasMatch(value)) {
            return 'Please enter a valid number or expression using +, -, and * (e.g., 123.5, 5*10-3, 45.2+56)';
          }
          return null;
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d+\-*.]')),
        ],
        onChanged: onChanged,
        cursorColor: AppColor.primaryColor,
        style: const TextStyle(
          color: AppColor.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelStyle: TextStyle(
            color: AppColor.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          hintStyle: TextStyle(
            color: const Color.fromARGB(255, 143, 175, 185),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          labelText: label,
          suffixText: suffix,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.primaryColor.withOpacity(0.15),
                  AppColor.primaryColor.withOpacity(0.08),
                ],
              ),
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
            borderSide: BorderSide(
              color: AppColor.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColor.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColor.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedArticleCard(InvontaireController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor,
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
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
                      controller.selectedArticle.value?.prdNom ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primaryColor,
                      ),
                    ),
                    if (controller.selectedArticle.value?.prdNo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Article N°: ${controller.selectedArticle.value?.prdNo}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor.primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.clearSelection(),
                icon: const Icon(Icons.close_rounded),
                color: AppColor.primaryColor,
                style: IconButton.styleFrom(
                  backgroundColor: AppColor.primaryColor.withOpacity(0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColor.primaryColor.withOpacity(0.1)),
          const SizedBox(height: 20),

          // Input fields
          const Text(
            'Quantity [ ex: 25*5-3+4... ] (supports +, -, *)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: controller.formState,
            child: _buildInputField(
              controller: controller.quantityController,
              label: 'Quantity',
              icon: Icons.inventory,
              suffix: controller
                  .safeCalculate(controller.quantityController.text)
                  .toString(),
              onChanged: (value) {
                controller.formState.currentState!.validate();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (controller.formState.currentState!.validate()) {
                  await controller.saveInvontaire();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: AppColor.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Obx(
                () => controller.isSaving.value
                    ? const CircularProgressIndicator(
                        color: AppColor.white,
                        strokeWidth: 2,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text(
                            'Save Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    InvontaireController controller,
  ) {
    return Container(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColor.primaryColor.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.primaryColor.withOpacity(0.1),
                  AppColor.primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColor.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'List is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColor.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void showSearchDialog(BuildContext context, InvontaireController controller) {
    // Keep existing search dialog logic
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColor.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColor.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Search products',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) => controller.filterProducts(value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, reference, or code...',
                    hintStyle: TextStyle(
                      color: AppColor.primaryColor.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColor.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColor.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GetBuilder<InvontaireController>(
                builder: (controller) {
                  if (controller.filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColor.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.searchQuery.isEmpty
                                ? 'Start typing to search'
                                : 'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColor.primaryColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: controller.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final article = controller.filteredProducts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColor.white,

                          border: Border.all(
                            color: AppColor.primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            controller.selectArticle(article);
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: AppColor.primaryColor.withOpacity(0.1),
                          highlightColor: AppColor.primaryColor.withOpacity(
                            0.05,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon Container
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColor.primaryColor.withOpacity(0.8),
                                        AppColor.primaryColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColor.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article?.prdNom ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primaryColor,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.tag,
                                            size: 14,
                                            color: AppColor.primaryColor
                                                .withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              article?.prdNo ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColor.primaryColor
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColor.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: AppColor.primaryColor.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
