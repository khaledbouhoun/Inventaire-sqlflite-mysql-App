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

  User? user1;
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
      if (!appController.isOnline.value) {
        return;
      }

      final responseproducts = await crud.get(AppLink.products);
      final responsegestqr = await crud.get('${AppLink.gestqr}?usr_no=1');
      print('response : $responseproducts');
      print('response : $responsegestqr');

      if (responseproducts.statusCode == 200) {
        products = (responseproducts.body as List).map((e) => Product.fromJson(e)).toList();
        for (var element in products) {
          print('${element.toJson()}\n');
        }
      }
      if (responsegestqr.statusCode == 200) {
        gestQr = (responsegestqr.body as List).map((e) => GestQr.fromJson(e)).toList();
        for (var element in gestQr) {
          print('${element.toJson()}\n');
        }
      }

      await appController.dbHelper.insertAllProducts(products);
      await appController.dbHelper.insertAllGestqr(gestQr);
    } catch (e) {
      print('Error fetching articles: $e');
      // Handle errors
    } finally {
      products = await appController.dbHelper.getAllProducts();
      gestQr = await appController.dbHelper.getallgestqr();
      print('✅ Loaded ${products.length} products from local database');
      update();
    }
  }

  Future<void> onRefresh() async {
    isLoading.value = true;
    await fetchArticles();
    isLoading.value = false;
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
    Get.to(() => QrPage());
  }

  void onLogout() {
    Get.offAll(() => const Login());
  }
}
