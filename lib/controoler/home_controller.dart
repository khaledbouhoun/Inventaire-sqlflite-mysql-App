import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/data/model/exercice_model.dart';
import 'package:invontaire_local/data/model/dossei_model.dart';
import 'package:invontaire_local/data/model/gestqr.dart';
import 'package:invontaire_local/data/model/inventaireentete_model.dart';
import 'package:invontaire_local/data/model/settings_model.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/view/screen/details.dart';
import 'package:invontaire_local/view/screen/login.dart';
import 'package:invontaire_local/view/screen/qrpage.dart';

class HomeController extends GetxController {
  final Crud crud = Crud();
  final AppLink appLink = Get.find<AppLink>();
  final AppController appController = Get.find<AppController>();
  // final LoginController loginController = Get.put(LoginController());
  List<InventaireEnteteModel> inventaireentetelist = <InventaireEnteteModel>[];
  RxBool isLoading = false.obs;
  RxBool isLoadingArticles = false.obs;
  RxBool loadingInventaireId = false.obs;

  User? user;
  DossierModel? dossier;
  ExerciceModel? exercice;

  List<Product> products = <Product>[];
  List<GestQr> gestQr = <GestQr>[];

  BuySettings buySettings = BuySettings();
  SellSettings sellSettings = SellSettings();

  @override
  void onInit() {
    super.onInit();
    print("Home controller initializing ...");
    final args = Get.arguments ?? <String, dynamic>{};

    user = args['user'] as User?;
    // dossier = args['dossier'] as DossierModel?;
    // exercice = args['exercice'] as ExerciceModel?;

    if (user == null) {
      print("Warning: Missing user (null). Returning to Login.");
      // If there's no user provided, send user back to login screen.
      // Use a microtask to avoid navigation during init synchronously.
      Future.microtask(() => Get.offAll(() => const Login()));
      return;
    }

    if (dossier == null) {
      print("Info: Dossier is null. Some features may be disabled until a dossier is selected.");
    }

    if (exercice == null) {
      print("Info: Exercice is null. Some features may be disabled until an exercice is selected.");
    }

    onRefresh();
  }

  Future<void> fetchArticles() async {
    try {
      if (!appController.isOnline.value) return;

      final lemp = user?.usrLemp;
      final usr = user?.usrNo;

      if (lemp == null || usr == null) {
        print("❌ User data missing! usrLemp or usrNo is null.");
        return;
      }

      print("🌍 Fetching products & gestqr...");
      print("🔗 Products URL : ${AppLink.products}");
      print("🔗 GestQR URL   : ${AppLink.gestqr}/$lemp/$usr");

      // Fetch both requests simultaneously (faster)
      final responses = await Future.wait([crud.get(AppLink.products), crud.get("${AppLink.gestqr}/$lemp/$usr")]);

      final responseProducts = responses[0];
      final responseGestqr = responses[1];

      // Parse products
      if (responseProducts.statusCode == 200 && responseProducts.body is List) {
        products = (responseProducts.body as List).map((e) => Product.fromJson(e)).toList();
      } else {
        products = [];
        print("⚠ No products received from API");
      }

      // Parse gestqr
      if (responseGestqr.statusCode == 200 && responseGestqr.body is List) {
        gestQr = (responseGestqr.body as List).map((e) => GestQr.fromJson(e)).toList();
      } else {
        gestQr = [];
        print("⚠ No GestQR received from API");
      }
    } catch (e) {
      print('❌ Error fetching articles: $e');
    } finally {
      // --- Save Gestqr locally ---
      await appController.dbHelper.insertAllGestqr(gestQr);
      gestQr = await appController.dbHelper.getallgestqr();

      // --- Filter products by gestqr ---
      final qrProductCodes = gestQr.map((qr) => qr.gqrPrdNo).toSet();

      // Keep all products, but clear QR if not in GestQR
      products = products.map((prod) {
        if (!qrProductCodes.contains(prod.prdNo)) {
          // product not found → clear QR
          prod.prdQr = "";
        }
        return prod;
      }).toList();

      // --- Save filtered products locally ---
      await appController.dbHelper.insertAllProducts(products);
      products = await appController.dbHelper.getAllProducts();

      print('✅ Loaded ${products.length} filtered products from local database');

      update();
    }
  }

  Future<void> onRefresh() async {
    if (appController.isOnline.value) {
      isLoading.value = true;
      await fetchArticles();
      isLoading.value = false;
    }
  }

  Future<void> onTapInventaire(InventaireEnteteModel inventaire) async {
    Get.to(() => Details(), arguments: {'inventaire': inventaire});
  }

  void goToInventaireList() {
    print("goToInventaireList");
    Get.to(() => Details());
  }

  void goToQrCodeSettings() {
    print("goToQrCodeSettings");
    try {
      Get.to(() => QrPage());
    } catch (e) {
      print(e);
    }
  }

  void onLogout() {
    Get.offAll(() => const Login());
  }
}
