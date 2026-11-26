import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/invontaire_controller.dart';
import 'package:invontaire_local/data/model/product_model.dart';
import 'package:invontaire_local/view/widget/InventaireWidget.dart';
import 'package:invontaire_local/view/widget/onlinewidget.dart';

class Invontaire extends GetView<InvontaireController> {
  const Invontaire({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColor.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: Get.height * 0.1,
      centerTitle: true,
      title: Text(
        '${controller.user?.usrLempNom ?? ''} / ${controller.user?.usrPntgNom ?? ''}',
        style: TextStyle(
          fontSize: Get.width * 0.045,
          fontWeight: FontWeight.bold,
          color: AppColor.primaryColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(Icons.arrow_back_ios_new, color: AppColor.primaryColor),
      ),
      actions: [
        MiniOnlineWidget(count: controller.appController.countInvontaies),
      ],
    );
  }

  // ==================== BODY ====================

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColor.primaryColor,
            strokeWidth: 2,
          ),
        );
      }

      return SafeArea(
        child: SingleChildScrollView(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selected article card
              Obx(() {
                if (controller.selectedArticle.value != null) {
                  return _SelectedArticleCard(controller: controller);
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 24),

              // Inventory list or empty state
              Obx(() {
                if (controller.inventaireDetaileList.isEmpty) {
                  return const _EmptyState();
                }

                return _InventoryList(items: controller.inventaireDetaileList);
              }),
            ],
          ),
        ),
      );
    });
  }

  // ==================== BOTTOM BAR ====================

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16.0,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton.extended(
              heroTag: 'searchByName',
              onPressed: () => _showSearchDialog(context),
              backgroundColor: AppColor.primaryColor,
              icon: const Icon(Icons.search, color: AppColor.white),
              label: const Text(
                'Code / Désignation',
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            FloatingActionButton(
              heroTag: 'searchByQR',
              onPressed: controller.scanQRCode,
              backgroundColor: AppColor.primaryColor,
              child: const Icon(Icons.qr_code_scanner, color: AppColor.white),
            ),
            FloatingActionButton.extended(
              heroTag: 'Qte',
              onPressed: () {},
              backgroundColor: AppColor.secendcolor,
              label: Text(
                controller.inventaireDetaileList.length.toString(),
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SEARCH DIALOG ====================

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchDialog(controller: controller),
    );
  }
}

// ==================== SELECTED ARTICLE CARD ====================

class _SelectedArticleCard extends StatelessWidget {
  final InvontaireController controller;

  const _SelectedArticleCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
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
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQuantityInput(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                  color: AppColor.black,
                ),
              ),
              if (controller.selectedArticle.value?.prdNo != null) ...[
                const SizedBox(height: 6),
                Text(
                  '# ${controller.selectedArticle.value?.prdNo}',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 34, 151, 187),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: controller.clearSelection,
          icon: const Icon(Icons.close_rounded),
          color: AppColor.primaryColor,
          style: IconButton.styleFrom(
            backgroundColor: AppColor.primaryColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityInput() {
    return Form(
      key: controller.formState,
      child: GetBuilder<InvontaireController>(
        builder: (_) => _QuantityInputField(controller: controller),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isSaving.value
              ? null
              : () async {
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
          child: controller.isSaving.value
              ? const CircularProgressIndicator(
                  color: AppColor.white,
                  strokeWidth: 2,
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ==================== QUANTITY INPUT FIELD ====================

class _QuantityInputField extends StatelessWidget {
  final InvontaireController controller;

  const _QuantityInputField({required this.controller});

  @override
  Widget build(BuildContext context) {
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
        controller: controller.quantityController,
        keyboardType: TextInputType.phone,
        validator: _validateQuantity,
        onChanged: (value) {
          controller.formState.currentState!.validate();
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d+\-*.]')),
        ],
        cursorColor: Colors.deepOrangeAccent,
        style: const TextStyle(
          color: Colors.deepOrangeAccent,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Quantité: [ ex: 25*5-3+4... ]',
          labelStyle: const TextStyle(
            color: AppColor.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          hintStyle: TextStyle(
            color: const Color.fromARGB(255, 143, 175, 185),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          suffixText: controller.formatNumber(
            controller.calculate(controller.quantityController.text),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrangeAccent.withOpacity(0.15),
                  Colors.deepOrangeAccent.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: Colors.deepOrangeAccent,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColor.primaryColor),
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

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une valeur';
    }

    final decimalExpressionRegex = RegExp(
      r'^[+-]?(\d+(\.\d*)?|\.\d+)([+\-*](\d+(\.\d*)?|\.\d+))*$',
    );

    if (!decimalExpressionRegex.hasMatch(value)) {
      return 'Veuillez entrer un nombre ou une expression valide utilisant +, -, et * '
          '(e.g., 123.5, 5*10-3, 45.2+56)';
    }

    return null;
  }
}

// ==================== INVENTORY LIST ====================

class _InventoryList extends StatelessWidget {
  final List items;

  const _InventoryList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        return InventaireWidget(item: items[index]);
      },
    );
  }
}

// ==================== EMPTY STATE ====================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ==================== SEARCH DIALOG ====================

class _SearchDialog extends StatelessWidget {
  final InvontaireController controller;

  const _SearchDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 16),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: const Text(
        'Recherche article',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColor.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
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
          onChanged: controller.filterProducts,
          decoration: InputDecoration(
            hintText: 'Code / Désignation',
            hintStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search, color: AppColor.primaryColor),
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
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.filteredProducts.isEmpty) {
        return _buildEmptySearchState();
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: controller.filteredProducts.length,
        itemBuilder: (context, index) {
          final article = controller.filteredProducts[index];
          return _SearchResultItem(
            article: article!,
            onTap: () {
              controller.selectArticle(article);
              Get.back();
            },
          );
        },
      );
    });
  }

  Widget _buildEmptySearchState() {
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
                ? 'Recherche article'
                : 'Aucun article trouvé',
            style: TextStyle(
              fontSize: 16,
              color: AppColor.primaryColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SEARCH RESULT ITEM ====================

class _SearchResultItem extends StatelessWidget {
  final Product article;
  final VoidCallback onTap;

  const _SearchResultItem({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColor.white,
        border: Border.all(
          color: AppColor.primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColor.primaryColor.withOpacity(0.1),
        highlightColor: AppColor.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildContent()),
              _buildArrowIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.prdNom ?? '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColor.black,
            letterSpacing: 0.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          article.prdNo ?? '',
          style: TextStyle(
            fontSize: 13,
            color: const Color.fromARGB(255, 34, 151, 187),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildArrowIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColor.primaryColor.withOpacity(0.7),
      ),
    );
  }
}
