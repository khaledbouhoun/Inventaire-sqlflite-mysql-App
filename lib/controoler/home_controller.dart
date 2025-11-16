import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/login_controller.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:invontaire_local/data/model/exercice_model.dart';
import 'package:invontaire_local/data/model/dossei_model.dart';
import 'package:invontaire_local/data/model/inventaireentete_model.dart';
import 'package:invontaire_local/data/model/settings_model.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/view/screen/details.dart';
import 'package:invontaire_local/view/screen/login.dart';
import 'package:invontaire_local/view/screen/qrpage.dart';

class HomeController extends GetxController {
  final Crud crud = Crud();
  final AppLink appLink = Get.find<AppLink>();
  // final LoginController loginController = Get.put(LoginController());
  List<InventaireEnteteModel> inventaireentetelist = <InventaireEnteteModel>[];
  RxBool isLoading = false.obs;
  RxBool isLoadingArticles = false.obs;
  RxBool loadingInventaireId = false.obs;

  User? user1;
  UserModel? user;
  DossierModel? dossier;
  ExerciceModel? exercice;

  List<Product> products = <Product>[];

  BuySettings buySettings = BuySettings();
  SellSettings sellSettings = SellSettings();

  @override
  void onInit() {
    super.onInit();
    print("Home controller initializing ...");

    user = UserModel(userId: '', userLogin: '', userPass: '');
    dossier = DossierModel(dosNo: '', dosNom: '');
    exercice = ExerciceModel(eXECLOS: 1, eXEDATEDEB: DateTime.now(), eXEDATEFIN: DateTime.now(), eXENO: 1);

    if (user == null) {
      print("Error: Missing  Use is null.");
    }
    if (dossier == null) {
      print("Error: Missing  Dosseie is null.");
    }
    if (exercice == null) {
      print("Error: Missing  exceric is null.");
    }

    print("user = ${user!.userLogin ?? 'N/A'} dossie = ${dossier!.dosBdd ?? 'N/A'} exercice = ${exercice!.eXEDATEDEB!.year ?? 'N/A'} ");

    onRefresh();
  }

  Future<void> fetchArticles() async {
    try {
      isLoadingArticles.value = true;
      await Future.delayed(const Duration(seconds: 2));
      final response = await crud.get(AppLink.products);
      print('response : $response');

      if (response.statusCode == 200) {
        products = (response.body as List).map((e) => Product.fromJson(e)).toList();
        print('✅ Loaded ${products.length} products');
      } else {
        throw Exception('Failed to load articles');
      }
    } catch (e) {
      // Handle errors
    } finally {
      isLoadingArticles.value = false;
      update();
    }
  }

  Future<void> onRefresh() async {
    print("refreching ... user : ${user!.userLogin} dossie : ${dossier!.dosBdd} exercice : ${exercice!.eXEDATEDEB!.year} ");
    await fetchArticles();
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
