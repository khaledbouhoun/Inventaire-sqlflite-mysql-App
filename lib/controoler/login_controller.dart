import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/linkapi.dart'; // Assumed to contain base API link
import 'package:invontaire_local/controoler/app_controller.dart';
import 'package:invontaire_local/fonctions/dialog.dart';
import 'package:invontaire_local/main.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/view/screen/home.dart';

class LoginController extends GetxController {
  // Dependencies (assuming these are correctly configured)
  final Crud crud = Crud();
  // final AppLink appLink = Get.find<AppLink>(); // Removed as it's not used here
  final MyServices myServices = Get.find();
  Dialogfun dialogfun = Dialogfun();
  AppController appController = Get.find<AppController>();

  // Form keys
  final formStateLogin = GlobalKey<FormState>();

  // Text controllers
  final passwordController = TextEditingController();

  // Observable state
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  var rememberMe = false.obs;

  // Selected values
  final Rx<User?> selectedUser = Rx<User?>(null);
  // Lists
  final RxList<User> users = <User>[].obs;

  // --- NEW: Define the server-side login API link ---
  // static const String loginApiLink = "";

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  // Fetch users for selection (Name/ID only)
  Future<void> fetchUsers() async {
    print("Fetching users for login...");
    try {
      isLoading.value = true;
      // We still fetch users to populate the dropdown for selection.
      final response = await crud.get(AppLink.users);

      if (response.statusCode == 200) {
        // The response body is assumed to be a List<Map<String, dynamic>>
        final List<dynamic> data = response.body;

        users.value = data
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();

        if (users.isEmpty) {
          dialogfun.showSnackWarning(
            'Avertissement',
            'Aucun utilisateur trouvé pour ce dossier',
          );
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      users.clear();
      dialogfun.showSnackError(
        'Erreur',
        'Erreur lors du chargement des utilisateurs: Impossible de se connecter au serveur.',
      );
      debugPrint('Error fetching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Handle user selection
  void onUserChanged(User? user) {
    selectedUser.value = user;
    passwordController.clear(); // Clear password on user change
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Perform secure login via API call
  Future<void> login() async {
    if (formStateLogin.currentState!.validate() || selectedUser.value != null) {
      try {
        isLoading.value = true;

        // 1. Prepare data to send to the server's login endpoint
        final loginData = {
          // Using usr_nom (username) to log in, as implemented in your PHP file
          'usr_nom': selectedUser.value!.usrNom,
          'usr_pas': passwordController.text, // Send plain password to server
          'remember': false, // Example: set this based on a checkbox if needed
          // 'remember': rememberMe.value, // Example: set this based on a checkbox if needed
        };

        // 2. Make the POST request to the server login API
        final response = await crud.post(AppLink.login, loginData);

        if (response.statusCode == 200) {
          // Login successful. The server responded with user data and maybe a token.
          // Assuming response.body is a Map<String, dynamic> containing the logged-in User data.

          // Save user data (e.g., token) if necessary, and navigate to Home
          Get.off(
            () => Home(),
            arguments: {'user': selectedUser.value, 'success': true},
          );
        } else if (response.statusCode == 401) {
          // Unauthorized - Server explicitly stated invalid credentials
          dialogfun.showSnackError(
            'Erreur',
            'Mot de passe ou utilisateur incorrect.',
          );
        } else {
          // Other server error
          dialogfun.showSnackError(
            'Erreur',
            'Erreur serveur lors de la connexion. Code: ${response.statusCode}',
          );
        }
      } catch (e) {
        dialogfun.showSnackError(
          'Erreur',
          'Impossible de se connecter au service de connexion.',
        );
        debugPrint('Secure Login error: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}
