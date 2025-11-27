import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class AppController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late DBHelper dbHelper;
  RxBool isOnline = true.obs;
  RxBool isUploading = false.obs;

  final Crud crud = Get.find();
  final Dialogfun dialogfun = Get.find();

  @override
  void onInit() {
    super.onInit();
    _initDB();
    _initConnectivityListener();
  }

  /// ------------------- Initialize Database -------------------
  Future<void> _initDB() async {
    dbHelper = DBHelper();
    await dbHelper.database;
    print("Database opened");

    // Defer sync until the widget tree is ready (context is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncPendingData();
    });
  }

  /// ------------------- Connectivity Listener -------------------
  void _initConnectivityListener() async {
    var status = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(status);

    _connectivity.onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> status) async {
    bool nowOnline =
        status.contains(ConnectivityResult.wifi) ||
        status.contains(ConnectivityResult.ethernet) ||
        status.contains(ConnectivityResult.mobile);

    if (isOnline.value != nowOnline) {
      isOnline.value = nowOnline;
      print('Connectivity changed: $nowOnline');

      if (nowOnline) {
        await syncPendingData();
      } else {
        print('Offline mode: sync paused.');
      }
    }
  }

  /// ------------------- Sync Pending Data -------------------
  Future<void> syncPendingData() async {
    if (isUploading.value || !isOnline.value) return;
    isUploading.value = true;

    try {
      int countProducts = await _syncPendingProducts();
      int countGestQr = await _syncPendingGestQr();

      // Only attempt to show snackbars if we have a valid context with Overlay
      // This check is safe because Dialogfun.showSnackSuccess now has internal validation
      if (countProducts > 0 || countGestQr > 0) {
        dialogfun.showSnackSuccess("Sync Complete", "Uploaded $countProducts products and $countGestQr gestQr records successfully.");
      } else {
        print('No pending data to upload.');
      }
    } catch (e) {
      print("Sync error: $e");
    } finally {
      isUploading.value = false;
    }
  }

  Future<int> _syncPendingProducts() async {
    final pendingProducts = await dbHelper.getPendingProducts();

    if (pendingProducts.isEmpty) {
      print('No pending products to upload.');
      return 0;
    }

    int successCount = 0;

    // Use batch upload if possible (for large datasets)
    for (var product in pendingProducts) {
      try {
        final prdNo = product.prdNo;
        if (prdNo == null || prdNo.isEmpty) continue;

        final response = await crud.post("${AppLink.products}/$prdNo", {'prd_qr': product.prdQr});

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Uploaded product ${product.prdNo} successfully.');
          await dbHelper.markAsUploaded(prdNo);
          successCount++;
        }
      } catch (e) {
        print('Failed to upload product ${product.prdNo}: $e');
      }
    }
    return successCount;
  }

  Future<int> _syncPendingGestQr() async {
    final pendingGestQr = await dbHelper.getPendingGestQr();

    if (pendingGestQr.isEmpty) {
      print('No pending gestQr to upload.');
      return 0;
    }
    int successCount = 0;
    for (var gestQr in pendingGestQr) {
      try {
        final response = await crud.post(AppLink.gestqr, {
          'gqr_lemp_no': gestQr.gqrLempNo,
          'gqr_usr_no': gestQr.gqrUsrNo,
          'gqr_prd_no': gestQr.gqrPrdNo,
          'gqr_no': gestQr.gqrNo,
          'gqr_date': gestQr.gqrDate == null ? DateTime.now().toIso8601String() : gestQr.gqrDate!.toIso8601String(),
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Uploaded gestQr ${gestQr.gqrNo} successfully.');
          await dbHelper.markGestQrAsUploaded(gestQr);
          successCount++;
        }
      } catch (e) {
        print('Failed to upload gestQr ${gestQr.gqrNo}: $e');
      }
    }
    return successCount;
  }

  // /// ------------------- Optional: Sync server products -------------------
  // Future<void> syncProductsFromServer(List<Product> serverProducts) async {
  //   for (var product in serverProducts) {
  //     try {
  //       await dbHelper.insertOrUpdateProduct(product); // you should implement this in DBHelper
  //     } catch (e) {
  //       print("Failed to save server product ${product.prdNo}: $e");
  //     }
  //   }
  // }
}
