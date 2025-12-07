import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/model/invontaie_model.dart';
import 'package:invontaire_local/data/model/product_model.dart';
import 'package:invontaire_local/data/model/settings_model.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/view/screen/login.dart';
import 'package:invontaire_local/view/screen/qrviewExample.dart';
import 'package:math_expressions/math_expressions.dart';

class InvontaireController extends GetxController {
  // ========== Dependencies ==========
  final Crud crud = Crud();
  final HomeController homeController = Get.find<HomeController>();
  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final AppController appController = Get.find<AppController>();

  // ========== Data Models ==========
  BuySettings? buySettings;
  SellSettings? sellSettings;
  User? user;

  // ========== Observables ==========
  Rx<Product?> selectedArticle = Rx<Product?>(null);

  // ========== Lists ==========
  List<Invontaie> inventaireDetaileList = <Invontaie>[];
  List<Product?> products = <Product?>[];
  List<Product?> filteredProducts = <Product?>[];

  // ========== State Variables ==========
  String searchQuery = '';
  final TextEditingController quantityController = TextEditingController();
  String quantityHideText = '';

  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  // ========== Initialization ==========
  @override
  void onInit() {
    super.onInit();
    _initializeData();
    quantityController.addListener(update);
  }

  @override
  void onClose() {
    quantityController.removeListener(update);
    quantityController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    try {
      // Load data from HomeController
      user = homeController.user;
      buySettings = homeController.buySettings;
      sellSettings = homeController.sellSettings;
      products = homeController.products;
      filteredProducts = [];

      await fetchInvontaires();
    } catch (e) {
      _showErrorSnackbar('Failed to initialize: $e');
    }
  }

