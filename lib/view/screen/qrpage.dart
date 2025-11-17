import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/qr_controller.dart';
import 'package:invontaire_local/view/widget/productwidget.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPage extends StatelessWidget {
  const QrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final QrController controller = Get.put(QrController());
    print("------ intitialize QrPage");
    print("------ products = ${controller.products.length}");

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
          icon: Icon(Icons.arrow_back_ios_new, color: AppColor.primaryColor),
        ),
      ),
      body: SafeArea(
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
                if (controller.selectedproduct.value != null) _buildSelectedproductCard(controller),
                ...controller.products.map((p) => ProductWidget(item: p, onTap: () => controller.selectproduct(p))),
              ],
            ),
          );
        }),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSearchModal(context, controller),
        backgroundColor: AppColor.primaryColor,
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  void _showSearchModal(BuildContext context, QrController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Obx(
        () => Container(
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
                  onChanged: controller.filterproducts,
                  decoration: InputDecoration(
                    hintText: 'Search by name, reference, or code...',
                    hintStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: AppColor.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppColor.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: controller.filteredproducts.isEmpty
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
                        itemCount: controller.filteredproducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.filteredproducts[index];
                          return ProductWidget(
                            item: product,
                            onTap: () {
                              controller.selectproduct(product);
                              Get.back();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
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

  Widget _buildSelectedproductCard(QrController controller) {
    final product = controller.selectedproduct.value;
    if (product == null) return const SizedBox();

    return Container(
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
          if (product.prdQr != null && product.prdQr!.isNotEmpty) ...[
            Center(
              child: QrImageView(data: product.prdQr!, size: 160, backgroundColor: Colors.white),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => controller.generateQrForProduct(),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text("Generate QR Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
