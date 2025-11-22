import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/home_controller.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/data/model/exercice_model.dart';
import 'package:invontaire_local/data/model/dossei_model.dart';
import 'package:invontaire_local/data/model/inventaired.dart';
import 'package:invontaire_local/data/model/inventaireentete_model.dart';
import 'package:invontaire_local/data/model/settings_model.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/view/screen/home.dart';
import 'package:invontaire_local/view/screen/login.dart';

class DetailsController extends GetxController {
  // ========== Dependencies ==========
  final Crud crud = Crud();
  final HomeController homeController = Get.put(HomeController());
  final GlobalKey<FormState> formState = GlobalKey<FormState>();

  ScrollController scrollController = ScrollController();

  // ========== Data Models ==========
  // UserModel? user;
  DossierModel? dossier;
  ExerciceModel? exercice;
  InventaireEnteteModel? inventaire;
  BuySettings? buySettings;
  SellSettings? sellSettings;

  Rx<ArticlesModel?> selectedArticle = Rx<ArticlesModel?>(null);

  // ========== INVENTAIRD Lists ==========
  List<InventairedModel> inventaireDetaileList = <InventairedModel>[];

  // ========== Article Lists ==========
  List<ArticlesModel> articles = <ArticlesModel>[];
  List<ArticlesModel> filteredArticles = <ArticlesModel>[];
  String searchQuery = '';

  // ========== Text Controllers ==========
  String expression = '';
  final TextEditingController quantityController = TextEditingController();
  String quantityHideText = '';
  final TextEditingController longController = TextEditingController();
  final TextEditingController largController = TextEditingController();

  // ========== State Variables ==========
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  bool updateMethode = false;
  bool userupdateMethode = false;

