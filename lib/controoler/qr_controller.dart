import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import your existing classes
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/data/model/gestqr.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class QrController extends GetxController {
  // Dependencies
  final Crud crud = Crud();
  final HomeController homeController = Get.find<HomeController>(); // Changed to Find to avoid re-putting
  final AppController appController = Get.find<AppController>();
  final Dialogfun dialogfun = Dialogfun();

  // UI Controllers
  final ScrollController scrollController = ScrollController();
  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  final TextEditingController searchController = TextEditingController();

  // Reactive State
  var products = <Product>[].obs;
  var filteredProducts = <Product>[].obs;
  var selectedProduct = Rx<Product?>(null);
  var searchQuery = ''.obs;

  // Animation & Status States
  var isLoading = true.obs; // Initial DB Load
  var isSyncing = false.obs; // Background Upload status

  // Holds the ID of the product currently being generated to show a specific loader
  var processingProductId = ''.obs;

  // Trigger for Success Animation (listenable in View)
  var successEventTrigger = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupListeners();
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // ================= Setup Listeners =================
  void _setupListeners() {
    // 1. Search Debounce: Waits 300ms after typing stops before filtering
    debounce(searchQuery, (query) {
      _performFilter(query.toString());
    }, time: const Duration(milliseconds: 300));

    // 2. Connectivity Listener (Uncommented and improved)
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      // Check if any result is not 'none'
      bool isConnected = !results.contains(ConnectivityResult.none);
      print('---Connectivity status changed: $isConnected');

      if (isConnected) {
        // Auto-sync when connection returns
        await uploadPendingData(silent: true);
      }
    });
  }

  Future<void> _initializeData() async {
    isLoading.value = true;

    // Using a Set for faster lookup during deduplication
    final existingIds = products.map((e) => e.prdNo).toSet();

    List<Product> newProducts = [];
    for (var p in homeController.products) {
      if (!existingIds.contains(p.prdNo)) {
        newProducts.add(p);
      }
    }

    products.addAll(newProducts);
    filteredProducts.assignAll(products); // Initial fill
    _sortProductsByQr(); // Keep unassigned ones at top usually

    isLoading.value = false;
  }

  // ================= UI Interactions =================

  void selectProduct(Product product) {
    selectedProduct.value = product;
    // Smooth scroll to top to see the selection details
    if (scrollController.hasClients) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuart);
    }
  }

  void clearSelection() {
    // Animate closing
    selectedProduct.value = null;
    searchController.clear();
    searchQuery.value = '';
  }

  void onSearchChanged(String val) {
    searchQuery.value = val; // Triggers the debounce listener
  }

  // ================= Filtering Logic =================
  void _performFilter(String query) {
    String cleanQuery = query.toLowerCase().trim();

    if (cleanQuery.isEmpty) {
      filteredProducts.assignAll(products);
      _sortProductsByQr(); // Keep unassigned ones at top usually
      return;
    }

    var results = products.where((product) {
      final nameMatch = product.prdNom?.toLowerCase().contains(cleanQuery) ?? false;
      final qrMatch = product.prdQr?.toLowerCase().contains(cleanQuery) ?? false;
      final noMatch = product.prdNo?.toLowerCase().contains(cleanQuery) ?? false;
      return nameMatch || qrMatch || noMatch;
    }).toList();

    // Smart Sorting
    results.sort((a, b) {
      // 1. Exact matches first
      final aExact = a.prdNom?.toLowerCase() == cleanQuery;
      final bExact = b.prdNom?.toLowerCase() == cleanQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // 2. Starts with query second
      final aStart = a.prdNom?.toLowerCase().startsWith(cleanQuery) ?? false;
      final bStart = b.prdNom?.toLowerCase().startsWith(cleanQuery) ?? false;
      if (aStart && !bStart) return -1;
      if (!aStart && bStart) return 1;

      return (a.prdNom ?? '').compareTo(b.prdNom ?? '');
    });

    filteredProducts.assignAll(results);
  }

  void _sortProductsByQr() {
    // Sorts items without QR codes to the top for easier access
    filteredProducts.sort((a, b) => a.prdNom!.toLowerCase().compareTo(b.prdNom!.toLowerCase()));
  }

  // ================= QR Generation & State Change =================
  Future<void> generateQrForProduct() async {
    final prod = selectedProduct.value;
    if (prod == null) return;
    if (prod.prdQr != null && prod.prdQr!.isNotEmpty) {
      dialogfun.showSnackInfo("Info", "QR already exists");
      return;
    }

    // 1. Set loading state for specific item
    processingProductId.value = prod.prdNo ?? '';

    try {
      // Artificial delay for animation effect (optional, remove in prod if needed)
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Modify Data
      prod.prdQr = "${prod.prdNo} / ${prod.prdNom}";

      // 3. DB Transaction
      await appController.dbHelper.insertGestQrAndProductInTransaction(prod, 1, 1);

      // 4. Update Lists locally (Optimistic UI update)
      int index = products.indexWhere((p) => p.prdNo == prod.prdNo);
      if (index != -1) {
        products[index] = prod;
        products.refresh(); // Triggers UI rebuild
      }

      // Update filtered list if needed
      int fIndex = filteredProducts.indexWhere((p) => p.prdNo == prod.prdNo);
      if (fIndex != -1) {
        filteredProducts[fIndex] = prod;
        filteredProducts.refresh();
      }

      // 5. Success Feedback
      HapticFeedback.mediumImpact(); // Vibrate
      successEventTrigger.value++; // Trigger View Animation

      // Close selection after a brief success pause
      await Future.delayed(const Duration(milliseconds: 500));
      selectedProduct.value = null;

      // 6. Attempt Sync
      if (appController.isOnline.value) {
        await uploadPendingData(silent: true);
      }
    } catch (e) {
      dialogfun.showSnackError("Error", "Failed to generate: $e");
    } finally {
      processingProductId.value = ''; // Stop loading
    }
  }

  // ================= Upload Logic (Refactored) =================
  Future<void> uploadPendingData({bool silent = false}) async {
    if (isSyncing.value) return;
    isSyncing.value = true;

    int successCount = 0;

    try {
      // 1. Upload Products
      final productPending = await appController.dbHelper.getPendingProducts();
      for (var product in productPending) {
        bool success = await _uploadSingleProduct(product);
        if (success) successCount++;
      }

      // 2. Upload GestQR
      final gestQrPending = await appController.dbHelper.getPendingGestQr();
      for (var item in gestQrPending) {
        bool success = await _uploadSingleGestQr(item);
        if (success) successCount++;
      }

      // 3. Refresh data from DB to ensure consistency
      products.assignAll(await appController.dbHelper.getAllProducts());
      _performFilter(searchQuery.value);

      if (!silent && successCount > 0) {
        dialogfun.showSnackSuccess("Sync Complete", "Uploaded $successCount items.");
      }
    } catch (e) {
      print("Global sync error: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  Future<bool> _uploadSingleProduct(Product product) async {
    if (product.prdNo == null) return false;
    try {
      final response = await crud.post("${AppLink.products}/${product.prdNo}", {'prd_qr': product.prdQr});
      if (response.statusCode == 201 || response.statusCode == 200) {
        await appController.dbHelper.markAsUploaded(product.prdNo!);
        return true;
      }
    } catch (e) {
      print("Err product upload: $e");
    }
    return false;
  }

  Future<bool> _uploadSingleGestQr(GestQr item) async {
    if (item.gqrPrdNo == null) return false;
    try {
      final response = await crud.post(AppLink.gestqr, item.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        await appController.dbHelper.markGestQrAsUploaded(item);
        return true;
      }
    } catch (e) {
      print("Err gestqr upload: $e");
    }
    return false;
  }
}
