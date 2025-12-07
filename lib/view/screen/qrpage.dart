import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/qr_controller.dart';
import 'package:invontaire_local/view/widget/onlinewidget.dart';
import 'package:invontaire_local/view/widget/productwidget.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:invontaire_local/data/model/product_model.dart';

class QrPage extends StatelessWidget {
  QrPage({super.key});

  // Make sure controller is created ONCE only (bindings recommended)
  final QrController controller = Get.put<QrController>(QrController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColor.background,
        elevation: 0,
        centerTitle: true,
        title: ListTile(
          title: Text(
            'QR Code Generator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColor.primaryColor,
            ),
          ),
          subtitle: Text(
            'L\'emplacement : ${controller.homeController.user!.usrLempNom!}',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColor.primaryColor,
          ),
        ),
        actions: const [MiniOnlineWidget()],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.products.isEmpty) {
          return _emptyState();
        }

        return Column(
          children: [
            // ----------------- SELECTED PRODUCT CARD -----------------
            Obx(
              () => controller.selectedProduct.value == null
                  ? const SizedBox()
                  : _selectedProductCard(controller),
            ),

            // ---------------------- PRODUCT LIST ----------------------
            Expanded(
              child: ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: controller.visibleResults.length,
                itemBuilder: (context, index) {
                  final item = controller.visibleResults[index];

                  return ProductWidget(
                    // qrExists:controller.qrExists(item),
                    item: item,
                    onTap: () {
                      controller.selectProduct(item);
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSearchModal(context),
        backgroundColor: AppColor.primaryColor,
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          "Chercher ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ----------------------- PRODUCT ITEM -----------------------
  Widget _productItem(
    Product item,
    QrController controller, {
    required VoidCallback onTap,
  }) {
    final hasQr = item.prdQr != null && item.prdQr!.isNotEmpty;
    final isProcessing = controller.processingProductId.value == item.prdNo;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ProductWidget(
        // qrExists: controller.qrExists(item),
        item: item,
        onTap: onTap,
        trailingWidget: isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                hasQr ? Icons.qr_code_2_rounded : Icons.add_circle_outline,
                color: hasQr ? Colors.green : AppColor.primaryColor,
              ),
      ),
    );
  }

  // --------------------- SELECTED PRODUCT CARD ---------------------
  Widget _selectedProductCard(QrController controller) {
    final item = controller.selectedProduct.value!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Close
          Row(
            children: [
              Expanded(
                child: Text(
                  item.prdNom ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.clearSelection,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text("Code: ${item.prdNo}"),

          const SizedBox(height: 20),

          // --- QR DISPLAY ---
          if ((item.prdQr ?? "").isNotEmpty)
            Center(
              child: QrImageView(
                data: item.prdQr!,
                size: 150,
                backgroundColor: Colors.white,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.processingProductId.value.isNotEmpty
                      ? null
                      : controller.generateQrForProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.processingProductId.value.isNotEmpty
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const Text(
                              "Generate QR",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

  // ---------------------- EMPTY STATE -----------------------
  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text(
          "La liste est vide",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  // ------------------- SEARCH MODAL -------------------
  void _openSearchModal(BuildContext context) {
    controller.searchController.clear();
    controller.onSearchChanged('');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColor.primaryColor,
                    ),
                    hintText: "Search products...",
                    filled: true,
                    fillColor: AppColor.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Search Results List
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.fullResults.length,
                    itemBuilder: (context, index) {
                      final product = controller.fullResults[index];
                      return _productItem(
                        product,
                        controller,
                        onTap: () {
                          controller.selectProduct(product);
                          Get.back();
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