  // ========== Initialization ==========
  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupListeners();
  }

  Future<void> _initializeData() async {
    try {
      // Get arguments from navigation
      final args = Get.arguments;
      if (args != null) {
        // user = homeController.user;
        dossier = homeController.dossier;
        exercice = homeController.exercice;
        inventaire = args['inventaire'];
        buySettings = homeController.buySettings;
        sellSettings = homeController.sellSettings;
      }

      // Load articles from home controller
      // articles = homeController.articles;
      filteredArticles = [];

      // _logInitialization();
    } catch (e) {
      _showErrorSnackbar('Failed to initialize: $e');
    }
  }

  void _setupListeners() {
    // Add listeners for auto-save or validation if needed
    quantityController.addListener(_onInputChanged);
    longController.addListener(_onInputChanged);
    largController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    // Optional: Add debounced validation or auto-calculation
    update();
  }

  void _logInitialization() {
    // debugPrint('📦 Details Controller Initialized');
    // debugPrint('👤 User: ${user?.u ?? 'N/A'}');
    // debugPrint('📁 Dossier: ${dossier?.dosnom ?? 'N/A'}');
    // debugPrint('📅 Exercice: ${exercice?.exenom ?? 'N/A'}');
    // debugPrint('📋 Inventory: #${inventaire?.ineno ?? 'N/A'}');
    // debugPrint('📦 Articles loaded: ${articles.length}');
  }

  // ========== Fetch INVENTAIRD  ==========
 

  // ========== Article Selection Functions ==========
  /// Select an article and prepare for data entry
  void selectArticle(ArticlesModel? article) {
    if (article == null) return;

    scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

    selectedArticle.value = article;
    if (inventaireDetaileList.where((e) => e.iNDART == article.artno).isEmpty) {
      updateMethode = false;
      quantityController.clear();
      longController.clear();
      largController.clear();
    } else {
      InventairedModel inventaireDetaileListFirst = inventaireDetaileList.firstWhere((e) => e.iNDART == article.artno);
      updateMethode = true;
      quantityHideText = inventaireDetaileListFirst.iNDQTEINV.toString();
      longController.text = inventaireDetaileListFirst.iNDLONG.toString();
      largController.text = inventaireDetaileListFirst.iNDLARG.toString();
    }

    update();
  }

  /// Clear the selected article and reset form
  void clearSelection() {
    selectedArticle.value = null;
    quantityController.clear();
    longController.clear();
    largController.clear();
    quantityHideText = '';
    searchQuery = '';
    filteredArticles = [];
    update();

    debugPrint('🔄 Article selection cleared');
  }

  // ========== Search Functions ==========

  /// Filter articles based on search query (real-time)
  void filterArticles(String query) {
    searchQuery = query.toLowerCase().trim();

    if (searchQuery.isEmpty) {
      filteredArticles = [];
      update();
      return;
    }

    // Perform multi-field search
    filteredArticles = articles.where((article) {
      return _matchesSearchQuery(article);
    }).toList();

    // Sort results by relevance (exact matches first)
    _sortSearchResults();

    update();
    debugPrint('🔍 Search: "$query" - Found ${filteredArticles.length} results');
  }

  bool _matchesSearchQuery(ArticlesModel article) {
    // Search in name (highest priority)
    if ((article.artnom?.toLowerCase().contains(searchQuery) ?? false)) {
      return true;
    }

    // Search in references
    if (_searchInReferences(article)) {
      return true;
    }

    // Search in barcodes
    if (_searchInBarcodes(article)) {
      return true;
    }

    // Search by artno
    if (article.artno?.toLowerCase().contains(searchQuery) ?? false) {
      return true;
    }

    return false;
  }

  bool _searchInReferences(ArticlesModel article) {
    final refs = [article.artref?.toLowerCase(), article.artref2?.toLowerCase(), article.artref3?.toLowerCase()];

    return refs.any((ref) => ref?.contains(searchQuery) ?? false);
  }

  bool _searchInBarcodes(ArticlesModel article) {
    final barcodes = [
      article.artcab?.toLowerCase(),
      article.artcab2?.toLowerCase(),
      article.artcab3?.toLowerCase(),
      article.artcab4?.toLowerCase(),
      article.artcab5?.toLowerCase(),
      article.artcab6?.toLowerCase(),
      article.artcab7?.toLowerCase(),
      article.artcab8?.toLowerCase(),
      article.artcab9?.toLowerCase(),
      article.artcab10?.toLowerCase(),
    ];

    return barcodes.any((code) => code?.contains(searchQuery) ?? false);
  }

  void _sortSearchResults() {
    filteredArticles.sort((a, b) {
      // Prioritize exact name matches
      final aNameMatch = a.artnom?.toLowerCase() == searchQuery;
      final bNameMatch = b.artnom?.toLowerCase() == searchQuery;

      if (aNameMatch && !bNameMatch) return -1;
      if (!aNameMatch && bNameMatch) return 1;

      // Then prioritize name starts with
      final aNameStarts = a.artnom?.toLowerCase().startsWith(searchQuery) ?? false;
      final bNameStarts = b.artnom?.toLowerCase().startsWith(searchQuery) ?? false;

      if (aNameStarts && !bNameStarts) return -1;
      if (!aNameStarts && bNameStarts) return 1;

      // Default alphabetical
      return (a.artnom ?? '').compareTo(b.artnom ?? '');
    });
  }

  /// Quick search by name (direct match)
  void searchByName(String query) {
    if (query.isEmpty) return;

    final found = articles.where((article) => article.artnom?.toLowerCase().contains(query.toLowerCase()) ?? false).toList();

    if (found.isNotEmpty) {
      selectArticle(found.first);
    } else {
      _showErrorSnackbar('No article found with name: $query');
    }
  }

  /// Quick search by reference (direct match)
  void searchByReference(String query) {
    if (query.isEmpty) return;

    final found = articles.where((article) {
      return (article.artref?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (article.artref2?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (article.artref3?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    if (found.isNotEmpty) {
      selectArticle(found.first);
    } else {
      _showErrorSnackbar('No article found with reference: $query');
    }
  }

  // ========== QR Code Scanner ==========

  /// Scan QR/Barcode and search for matching article
  Future<void> scanQRCode() async {
    // try {
    //   debugPrint('📷 Starting barcode scanner...');

    //   final options = _getScannerOptions();
    //   final result = await BarcodeScanner.scan(options: options);

    //   if (result.rawContent.isNotEmpty) {
    //     debugPrint('✅ Barcode scanned: ${result.rawContent}');
    //     _handleScannedBarcode(result.rawContent);
    //   } else {
    //     debugPrint('❌ Scan cancelled by user');
    //   }
    // } on PlatformException catch (e) {
    //   debugPrint('❌ Scanner error: ${e.code}');
    //   _handleScanError(e);
    // } catch (e) {
    //   debugPrint('❌ Unexpected scan error: $e');
    //   _showErrorSnackbar('Failed to scan barcode: $e');
    // }
  }

  // ScanOptions _getScannerOptions() {
  //   return ScanOptions(
  //     strings: {'cancel': 'Cancel', 'flash_on': 'Flash On', 'flash_off': 'Flash Off'},
  //     restrictFormat: [
  //       BarcodeFormat.qr,
  //       BarcodeFormat.code128,
  //       BarcodeFormat.code39,
  //       BarcodeFormat.ean13,
  //       BarcodeFormat.ean8,
  //       BarcodeFormat.code93,
  //     ],
  //     useCamera: -1, // Auto-select best camera
  //     android: const AndroidOptions(useAutoFocus: true, aspectTolerance: 0.5),
  //   );
  // }

  void _handleScannedBarcode(String barcode) {
    // Search in all barcode fields
    final found = articles.where((article) {
      return _articleMatchesBarcode(article, barcode);
    }).toList();

    if (found.isNotEmpty) {
      selectArticle(found.first);
      // _showSuccessSnackbar('✓ Article found: ${found.first.artnom}');
    } else {
      _showErrorSnackbar('No article found with barcode: $barcode');
      debugPrint('❌ No match for barcode: $barcode');
    }
  }

  bool _articleMatchesBarcode(ArticlesModel article, String barcode) {
    final barcodes = [
      article.artcab,
      article.artcab2,
      article.artcab3,
      article.artcab4,
      article.artcab5,
      article.artcab6,
      article.artcab7,
      article.artcab8,
      article.artcab9,
      article.artcab10,
    ];

    return barcodes.contains(barcode);
  }

  void _handleScanError(PlatformException e) {
    // if (e.code == BarcodeScanner.cameraAccessDenied) {
    //   _showErrorSnackbar('Camera permission denied. Please enable in settings.');
    // } else {
    //   _showErrorSnackbar('Scanner error: ${e.message ?? 'Unknown error'}');
    // }
  }

  // Future<void> printQrUSB(String dataToPrint) async {
  //   final printer = (
  //     vendorId: 0x0416, // CHANGE to your printer vendorId
  //     productId: 0x5011, // CHANGE to your printer productId
  //     baudRate: 9600,
  //   );

  //   // Load profile for ESC/POS printers
  //   final profile = await CapabilityProfile.load();
  //   final generator = Generator(PaperSize.mm58, profile);
  //   List<int> bytess = [];

  //   // Title
  //   bytess += generator.text(
  //     'QR Code',
  //     styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
  //   );

  //   // Print the QR
  //   bytess += generator.qrcode(dataToPrint, size: QRSize.Size6, align: PosAlign.center);

  //   // Extra space
  //   bytess += generator.feed(3);

  //   // Cut
  //   bytes += generator.cut();

  //   // Send to printer
  //   final res = await printer.call();
  //   if (res == PosPrintResult.success) {
  //     // await printer.printInfo(bytes);
  //     // await printer.disconnect();
  //   } else {
  //     print("Printer Error: $res");
  //   }
  // }

  // ========== Save Inventory Item ==========

  /// Validate and save the inventory item
  // Future<void> saveInventoryItem(bool replace) async {
  //   print("is TYPIN1j");

  //   // Validation
  //   print("is TYPING");
  //   if (!_validateBeforeSave()) return;

  //   isSaving.value = true;
  //   update();

  //   try {
  //     Map<String, dynamic> data = {};
  //     // Verify that the inventory header is not closed or removed

  //     bool inventaireStillOpen = false;
   

  //     if (!inventaireStillOpen) {
  //       print("⚠️ This inventory is closing...");
  //       _showInfoSnackbar("This inventory is closing");
  //       Get.offAll(() {
  //         Get.delete<HomeController>(); // حذف أي نسخة قديمة
  //         return Home();
  //       });

  //       return; // ⛔ مهم لإيقاف الدالة هنا
  //     }

  //     // ✅ الجرد مازال مفتوحاً، أكمل العملية هنا...

  //     if (updateMethode) {
  //       InventairedModel inventairedModel = inventaireDetaileList.firstWhere((element) => element.iNDART == selectedArticle.value!.artno);
  //       inventairedModel.iNDLONG = double.parse(longController.text);
  //       inventairedModel.iNDLARG = double.parse(largController.text);
  //       inventairedModel.iNDQTEINV = replace ? double.parse(quantityController.text) : _calculateQty(inventairedModel.iNDQTEINV!);
  //       inventairedModel.iNDQTEDIFF = inventairedModel.iNDQTEINV! - inventairedModel.iNDQTETHEOR!;
  //       inventairedModel.iNDMONTANT = replace
  //           ? _calculateMontant(double.parse(quantityController.text), inventairedModel.iNDPU!)
  //           : _calculateMontant(inventairedModel.iNDQTEINV!, inventairedModel.iNDPU!);
  //       inventairedModel.iNDQTEEXPR = replace ? quantityController.text : _calculateExpression(inventairedModel.iNDQTEEXPR!);
  //       inventairedModel.iNDMNTDIFF = inventairedModel.iNDMONTANT! - inventairedModel.iNDMNTTHEOR!;
  //       inventairedModel.iNDQTEINVG = _calculateqtySurface();
  //       data = inventairedModel.toJson();
  //       data.addAll({"updateMethode": updateMethode.toString()});
  //     } else {
  //       final item = _prepareInventorData();
  //       data = item.toJson();
  //       data.addAll({
  //         "updateMethode": updateMethode.toString(),
  //         "artpap": selectedArticle.value!.artpap,
  //         "artcompo2": selectedArticle.value!.artcompo2,
  //         "inetypecout": inventaire!.inetypecout,
  //         "PrmCalculPrixTTC": buySettings!.prmCalculPrixTTC,
  //         "PrmMajStk": sellSettings!.pRMMAJSTK,
  //         "PrmConsomMatPrem2": sellSettings!.pRMCONSOMMATPREM2,
  //         "PrmDepotDefautTourneeAB": sellSettings!.pRMDEPOTDEFAUTTOURNEEAB,
  //       });
  //     }
  //     print(data);

  //     final response = await crud.post(AppLink.saveInventaireDetailsUrl(dossier!.dosBdd!), data);

  //     if (response.statusCode == 201) {
  //       // // _showSuccessSnackbar('Inventory item saved successfully');
  //       // inventaireDetaileList.add(item);
  //       clearSelection();
  //       fetchInventaired();
  //     }
  //   } catch (e) {
  //     _onSaveError(e);
  //   } finally {
  //     isSaving.value = false;
  //     update();
  //   }
  // }

  bool _validateBeforeSave() {
    if (selectedArticle.value == null) {
      _showErrorSnackbar('Please select an article first');
      return false;
    }

    if (!_validateMeasurements()) {
      _showErrorSnackbar('Please enter valid numbers');
      return false;
    }

    return true;
  }

  bool _hasAnyMeasurement() {
    return quantityController.text.isNotEmpty || longController.text.isNotEmpty || largController.text.isNotEmpty;
  }

  bool _validateMeasurements() {
    // Check if entered values are valid numbers
    if (quantityController.text.isNotEmpty) {
      if (double.tryParse(quantityController.text) == null) return false;
    }
    if (longController.text.isNotEmpty) {
      if (double.tryParse(longController.text) == null) return false;
    }
    if (largController.text.isNotEmpty) {
      if (double.tryParse(largController.text) == null) return false;
    }
    return true;
  }

  int _calculateOrder() {
    if (inventaireDetaileList.isEmpty) return 1;
    final maxOrd = inventaireDetaileList.map((e) => e.iNDORD ?? 0).reduce((a, b) => a > b ? a : b);
    return maxOrd + 1;
  }

  double _calculateMontant(double quantity, double price) {
    return quantity * price;
  }

  double _calculateQty(double oldquantity) {
    if (double.parse(quantityController.text) > 0) {
      return oldquantity + double.parse(quantityController.text);
    } else {
      return oldquantity - double.parse(quantityController.text).abs();
    }
  }

  String _calculateExpression(String oldExpression) {
    if (double.parse(quantityController.text) > 0) {
      return "$oldExpression+${quantityController.text}";
    } else {
      return '$oldExpression${quantityController.text}';
    }
  }

  double _calculateqtySurface() {
    switch (selectedArticle.value!.artvtepar) {
      case 0:
        return 0.0;
      case 1:
        return (double.parse(longController.text) + double.parse(largController.text)) * 2;
      case 2:
        return double.parse(longController.text) * double.parse(largController.text);
      default:
        return double.parse(quantityController.text);
    }
  }

  InventairedModel _prepareInventorData() {
    return InventairedModel(
      iNDDATE: inventaire!.inedate,
      iNDNO: inventaire!.ineno,
      iNDART: selectedArticle.value!.artno,
      iNDORD: _calculateOrder(),
      iNDCOMPAR: selectedArticle.value!.artvtepar,
      iNDLONG: longController.text.isNotEmpty ? double.parse(longController.text) : 0.0,
      iNDLARG: largController.text.isNotEmpty ? double.parse(largController.text) : 0.0,
      // iNDCOLISAGE: selectedArticle.value!.artcolisage,
      // iNDCOLIS: selectedArticle.value!.artcolis,
      // iNDUNTCOL: selectedArticle.value!.artunitcolis,
      iNDCOLISAGE: selectedArticle.value!.artcolis,
      iNDCOLIS: 0.0,
      iNDUNTCOL: 0.0,
      iNDQTEINV: double.parse(quantityController.text),
      iNDQTETHEOR: 0,
      iNDQTEDIFF: 0, // qty difirence = qty inv - qty theor
      iNDPU: 1,
      // iNDPU: selectedArticle.value!.artprix,
      iNDMONTANT: _calculateMontant(double.parse(quantityController.text), 1),
      iNDQTEEXPR: quantityController.text,
      // iNDDEPOT: inventaire!.indepot,
      iNDDEPOT: inventaire!.inedepot,
      iNDMNTTHEOR: 0,
      iNDMNTDIFF: 0.0, // montant difirence = montant inv - montant theor
      iNDQTEINVG: _calculateqtySurface(), // qty inv in progress
      iNDUSER: "",
      iNDDH: DateTime.now(),
    );
  }

  void _onSaveSuccess() {
    _showSuccessSnackbar('✓ Inventory item saved successfully');
    clearSelection();
    // Optionally refresh data or navigate
    // homeController.fetchInventoryItems();
  }

  void _onSaveError(dynamic error) {
    debugPrint('❌ Save error: $error');
    _showErrorSnackbar('Failed to save: ${error.toString()}');
  }

  // ========== Snackbar Helpers ==========

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      '✓ Success',
      message,
      backgroundColor: Colors.green.shade400,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 400),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      '✗ Error',
      message,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_rounded, color: Colors.white, size: 28),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 400),
    );
  }

  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'ℹ Info',
      message,
      backgroundColor: Colors.blue.shade400,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.info_rounded, color: Colors.white, size: 28),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 400),
    );
  }

  void _showWarningSnackbar(String message) {
    Get.snackbar(
      '⚠ Warning',
      message,
      backgroundColor: Colors.orange.shade400,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 400),
    );
  }

  // ========== Utility Functions ==========

  /// Get article by barcode
  ArticlesModel? getArticleByBarcode(String barcode) {
    try {
      return articles.firstWhere((article) => _articleMatchesBarcode(article, barcode));
    } catch (e) {
      return null;
    }
  }

  /// Get article by reference
  ArticlesModel? getArticleByReference(String reference) {
    try {
      return articles.firstWhere((article) => article.artref == reference || article.artref2 == reference || article.artref3 == reference);
    } catch (e) {
      return null;
    }
  }

  // ========== Navigation ==========

  /// Logout user and navigate to login screen
  void onLogout() {
    debugPrint('👋 User logging out...');
    clearSelection();
    Get.offAll(() => Login());
  }

  /// Navigate back with confirmation if data is entered
  Future<bool> onWillPop() async {
    if (_hasUnsavedData()) {
      return await _showExitConfirmation();
    }
    return true;
  }

  bool _hasUnsavedData() {
    return selectedArticle.value != null && _hasAnyMeasurement();
  }

  Future<bool> _showExitConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved data. Are you sure you want to leave?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void showSearchDialog(BuildContext context, DetailsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColor.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            // Title
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
                    'Search Articles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) => controller.filterArticles(value),
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
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child: GetBuilder<DetailsController>(
                builder: (controller) {
                  if (controller.filteredArticles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: AppColor.primaryColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            controller.searchQuery.isEmpty ? 'Start typing to search' : 'No articles found',
                            style: TextStyle(fontSize: 16, color: AppColor.primaryColor.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: controller.filteredArticles.length,
                    itemBuilder: (context, index) {
                      final article = controller.filteredArticles[index];
                      return TweenAnimationBuilder(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: AppColor.primaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                controller.selectArticle(article);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.artnom ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColor.primaryColor),
                                    ),
                                    const SizedBox(height: 8),
                                    if (article.artref != null)
                                      Row(
                                        children: [
                                          Icon(Icons.tag, size: 14, color: AppColor.primaryColor.withOpacity(0.6)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ref: ${article.artref}',
                                            style: TextStyle(fontSize: 13, color: AppColor.primaryColor.withOpacity(0.7)),
                                          ),
                                        ],
                                      ),
                                    if (article.artcab != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.qr_code, size: 14, color: AppColor.primaryColor.withOpacity(0.6)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Code: ${article.artcab}',
                                            style: TextStyle(fontSize: 13, color: AppColor.primaryColor.withOpacity(0.7)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== Lifecycle ==========

  @override
  void onClose() {
    debugPrint('🔚 Details Controller disposed');

    // Dispose controllers
    quantityController.dispose();
    longController.dispose();
    largController.dispose();

    super.onClose();
  }
}
