import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
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

/// Controller for managing inventory operations
class InvontaireController extends GetxController {
  // ==================== DEPENDENCIES ====================
  final Crud _crud = Crud();
  final HomeController _homeController = Get.find<HomeController>();
  final AppController _appController = Get.find<AppController>();

  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController quantityController = TextEditingController();

  // ==================== GETTERS ====================
  AppController get appController => _appController;
  User? get user => _user;
  BuySettings? get buySettings => _buySettings;
  SellSettings? get sellSettings => _sellSettings;

  // ==================== PRIVATE DATA ====================
  BuySettings? _buySettings;
  SellSettings? _sellSettings;
  User? _user;

  // ==================== OBSERVABLE STATE ====================
  final selectedArticle = Rx<Product?>(null);
  final inventaireDetaileList = <Invontaie>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  // ==================== SEARCH STATE ====================
  final filteredProducts = <Product?>[].obs;
  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  List<Product?> _allProducts = [];

  // ==================== LIFECYCLE ====================
  @override
  void onInit() {
    super.onInit();
    _initializeData();
    quantityController.addListener(_onQuantityChanged);
  }

  @override
  void onClose() {
    quantityController.removeListener(_onQuantityChanged);
    quantityController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================
  Future<void> _initializeData() async {
    try {
      _user = _homeController.user;
      _buySettings = _homeController.buySettings;
      _sellSettings = _homeController.sellSettings;
      _allProducts = _homeController.products;

      await fetchInvontaires();
    } catch (e) {
      _showErrorSnackbar('Failed to initialize: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    fetchInvontaires(); // Ensures fresh data when screen shows
  }

  void _onQuantityChanged() {
    if (formState.currentState != null) {
      formState.currentState!.validate();
    }
    update();
  }

  // ==================== DATA OPERATIONS ====================

  /// Fetches inventory data from local DB and syncs with server if online
  Future<void> fetchInvontaires() async {
    isLoading.value = true;

    try {
      // Load from local database
      await _loadLocalInventory();

      // Sync with server if online
      if (_appController.isOnline.value) {
        await _syncWithServer();
      } else {
        debugPrint("Offline mode: Using local inventory data");
      }

      // Sort, clean and enrich data
      _sortAndCleanInventory();
      _enrichInventoryWithProductNames();
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Enrich inventory items with product names from the products list
  void _enrichInventoryWithProductNames() {
    for (var item in inventaireDetaileList) {
      if (item.invPrdNo != null) {
        final product = _allProducts.firstWhereOrNull(
          (p) => p?.prdNo == item.invPrdNo,
        );
        if (product != null && product.prdNom != null) {
          item.invPrdNom = _appController.removeQtyFromName(
            product.prdNom!,
          )["cleanName"];
        }
      }
    }

    // Force final update
    inventaireDetaileList.refresh();
  }

  Future<void> _loadLocalInventory() async {
    inventaireDetaileList.value = await _appController.dbHelper
        .getAllInvontaies();
    debugPrint("Loaded ${inventaireDetaileList.length} items from local DB");

    // Force observable update
    inventaireDetaileList.refresh();
  }

  Future<void> _syncWithServer() async {
    try {
      final response = await _crud.get(
        '${AppLink.invontaies}?usr_no=${_user?.usrNo}'
        '&lemp_no=${_user?.usrLemp}&pntg_no=${_user?.usrPntg}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.body;

        if (data is List) {
          final serverInventory = data
              .map((e) => Invontaie.fromJson(e))
              .toList();

          await _appController.dbHelper.insertAllInvontaie(serverInventory);
          inventaireDetaileList.value = await _appController.dbHelper
              .getAllInvontaies();

          // Force observable update
          inventaireDetaileList.refresh();

          debugPrint(
            "Synced ${inventaireDetaileList.length} items from server",
          );
        }
      }
    } catch (e) {
      debugPrint("Error syncing with server: $e");
    }
  }

  void _sortAndCleanInventory() {
    // Sort by date descending
    inventaireDetaileList.sort((b, a) {
      if (a.invDate == null && b.invDate == null) return 0;
      if (a.invDate == null) return -1;
      if (b.invDate == null) return 1;
      return a.invDate!.compareTo(b.invDate!);
    });

    // Clean product names
    for (var item in inventaireDetaileList) {
      if (item.invPrdNom != null) {
        item.invPrdNom = _appController.removeQtyFromName(
          item.invPrdNom!,
        )["cleanName"];
      }
    }

    // Force observable update
    inventaireDetaileList.refresh();
  }

  /// Saves or updates inventory item
  Future<void> saveInvontaire() async {
    if (selectedArticle.value == null || !formState.currentState!.validate()) {
      return;
    }

    isSaving.value = true;

    try {
      final invontaire = _createInvontaireRecord();
      final localId = await _appController.dbHelper.insertOrUpdateInvontaie(
        invontaire,
      );

      if (localId != null) {
        debugPrint("Invontaie saved locally with id: $localId");

        // Update the local list immediately without fetching
        await _updateLocalList(localId);

        _showSuccessSnackbar("Item saved successfully");

        // Sync to server in background if online
        if (_appController.isOnline.value) {
          _appController.syncPendingInvontaies();
        }

        clearSelection();

        // Force UI update
        update();
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

  /// Updates the local inventory list with the saved item
  Future<void> _updateLocalList(int savedId) async {
    try {
      // Get the saved item from DB
      final savedItem = await _appController.dbHelper.getInvontaieById(savedId);

      if (savedItem == null) {
        debugPrint("Warning: Could not find saved item with id $savedId");
        return;
      }

      // Enrich with product name
      if (savedItem.invPrdNo != null) {
        final product = _allProducts.firstWhereOrNull(
          (p) => p?.prdNo == savedItem.invPrdNo,
        );
        if (product != null && product.prdNom != null) {
          savedItem.invPrdNom = _appController.removeQtyFromName(
            product.prdNom!,
          )["cleanName"];
        }
      }

      // Check if item already exists in list
      final existingIndex = inventaireDetaileList.indexWhere(
        (item) => item.invNo == savedId,
      );

      if (existingIndex != -1) {
        // Update existing item
        inventaireDetaileList[existingIndex] = savedItem;
        debugPrint("Updated existing item at index $existingIndex");
      } else {
        // Add new item at the beginning (most recent first)
        inventaireDetaileList.insert(0, savedItem);
        debugPrint("Added new item to list");
      }

      // Force observable update
      inventaireDetaileList.refresh();
    } catch (e) {
      debugPrint("Error updating local list: $e");
    }
  }

  Invontaie _createInvontaireRecord() {
    final existingItem = inventaireDetaileList.firstWhereOrNull(
      (e) => e.invPrdNo == selectedArticle.value!.prdNo,
    );

    if (existingItem == null) {
      // Create new record
      return Invontaie(
        invLempNo: _user?.usrLemp,
        invPntgNo: _user?.usrPntg,
        invUsrNo: _user?.usrNo,
        invPrdNo: selectedArticle.value!.prdNo,
        invExp: quantityController.text,
        invQte: calculate(quantityController.text),
        invDate: DateTime.now(),
        isUploaded: 0,
      );
    } else {
      // Update existing record
      return Invontaie(
        invNo: existingItem.invNo,
        invLempNo: existingItem.invLempNo,
        invPntgNo: existingItem.invPntgNo,
        invUsrNo: existingItem.invUsrNo,
        invPrdNo: existingItem.invPrdNo,
        invExp: quantityController.text,
        invQte: calculate(quantityController.text),
        invDate: existingItem.invDate,
        isUploaded: 0,
      );
    }
  }

  // ==================== ARTICLE SELECTION ====================

  void selectArticle(Product? article) {
    if (article == null) return;

    // Clean product name
    article.prdNom = _appController.removeQtyFromName(
      article.prdNom!,
    )['cleanName'];

    selectedArticle.value = article;
    _scrollToTop();
    _loadExistingQuantity(article);
  }

  void _scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _loadExistingQuantity(Product article) {
    final existingItem = inventaireDetaileList.firstWhereOrNull(
      (e) => e.invPrdNo == article.prdNo,
    );

    if (existingItem != null) {
      quantityController.text = existingItem.invExp ?? '';
    } else {
      quantityController.clear();
    }
  }

  void clearSelection() {
    selectedArticle.value = null;
    quantityController.clear();
    _searchQuery.value = '';
    filteredProducts.clear();
  }

  // ==================== SEARCH FUNCTIONALITY ====================

  void filterProducts(String query) {
    _searchQuery.value = query.toLowerCase().trim();

    if (_searchQuery.value.isEmpty) {
      filteredProducts.clear();
      return;
    }

    filteredProducts.value = _allProducts
        .where(_matchesSearchQuery)
        .map(_createCleanProduct)
        .toList();

    _sortSearchResults();
  }

  bool _matchesSearchQuery(Product? product) {
    if (product == null) return false;

    final query = _searchQuery.value;
    final parts = query.split(' ').where((p) => p.isNotEmpty).toList();

    final name = (product.prdNom ?? "").toLowerCase();
    final code = (product.prdNo ?? "").toLowerCase();
    final qr = (product.prdQr ?? "").toLowerCase();
    final combinedText = "$code $name $qr";

    if (parts.length > 1) {
      return parts.every((word) => combinedText.contains(word));
    }

    return name.contains(query) || code.contains(query) || qr.contains(query);
  }

  Product _createCleanProduct(Product? p) {
    return Product(
      prdNo: p!.prdNo,
      prdNom: p.prdNom != null
          ? _appController.removeQtyFromName(p.prdNom!)["cleanName"]
          : p.prdNom,
      prdQr: p.prdQr,
    );
  }

  void _sortSearchResults() {
    filteredProducts.sort((a, b) {
      final aName = (a?.prdNom ?? "").toLowerCase();
      final bName = (b?.prdNom ?? "").toLowerCase();

      // Exact matches first
      final aExact = aName == _searchQuery.value;
      final bExact = bName == _searchQuery.value;

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      return aName.compareTo(bName);
    });
  }

  // ==================== QR CODE SCANNING ====================

  Future<void> scanQRCode() async {
    try {
      final result = await Get.to<String>(() => QRViewExample());

      if (result != null && result.isNotEmpty) {
        debugPrint("QR CODE: $result");

        final product = _findProductByQR(result);
        if (product != null) {
          selectArticle(product);
        } else {
          _showErrorSnackbar("Product not found for QR: $result");
        }
      }
    } catch (e) {
      debugPrint("QR Scan error: $e");
    }
  }

  Product? _findProductByQR(String qr) {
    final qrCode = qr.split('/')[0].trim();
    return _allProducts.firstWhereOrNull((product) => product?.prdNo == qrCode);
  }

  // ==================== UTILITIES ====================

  double calculate(String expr) {
    if (expr.isEmpty) return 0.0;

    try {
      final parser = Parser();
      final expression = parser.parse(expr);
      final contextModel = ContextModel();
      return expression.evaluate(EvaluationType.REAL, contextModel);
    } catch (e) {
      debugPrint("Calculation error: $e");
      return 0.0;
    }
  }

  String formatNumber(double number) {
    return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
  }

  void onLogout() {
    Get.offAll(() => Login());
  }

  // ==================== UI FEEDBACK ====================

  void _showSuccessSnackbar(String message) {
    if (Get.context == null) {
      debugPrint("Success: $message");
      return;
    }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (Get.context == null) {
      debugPrint("Error: $message");
      return;
    }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
