import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/qr_controller.dart';
import 'package:invontaire_local/view/widget/onlinewidget.dart';
import 'package:invontaire_local/view/widget/productwidget.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Assuming these are the new/updated imports based on your app structure:
import 'package:invontaire_local/data/model/articles_model.dart';

class QrPage extends StatelessWidget {
  QrPage({super.key});

  // Use Get.put() for controllers already initialized in the binding or the previous screen.
  final QrController controller = Get.put(QrController());

  @override
  Widget build(BuildContext context) {
    print("------ intitialize QrPage");

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColor.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'QR Code Generator',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColor.primaryColor),
        ),
        actions: [MiniOnlineWidget()],
      ),
      body: Stack(
        // Use Stack to overlay success animation
        children: [
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.products.isEmpty) {
                return _buildEmptyState();
              }

              return SingleChildScrollView(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 1. Selected Product Card with Animation
                    Obx(() => _buildSelectedProductCard(controller)),

                    const SizedBox(height: 16),

                    // 2. Main Product List (using filteredProducts for better consistency)
                    // The onTap here is the default selection logic
                    ...controller.filteredProducts.map(
                      (p) => _buildProductListItem(p, controller, onTap: () => controller.selectProduct(p)),
                    ),

                    const SizedBox(height: 100), // Extra space for FAB clearance
                  ],
                ),
              );
            }),
          ),

          // 3. Global Sync Indicator (New)
          Obx(
            () => controller.isSyncing.value
                ? const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 80.0),
                      child: Chip(
                        label: Text("Syncing data...", style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 4. Success Animation Overlay
          // _buildSuccessOverlay(context, controller),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearchModal(context, controller),
        backgroundColor: AppColor.primaryColor,
        icon: const Icon(Icons.search, color: Colors.white),
        label: Obx(() => Text(controller.filteredProducts.length.toString(), style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  // --- BUILDERS & WIDGETS ---

  // Refactored Product List Item to accept a required onTap callback
  Widget _buildProductListItem(Product product, QrController controller, {required VoidCallback onTap}) {
    // Determine if this specific product is currently processing
    final isProcessing = controller.processingProductId.value == product.prdNo;
    final hasQr = product.prdQr != null && product.prdQr!.isNotEmpty;

    // Use an AnimatedContainer for subtle state changes (like border or elevation)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProcessing
              ? Colors.blue.shade300
              : hasQr
              ? Colors.green.shade400
              : Colors.transparent,
          width: isProcessing ? 2.5 : 1,
        ),
        boxShadow: isProcessing ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)] : null,
      ),
      child: ProductWidget(
        item: product,
        onTap: onTap, // Use the provided custom onTap action
        // Pass the processing state to the ProductWidget if it supports it
        trailingWidget: isProcessing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primaryColor))
            : Icon(
                hasQr ? Icons.qr_code_2_rounded : Icons.add_circle_outline,
                color: hasQr ? Colors.green : AppColor.primaryColor.withOpacity(0.7),
              ),
      ),
    );
  }

  // Refactored Selected Product Card to include animation
  Widget _buildSelectedProductCard(QrController controller) {
    final product = controller.selectedProduct.value; // Corrected to selectedProduct
    if (product == null) return const SizedBox();

    // Fade the card out slightly when generation is successful
    return AnimatedOpacity(
      opacity: controller.processingProductId.value.isNotEmpty ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.prdNom ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                      ),
                      if (product.prdNo != null)
                        Text('Product N°: ${product.prdNo}', style: TextStyle(fontSize: 14, color: AppColor.primaryColor.withOpacity(0.6))),
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

            // Generate/Display QR Section
            if (product.prdQr != null && product.prdQr!.isNotEmpty) ...[
              Center(
                child: QrImageView(data: product.prdQr!, size: 160, backgroundColor: Colors.white),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.processingProductId.value.isNotEmpty
                        ? null
                        : () => controller.generateQrForProduct(), // Disable when processing
                    icon: controller.processingProductId.value.isNotEmpty
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.qr_code_2_rounded),
                    label: Text(
                      controller.processingProductId.value.isNotEmpty ? "Generating..." : "Generate QR Code",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: AppColor.primaryColor.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text('La liste est vide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  // Search Modal
  void _showSearchModal(BuildContext context, QrController controller) {
    // Clear search on open to start fresh
    controller.searchController.clear();
    controller.onSearchChanged('');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
              decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.search, color: AppColor.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Search products',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                autofocus: true,
                controller: controller.searchController, // Use controller's TextEditingController
                onChanged: controller.onSearchChanged, // Corrected method name
                decoration: InputDecoration(
                  hintText: 'Search by name, reference, or code...',
                  hintStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: AppColor.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColor.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: Obx(
                    () => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColor.primaryColor),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.onSearchChanged('');
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(
                () => controller.filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: AppColor.primaryColor.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              controller.searchQuery.isEmpty ? 'Start typing to search' : 'No products found',
                              style: TextStyle(fontSize: 16, color: AppColor.primaryColor.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: controller.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.filteredProducts[index];

                          // Custom onTap logic for items in the search modal
                          return _buildProductListItem(
                            product,
                            controller,
                            onTap: () {
                              // 1. Select the product (updates the main page)
                              controller.selectProduct(product);
                              // 2. Clear the search state
                              controller.searchController.clear();
                              controller.onSearchChanged('');
                              // 3. Close the modal
                              Get.back();
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
