import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class QrController extends GetxController {
  final Crud crud = Crud();
  final HomeController homeController = Get.put(HomeController());
  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  Dialogfun dialogfun = Dialogfun();

  ScrollController scrollController = ScrollController();

  Rx<Product?> selectedproduct = Rx<Product?>(null);
  List<Product> products = <Product>[];
  List<Product> filteredproducts = <Product>[];
  RxString searchQuery = ''.obs;

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();

    // مراقبة اتصال الإنترنت
    Connectivity().onConnectivityChanged.listen((status) async {
      print('---Connectivity status: $status');
      if (!status.contains(ConnectivityResult.none)) {
        await uploadPendingData();
      }
    });
  }

  // @override
  // void onReady() {
  //   super.onReady();
  //   _initializeData();
  // }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    print("------ intitialize QrController");

    isLoading.value = true;

    // Load from SQLite
    // final dbProducts = await DBHelper().getAllProducts();

    // print("------ dbproducts = ${dbProducts.length}");
    // // Use assignAll to trigger RxList updates correctly
    // products.assignAll(dbProducts);

    // Merge with homeController products
    for (var p in homeController.products) {
      if (!products.any((e) => e.prdNo == p.prdNo)) {
        products.add(p);
      }
    }

    print("------ products = ${products.length}");
    isLoading.value = false;
    update();
  }

  // ================= Product Selection =================
  void selectproduct(Product product) {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    selectedproduct.value = product;
  }

  void clearSelection() {
    selectedproduct.value = null;
    searchQuery.value = '';
    filteredproducts.clear();
  }

  // ================= Search & Sort =================
  void filterproducts(String query) {
    searchQuery.value = query.toLowerCase().trim();

    if (searchQuery.value.isEmpty) {
      filteredproducts.clear();
      return;
    }

    filteredproducts = products.where(_matchesSearchQuery).toList();

    _sortSearchResults();
    _sortProductsByQr();
  }

  bool _matchesSearchQuery(Product product) {
    final nameMatch = product.prdNom?.toLowerCase().contains(searchQuery.value) ?? false;
    final qrMatch = product.prdQr?.toLowerCase().contains(searchQuery.value) ?? false;
    final noMatch = product.prdNo?.toLowerCase().contains(searchQuery.value) ?? false;
    return nameMatch || qrMatch || noMatch;
  }

  void _sortSearchResults() {
    filteredproducts.sort((a, b) {
      final aExact = a.prdNom?.toLowerCase() == searchQuery.value;
      final bExact = b.prdNom?.toLowerCase() == searchQuery.value;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aStart = a.prdNom?.toLowerCase().startsWith(searchQuery.value) ?? false;
      final bStart = b.prdNom?.toLowerCase().startsWith(searchQuery.value) ?? false;
      if (aStart && !bStart) return -1;
      if (!aStart && bStart) return 1;

      return (a.prdNom ?? '').compareTo(b.prdNom ?? '');
    });
  }

  void _sortProductsByQr() {
    filteredproducts.sort((a, b) {
      final aHasQr = a.prdQr?.isNotEmpty ?? false;
      final bHasQr = b.prdQr?.isNotEmpty ?? false;
      if (!aHasQr && bHasQr) return -1;
      if (aHasQr && !bHasQr) return 1;
      return 0;
    });
  }

  // ================= QR Generation =================
  Future<void> generateQrForProduct() async {
    if (selectedproduct.value == null) return;
    if (selectedproduct.value!.prdQr != null && selectedproduct.value!.prdQr!.isNotEmpty) return;

    selectedproduct.value!.prdQr = "${selectedproduct.value!.prdNo} ${selectedproduct.value!.prdNom}";
    selectedproduct.refresh();

    // Save locally
    await DBHelper().insertProduct(selectedproduct.value!);

    // Update list
    final dbProducts = await DBHelper().getAllProducts();
    products = dbProducts;

    // Upload if internet available
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.none)) {
      await uploadPendingData();
    }

    selectedproduct.value = null;
  }

  // ================= Upload Pending Data =================
  Future<void> uploadPendingData() async {
    print("------ uploadPendingData called");
    final productPending = await DBHelper().getPendingProducts();
    print("------ productPending length = ${productPending.length}");
    if (productPending.isEmpty) {
      print('No pending products to upload');
      return;
    }
    int count = 0;

    for (var product in productPending) {
      try {
        final prdNo = product.prdNo;
        if (prdNo == null || prdNo.isEmpty) {
          print('Skipping product with null/empty prdNo: ${product.prdNom}');
          continue;
        }

        final response = await crud.post("${AppLink.products}/$prdNo", {'prd_qr': product.prdQr});
        if (response.statusCode == 201) {
          int uploaded = await DBHelper().markAsUploaded(prdNo);
          count = count + uploaded;
        }
      } catch (e) {
        print('Upload failed for ${product.prdNo}: $e');
      }
    }

    // Refresh products
    final dbProducts = await DBHelper().getAllProducts();
    products = dbProducts;

    if (count > 0) {
      dialogfun.showSnackSuccess("Success", "Uploaded $count products successfully.");
    }
  }
}
