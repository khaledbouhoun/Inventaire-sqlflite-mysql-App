import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class QrController extends GetxController {
  late final HomeController _homeController = Get.find<HomeController>();
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
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
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

    products.assignAll(_homeController.products);

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
    debounce(searchQuery, (_) => performOptimizedSearch(), time: const Duration(milliseconds: 200));
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
      prod.prdQr = "${prod.prdNo} / ${prod.prdNom}";

      await _appController.dbHelper.insertGestQrAndProductInTransaction(prod, _homeController.user!.usrNo!, _homeController.user!.usrLemp!);

      _updateProductInLists(prod);

      await Future.delayed(const Duration(milliseconds: 500));
      selectedProduct.value = null;

      if (_appController.isOnline.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _appController.syncPendingData();
        });
      }
    } catch (e) {
      print("Error generating QR: $e");
      _dialogfun.showSnackError("Error", "Failed to generate QR: $e");
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

  // Selection control
  void selectProduct(Product product) {
    selectedProduct.value = product;
  }

  void clearSelection() {
    selectedProduct.value = null;
  }
}
