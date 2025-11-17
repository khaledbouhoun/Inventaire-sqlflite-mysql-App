import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Start
    Get.put(Crud());
    Get.put(AppLink());
    Get.put(Dialogfun());
    Get.put(AppController(), permanent: true); // دائم طوال فترة التطبيق
  }
}
