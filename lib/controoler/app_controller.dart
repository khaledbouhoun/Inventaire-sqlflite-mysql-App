import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/data/model/articles_model.dart';
import 'package:flutter/material.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class AppController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late DBHelper dbHelper;
  RxBool isOnline = true.obs;
  bool _isUploading = false;
  final Crud crud = Get.find();
  final Dialogfun dialogfun = Get.find();

  @override
  void onInit() {
    super.onInit();
    _initDB();
    _initConnectivityListener();
  }

  Future<void> _initDB() async {
    dbHelper = DBHelper();
    await dbHelper.database;
    print("Database opened");
    await _syncPendingData();
  }

  void _initConnectivityListener() async {
    // التحقق عند فتح التطبيق
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(connectivityResult);

    // الاستماع للتغيرات
    _connectivity.onConnectivityChanged.listen((status) {
      _updateConnectivityStatus(status);
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> status) async {
    if (status.contains(ConnectivityResult.ethernet) ||
        status.contains(ConnectivityResult.wifi) ||
        status.contains(ConnectivityResult.mobile)) {
      isOnline.value = true;
    } else {
      isOnline.value = false;
      dialogfun.showSnackError("No Internet", "You are offline. Some features may be unavailable.");
    }

    if (!isOnline.value) {
      // إذا تحولت من Offline إلى Online
      await _syncPendingData();
    }
  }

  Future<void> _syncPendingData() async {
    if (_isUploading || !isOnline.value) return;
    _isUploading = true;
    await _syncPendingProducts();

    _isUploading = false;
  }

  Future<void> _syncPendingProducts() async {
    final pendingProducts = await dbHelper.getPendingProducts();
    int count = 0;
    if (pendingProducts.isEmpty) {
      print('No pending products to upload.');
      return;
    }

    for (var product in pendingProducts) {
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
    dialogfun.showSnackSuccess("Success", "Uploaded $count pending products.");
  }

  /// إدراج قائمة منتجات جديدة من السيرفر مع حفظ الموجودة مسبقًا
  // Future<void> syncProductsFromServer(List<Product> serverProducts) async {
  //   for (var product in serverProducts) {
  //     await dbHelper.;
  //   }
  // }
}
