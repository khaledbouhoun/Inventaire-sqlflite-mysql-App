import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/intialbindings.dart';
import 'package:invontaire_local/view/screen/home.dart';
import 'package:invontaire_local/widget_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invontaire_local/view/screen/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => MyServices().init());
  runApp(MyApp());
}

class MyServices extends GetxService {
  late SharedPreferences sharedPreferences;
  Future<MyServices> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return this;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      initialBinding: InitialBindings(),
      home: Login(),
      // home: TicketScreen(),
    );
  }
}