  // ========== Fetch Data ==========
  Future<void> fetchInvontaires() async {
    isLoading.value = true;
    update();
    try {
      // Always load from local database first
      inventaireDetaileList = await appController.dbHelper.getAllInvontaies();
      print("Loaded ${inventaireDetaileList.length} invontaires from local DB");

      // If online, sync with server
      if (appController.isOnline.value) {
        try {
          var response = await crud.get(AppLink.invontaies);
          if (response.statusCode == 200 || response.statusCode == 201) {
            var data = response.body;
            if (data is List) {
              List<Invontaie> serverInvontaires = data
                  .map((e) => Invontaie.fromJson(e))
                  .toList();

              await appController.dbHelper.insertAllInvontaie(
                serverInvontaires,
              );
              inventaireDetaileList = await appController.dbHelper
                  .getAllInvontaies();
              print(
                "Synced ${inventaireDetaileList.length} invontaires from server",
              );
            }
          }
        } catch (e) {
          print("Error syncing invontaires from server: $e");
          // Continue with local data
        }
      } else {
        print("Offline mode: Using local invontaires data");
      }
    } catch (e) {
      print("Error fetching invontaires: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // ========== Save / Update ==========
  Future<void> saveInvontaire() async {
    if (selectedArticle.value == null) return;
    if (!formState.currentState!.validate()) return;

    isSaving.value = true;
    update();

    try {
      Invontaie? existingInvontaie = inventaireDetaileList.firstWhereOrNull(
        (e) => e.invPrdNo == selectedArticle.value!.prdNo,
      );

      Invontaie invontaieToSave;

      if (existingInvontaie == null) {
        // Create new record
        invontaieToSave = Invontaie(
          invLempNo: user?.usrLemp,
          invPntgNo: user?.usrPntg,
          invUsrNo: user?.usrNo,
          invPrdNo: selectedArticle.value!.prdNo,
          invExp: quantityController.text,
          invDate: DateTime.now(),
          isUploaded: 0, // Mark as pending upload
        );
      } else {
        // Update existing record
        invontaieToSave = Invontaie(
          invNo: existingInvontaie.invNo,
          invLempNo: existingInvontaie.invLempNo,
          invPntgNo: existingInvontaie.invPntgNo,
          invUsrNo: existingInvontaie.invUsrNo,
          invPrdNo: existingInvontaie.invPrdNo,
          invExp: quantityController.text,
          invDate: existingInvontaie.invDate,
          isUploaded: 0, // Mark as pending upload
        );
      }

      // Save to local database first
      final localId = await appController.dbHelper.insertOrUpdateInvontaie(
        invontaieToSave,
      );

      if (localId != null) {
        _showSuccessSnackbar("Item saved locally");

        // If online, try to sync to server
        if (appController.isOnline.value) {
          try {
            Response response;
            if (existingInvontaie == null) {
              Map<String, dynamic> data = {
                "inv_lemp_no": user?.usrLemp,
                "inv_pntg_no": user?.usrPntg,
                "inv_usr_no": user?.usrNo,
                "inv_prd_no": selectedArticle.value!.prdNo,
                "inv_exp": quantityController.text,
                "inv_date": DateTime.now().toIso8601String(),
              };
              response = await crud.post(AppLink.invontaies, data);
            } else {
              Map<String, dynamic> data = {"inv_exp": quantityController.text};
              response = await crud.post(
                "${AppLink.invontaies}/${existingInvontaie.invNo}",
                data,
              );
            }

            if (response.statusCode == 200 || response.statusCode == 201) {
              // Mark as uploaded in local DB
              if (invontaieToSave.invNo != null) {
                await appController.dbHelper.markInvontaieAsUploaded(
                  invontaieToSave.invNo!,
                );
              }
              _showSuccessSnackbar("Item synced to server");
            }
          } catch (e) {
            print("Error syncing to server: $e");
            _showSuccessSnackbar("Item saved locally (will sync when online)");
          }
        } else {
          _showSuccessSnackbar("Item saved locally (will sync when online)");
        }

        clearSelection();
        await fetchInvontaires();
      } else {
        _showErrorSnackbar("Failed to save item locally");
      }
    } catch (e) {
      _showErrorSnackbar("Error saving: $e");
    } finally {
      isSaving.value = false;
      update();
    }
  }

  // ========== Article Selection ==========
  void selectArticle(Product? article) {
    if (article == null) return;

    selectedArticle.value = article;

    // Scroll to top to show selection
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Check if article exists in current list and populate with existing expression
    var existingItems = inventaireDetaileList.where(
      (e) => e.invPrdNo == article.prdNo,
    );

    if (existingItems.isEmpty) {
      quantityController.clear();
      quantityHideText = '';
    } else {
      Invontaie existingItem = existingItems.first;
      quantityController.text = existingItem.invExp ?? '';
    }

    update();
  }

  void clearSelection() {
    selectedArticle.value = null;
    quantityController.clear();
    quantityHideText = '';
    searchQuery = '';
    filteredProducts = [];
    update();
  }

  // ========== Search Logic ==========
  void filterProducts(String query) {
    searchQuery = query.toLowerCase().trim();

    if (searchQuery.isEmpty) {
      filteredProducts = [];
      update();
      return;
    }

    filteredProducts = products.where((article) {
      return _matchesSearchQuery(article);
    }).toList();

    _sortSearchResults();
    update();
  }

  bool _matchesSearchQuery(Product? article) {
    if (article == null) return false;

    final q = searchQuery;
    final parts = q.split(' ').where((p) => p.isNotEmpty).toList();

    final name = (article.prdNom ?? "").toLowerCase();
    final code = (article.prdNo ?? "").toLowerCase();
    final qr = (article.prdQr ?? "").toLowerCase();

    // Combine fields for searching
    final text = "$code $name $qr";

    if (parts.length > 1) {
      return parts.every((word) => text.contains(word));
    } else {
      return name.contains(q) || code.contains(q) || qr.contains(q);
    }
  }

  void _sortSearchResults() {
    filteredProducts.sort((a, b) {
      final aName = (a?.prdNom ?? "").toLowerCase();
      final bName = (b?.prdNom ?? "").toLowerCase();

      final aExact = aName == searchQuery;
      final bExact = bName == searchQuery;

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      return aName.compareTo(bName);
    });
  }

  // ========== QR Code ==========
  Future<void> scanQRCode() async {
    try {
      String? result = await Get.to(() => QRViewExample());
      if (result != null && result.isNotEmpty) {
        print("QR CODE: $result");
        Product? product = _searchInBarcodes(result);
        if (product != null) {
          selectArticle(product);
        } else {
          _showErrorSnackbar("Product not found for QR: $result");
        }
      }
    } catch (e) {
      print("QR Scan error: $e");
    }
  }

  Product? _searchInBarcodes(String result) {
    print("--searching in barcodes");
    try {
      return products.firstWhere((product) {
        print('${product?.prdQr} compre with {$result}');
        return product?.prdQr?.contains(result) ?? false;
      });
    } catch (e) {
      print("Search in barcodes error: $e");
      return null;
    }
  }

  // ========== Helpers ==========
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

  String safeCalculate(String expr) {
    try {
      // 1. إنشاء Parser (محلل)
      Parser p = Parser();

      // 2. تحليل التعبير إلى شجرة (Expression object)
      Expression exp = p.parse(expr);

      // 3. إنشاء ContextModel (للمتغيرات إن وجدت، هنا لا نحتاجها)
      ContextModel cm = ContextModel();

      // 4. تقييم التعبير. يتم تطبيق أسبقية العمليات تلقائيًا.
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      return eval.toStringAsFixed(2);
    } catch (e) {
      // معالجة الأخطاء (مثل تعبير غير صالح)
      print("Evaluation Error: $e");
      return '0.00';
    }
  }

  void onLogout() {
    Get.offAll(() => Login());
  }
}
