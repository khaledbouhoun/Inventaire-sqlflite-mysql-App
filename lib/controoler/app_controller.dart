import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/data/db_helper.dart';
import 'package:invontaire_local/fonctions/dialog.dart';

class AppController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late DBHelper dbHelper;
  RxBool isOnline = true.obs;
  RxBool isUploading = false.obs;
  RxInt countProducts = 0.obs;
  RxInt countGestQr = 0.obs;
  RxInt countInvontaies = 0.obs;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await syncPendingData();
      await syncPendingInvontaies();
    });
  }

  /// ------------------- Connectivity Listener -------------------
  void _initConnectivityListener() async {
    // Initial check
    var status = await _connectivity.checkConnectivity();
    final internet = await hasInternet();
    _updateConnectivityStatus(status, internet);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((status) async {
      final internet = await hasInternet();
      _updateConnectivityStatus(status, internet);
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> status, bool internet) async {
    // Check if connected to a network
    bool connectedToNetwork =
        status.contains(ConnectivityResult.wifi) ||
        status.contains(ConnectivityResult.ethernet) ||
        status.contains(ConnectivityResult.mobile);

    bool nowOnline = connectedToNetwork && internet;

    if (isOnline.value != nowOnline) {
      isOnline.value = nowOnline;
      print('Connectivity changed: $nowOnline');

      if (nowOnline) {
        // Only sync if truly online
        await syncPendingData();
        await syncPendingInvontaies();
      } else {
        print('Offline mode: sync paused.');
      }
    }
  }

  /// ------------------- Check Internet via HTTP -------------------
  Future<bool> hasInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://inventaire.zakawatt.dz/api/test'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 ? true : false;
    } catch (e) {
      print('No internet via HTTP: $e');
      return false;
    }
  }

  /// ------------------- Sync Pending Data -------------------
  Future<void> syncPendingData() async {
    if (isUploading.value || !isOnline.value || !await hasInternet()) return;
    isUploading.value = true;

    try {
      int countProducts = await _syncPendingProducts();
      int countGestQr = await _syncPendingGestQr();

      // Only attempt to show snackbars if we have a valid context with Overlay
      // This check is safe because Dialogfun.showSnackSuccess now has internal validation
      if (countProducts > 0 || countGestQr > 0) {
        dialogfun.showSnackSuccess(
          "Sync Complete",
          "Uploaded $countProducts products, $countGestQr gestQr successfully.",
        );
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
          await dbHelper.markProductAsUploaded(prdNo);
          successCount++;
        }
      } catch (e) {
        print('Failed to upload product ${product.prdNo}: $e');
      }
    }
    return successCount;
  }

  Future<int> _syncPendingGestQr() async {
    countGestQr.value = 0;
    final pendingGestQr = await dbHelper.getPendingGestQr();

    if (pendingGestQr.isEmpty) {
      print('No pending gestQr to upload.');
      return 0;
    }
    int successCount = 0;

    countGestQr.value = pendingGestQr.length;
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
          countGestQr.value -= await dbHelper.markGestQrAsUploaded(gestQr);
          successCount++;
        }
      } catch (e) {
        print('Failed to upload gestQr ${gestQr.gqrNo}: $e');
      }
    }
    return successCount;
  }

  Future<void> syncPendingInvontaies() async {
    if (isUploading.value || !isOnline.value || !await hasInternet()) return;
    isUploading.value = true;
    countInvontaies.value = 0;

    try {
      final pendingInvontaies = await dbHelper.getPendingInvontaies();
      countInvontaies.value = pendingInvontaies.length;

      if (pendingInvontaies.isEmpty) {
        print('No pending invontaies to upload.');
        return;
      }

      for (var invontaie in pendingInvontaies) {
        try {
          final response = await crud.post(AppLink.invontaies, {
            'inv_lemp_no': invontaie.invLempNo,
            'inv_pntg_no': invontaie.invPntgNo,
            'inv_usr_no': invontaie.invUsrNo,
            'inv_prd_no': invontaie.invPrdNo,
            'inv_exp': invontaie.invExp,
            'inv_qte': invontaie.invQte,
            'inv_date': invontaie.invDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('Uploaded invontaie ${invontaie.invNo} successfully.');
            if (invontaie.invNo != null) {
              final updated = await dbHelper.markInvontaieAsUploaded(invontaie.invNo!);
              countInvontaies.value = (countInvontaies.value - updated).clamp(0, pendingInvontaies.length);
            } else {
              continue;
            }
          }
        } catch (e) {
          print('Failed to upload invontaie ${invontaie.invNo}: $e');
          continue;
        }
      }
    } catch (e) {
      print('Failed to upload invontaies: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Map<String, String> removeQtyFromName(String name) {
    String qtyText = "";
    String cleanName = name;

    final qtyRegex = RegExp(r'/\s*Qte\s*[:=]?\s*(\d+)\s*$', caseSensitive: false);
    final match = qtyRegex.firstMatch(name);
    if (match != null) {
      qtyText = match.group(0) ?? "";
      // Extract clean name without modifying the original
      cleanName = name.replaceAll(qtyRegex, '').trim();
    }
    return {'qtyText': qtyText, 'cleanName': cleanName};
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
