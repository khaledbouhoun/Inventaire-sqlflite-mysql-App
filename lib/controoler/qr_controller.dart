import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/data/model/articles_model.dart';

class QrController extends GetxController {
  final Crud crud = Crud();
  final HomeController homeController = Get.put(HomeController());
  final GlobalKey<FormState> formState = GlobalKey<FormState>();

  ScrollController scrollController = ScrollController();

  Rx<Product?> selectedproduct = Rx<Product?>(null);
  RxList<Product> products = <Product>[].obs;
  RxList<Product> filteredproducts = <Product>[].obs;
  String searchQuery = '';

  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  bool updateMethode = false;

  @override
  void onInit() {
    super.onInit();
    _initializeData();

    // مراقبة اتصال الإنترنت
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        uploadPendingData();
      }
    });
  }

  Future<void> _initializeData() async {
    isLoading.value = true;

    // جلب البيانات من SQLite أولاً
    final dbProducts = await DBHelper().getAllProducts();
    products.value = dbProducts;
    filteredproducts.clear();

    // إضافة المنتجات من homeController (إذا تريد دمجها مع SQLite)
    for (var p in homeController.products) {
      if (!products.any((e) => e.prdNo == p.prdNo)) {
        products.add(p);
      }
    }

    isLoading.value = false;
  }

  // ========== Product Selection ==========
  void selectproduct(Product? product) {
    if (product == null) return;
    scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    selectedproduct.value = product;
    update();
  }

  void clearSelection() {
    selectedproduct.value = null;
    searchQuery = '';
    filteredproducts.clear();
    update();
  }

  // ========== Search & Sort ==========
  void filterproducts(String query) {
    searchQuery = query.toLowerCase().trim();

    if (searchQuery.isEmpty) {
      filteredproducts.clear();
      update();
      return;
    }

    filteredproducts.value = products.where(_matchesSearchQuery).toList();

    _sortSearchResults();
    _sortProductsByQr();
    update();
  }

  bool _matchesSearchQuery(Product product) {
    final nameMatch = product.prdNom?.toLowerCase().contains(searchQuery) ?? false;
    final qrMatch = product.prdQr?.toLowerCase().contains(searchQuery) ?? false;
    final noMatch = product.prdNo?.toLowerCase().contains(searchQuery) ?? false;
    return nameMatch || qrMatch || noMatch;
  }

  void _sortSearchResults() {
    filteredproducts.sort((a, b) {
      final aExact = a.prdNom?.toLowerCase() == searchQuery;
      final bExact = b.prdNom?.toLowerCase() == searchQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aStart = a.prdNom?.toLowerCase().startsWith(searchQuery) ?? false;
      final bStart = b.prdNom?.toLowerCase().startsWith(searchQuery) ?? false;
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

  // ========== QR Generation ==========
  void generateQrForProduct() async {
    if (selectedproduct.value == null) return;

    selectedproduct.value!.prdQr = "${selectedproduct.value!.prdNo} ${selectedproduct.value!.prdNom}";
    selectedproduct.refresh();

    // حفظ محليًا في SQLite
    await DBHelper().insertProduct(selectedproduct.value!);

    // تحديث القائمة محليًا
    final dbProducts = await DBHelper().getAllProducts();
    products.value = dbProducts;

    // رفع البيانات إذا الإنترنت متاح
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.none)) {
      uploadPendingData();
    }
  }

  // ========== Upload Pending Data ==========
  Future<void> uploadPendingData() async {
    final productPending = await DBHelper().getPendingProducts();
    for (var product in productPending) {
      try {
        final response = await crud.post(AppLink.products, {}); // ضع الرابط الصحيح
        if (response.statusCode == 201) {
          await DBHelper().markAsUploaded(product.prdNo!);
        }
      } catch (e) {
        print('Upload failed for ${product.prdNo}: $e');
      }
    }

    // تحديث المنتجات بعد رفعها
    final dbProducts = await DBHelper().getAllProducts();
    products.value = dbProducts;
  }
}
