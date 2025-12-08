import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/model/product_model.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class QrController extends GetxController {
  late final HomeController homeController = Get.find<HomeController>();
  late final AppController _appController = Get.find<AppController>();
  late final Crud _crud = Get.find<Crud>();
  late final Dialogfun _dialogfun = Get.find<Dialogfun>();

  // ALL products from DB
  final RxList<Product> products = <Product>[].obs;

  // SEARCH + PAGINATION
  final RxList<Product> fullResults = <Product>[].obs; // all matched items
  final RxList<Product> visibleResults = <Product>[].obs; // paginated list

  final RxBool isLoading = false.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = "".obs;

  final ScrollController scrollController = ScrollController();

  final Rx<Product?> selectedProduct = Rx<Product?>(null);
  final RxString processingProductId = "".obs;

  final int pageSize = 500;
  int currentPage = 1;

  @override
  void onReady() {
    super.onReady();
    _loadProducts();
    _setupSearchDebounce();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
    print("--QR Controller ready");
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ----------------------------------------------------------
  // PAGINATION SYSTEM
  // ----------------------------------------------------------

  void resetPagination() {
    currentPage = 1;
    visibleResults.clear();
    fullResults.refresh();
    visibleResults.refresh();
  }

  void loadMore() {
    final end = currentPage * pageSize;

    if (end <= products.length) {
      visibleResults.assignAll(products.take(end).toList());
      currentPage++;
    }
  }

  // ----------------------------------------------------------
  // LOADING ALL PRODUCTS
  // ----------------------------------------------------------

  void _loadProducts() {
    isLoading.value = true;

    products.assignAll(homeController.products);

    // show full data before search
    fullResults.assignAll(products);

    resetPagination();
    loadMore(); // first 500 only

    isLoading.value = false;
  }

  // ----------------------------------------------------------
  // SEARCH SYSTEM (FULL DATABASE)
  // ----------------------------------------------------------

  void _setupSearchDebounce() {
    print("--Setting up search debounce");
    debounce(
      searchQuery,
      (_) => performOptimizedSearch(),
      time: const Duration(milliseconds: 200),
    );
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
  }

  void clearSearch() {
    searchQuery.value = "";
    searchController.clear();

    fullResults.assignAll(products);
    resetPagination();
    loadMore();
  }

  void performOptimizedSearch() {
    final query = searchQuery.value.trim();

    if (query.isEmpty) {
      fullResults.assignAll(products);
      resetPagination();
      loadMore();
      return;
    }

    final q = query.toLowerCase();
    final parts = q.split(' ').where((p) => p.isNotEmpty).toList();

    // IMPORTANT: SEARCH ONLY IN products = ALL DATA
    final results = products.where((product) {
      final name = product.prdNom?.toLowerCase() ?? "";
      final code = product.prdNo?.toLowerCase() ?? "";
      final text = "$code $name";

      if (parts.length > 1) {
        return parts.every((word) => text.contains(word));
      } else {
        return name.contains(q) || code.contains(q);
      }
    }).toList();

    fullResults.assignAll(results);
    resetPagination();
    loadMore(); // show first 500 matching items
  }

  // bool qrExists(Product product) {
  //   print("qrExists : ${product.prdNo} are ${_homeController.gestQr.any((qr) => qr.gqrPrdNo == product.prdNo)}");
  //   return _homeController.gestQr.any((qr) => qr.gqrPrdNo == product.prdNo);
  // }

  // ----------------------------------------------------------
  // QR GENERATION + LOCAL SYNC
  // ----------------------------------------------------------

  Future<void> generateQrForProduct() async {
    final prod = selectedProduct.value;
    if (prod == null) return;
    if (prod.prdQr != null && prod.prdQr!.isNotEmpty) return;

    processingProductId.value = prod.prdNo ?? '';

    try {
      // String cleanName = prod.prdNom ?? "No Name";

      // if (prod.prdNom != null) {
      //   final qtyRegex = RegExp(
      //     r'/\s*Qte\s*[:=]?\s*(\d+)\s*$',
      //     caseSensitive: false,
      //   );
      //   final match = qtyRegex.firstMatch(prod.prdNom!);
      //   if (match != null) {
      //     cleanName = prod.prdNom!.replaceAll(qtyRegex, '').trim();
      //   }
      // }
      // print("cleanName : $cleanName");
      // prod.prdQr = "${prod.prdNo} / $cleanName";
      final Map<String, String> nameAndQty = _appController.removeQtyFromName(
        prod.prdNom ?? "",
      );
      prod.prdQr = "${prod.prdNo} / ${nameAndQty['cleanName']}";

      bool success = await _appController.dbHelper
          .insertGestQrAndProductInTransaction(
            prod,
            homeController.user!.usrNo!,
            homeController.user!.usrLemp!,
          );
      if (success) {
        _showSuccessSnackbar("QR generation enregistré local success");
      } else {
        _showErrorSnackbar("Error QR generation local");
      }

      _updateProductInLists(prod);

      await Future.delayed(const Duration(milliseconds: 500));
      selectedProduct.value = null;

      if (success && _appController.isOnline.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _appController.syncPendingData();
        });
      }
    } catch (e) {
      print("Error generating QR: $e");
      _dialogfun.showSnackError("Error", "Error QR generation: $e");
    } finally {
      processingProductId.value = '';
    }
  }

  // update everywhere (products • fullResults • visibleResults)
  void _updateProductInLists(Product product) {
    int a = products.indexWhere((p) => p.prdNo == product.prdNo);
    if (a != -1) products[a] = product;

    int b = fullResults.indexWhere((p) => p.prdNo == product.prdNo);
    if (b != -1) fullResults[b] = product;

    // int c = visibleResults.indexWhere((p) => p.prdNo == product.prdNo);
    // if (c != -1) visibleResults[c] = product;

    products.refresh();
    fullResults.refresh();
    visibleResults.refresh();
  }

  void _showSuccessSnackbar(String message) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      print("Success: $message");
    }
  }

  void _showErrorSnackbar(String message) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      print("Error: $message");
    }
  }

  // Selection control
  void selectProduct(Product product) {
    selectedProduct.value = product;
  }

  void clearSelection() {
    selectedProduct.value = null;
  }
}
