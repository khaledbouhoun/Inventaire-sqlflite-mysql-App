import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/class/crud.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/constant/linkapi.dart';
import 'package:invontaire_local/data/model/exercice_model.dart';
import 'package:invontaire_local/data/model/dossei_model.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/main.dart';
import 'package:invontaire_local/view/screen/home.dart';

class LoginController extends GetxController {
  // Dependencies
  final Crud crud = Crud();
  final AppLink appLink = Get.find<AppLink>();
  final MyServices myServices = Get.find();

  // Form keys
  final formStateLogin = GlobalKey<FormState>();
  final formStateServer = GlobalKey<FormState>();

  // Text controllers
  final passwordController = TextEditingController();
  final serverController = TextEditingController();
  final portController = TextEditingController();

  // Observable state
  final isConnected = false.obs;
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  // Selected values
  final Rx<DossierModel?> selectedDossier = Rx<DossierModel?>(null);
  final Rx<ExerciceModel?> selectedExercice = Rx<ExerciceModel?>(null);
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);

  // Lists
  final RxList<DossierModel> dossiers = <DossierModel>[].obs;
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<ExerciceModel> exercices = <ExerciceModel>[].obs;

  // Computed properties
  String? get currentBase => selectedDossier.value?.dosBdd;
  bool get canLogin => selectedDossier.value != null && selectedExercice.value != null && selectedUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _initializeServerConfig();
  }

  // Initialize server configuration
  void _initializeServerConfig() {
    final savedServer = myServices.sharedPreferences.getString('server');
    final savedPort = myServices.sharedPreferences.getString('port');

    if (savedServer == null || savedPort == null) {
      Future.delayed(Duration(milliseconds: 500), showServerDialog);
    } else {
      serverController.text = savedServer;
      portController.text = savedPort;
      fetchDossiers();
      update();
    }
  }

  // Fetch dossiers from server
  Future<void> fetchDossiers() async {
    try {
      isLoading.value = true;

      // final response = await crud.get(appLink.getDossieUrl());
      final response = await crud.get(AppLink.autoLogin);

      if (response.statusCode == 200) {
        final List data = response.body['Data'];
        dossiers.value = data.map((e) => DossierModel.fromJson(e)).toList();
        // Ensure selectedDossier is valid
        if (selectedDossier.value == null || !dossiers.any((d) => d.dosNo == selectedDossier.value?.dosNo)) {
          selectedDossier.value = null;
        }
        final baseSysPath = response.body['BaseSys'];
        myServices.sharedPreferences.setString('BaseSys', baseSysPath);
        isConnected.value = true;
        // _showSuccessSnackbar('Connexion réussie');
      } else {
        throw Exception('Échec de la récupération des dossiers');
      }
    } catch (e) {
      isConnected.value = false;
      _showErrorSnackbar('Erreur de connexion au serveur');
      debugPrint('Error fetching dossiers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch users for selected dossier
  Future<void> fetchUsers(DossierModel dossier) async {
    try {
      isLoading.value = true;

      final response = await crud.get(AppLink.autoLogin);

      if (response.statusCode == 200) {
        if (response.body == null || response.body.toString().isEmpty) {
          throw Exception('Empty response from server');
        }

        // Try to parse the response body as a List
        final List data = response.body is List
            ? response.body
            : response.body is Map
            ? (response.body['users'] ?? [])
            : [];

        users.value = data.map((e) => UserModel.fromJson(e)).toList();

        if (users.isEmpty) {
          _showErrorSnackbar('Aucun utilisateur trouvé pour ce dossier');
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      users.clear();
      _showErrorSnackbar('Erreur lors du chargement des utilisateurs: ${e.toString()}');
      debugPrint('Error fetching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch exercices for selected database
  Future<void> fetchExercices(String database) async {
    try {
      isLoading.value = true;

      final response = await crud.get(AppLink.autoLogin);

      if (response.statusCode == 200) {
        final List data = response.body['exercices'];
        exercices.value = data.map((e) => ExerciceModel.fromJson(e)).toList();
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des exercices');
      debugPrint('Error fetching exercices: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Handle dossier selection
  Future<void> onDossierChanged(DossierModel? dossier) async {
    if (dossier == null) return;

    selectedDossier.value = dossier;
    selectedExercice.value = null;
    selectedUser.value = null;
    users.clear();
    exercices.clear();

    await Future.wait([fetchExercices(dossier.dosBdd!), fetchUsers(dossier)]);
  }

  // Handle exercice selection
  void onExerciceChanged(ExerciceModel? exercice) {
    selectedExercice.value = exercice;
  }

  // Handle user selection
  void onUserChanged(UserModel? user) {
    selectedUser.value = user;
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Perform login
  Future<void> login() async {
    if (!formStateLogin.currentState!.validate()) {
      _showErrorSnackbar('Veuillez remplir tous les champs requis');
      return;
    }

    if (!canLogin) {
      _showErrorSnackbar('Veuillez sélectionner toutes les données requises');
      return;
    }

    try {
      isLoading.value = true;

      final hashedPassword = md5.convert(passwordController.text.codeUnits).toString();

      if (hashedPassword.toUpperCase() == selectedUser.value!.userPass!.toUpperCase()) {
        // _showSuccessSnackbar('Connexion réussie');
        print(
          "login ... user : ${selectedUser.value!.userLogin} dossie : ${selectedDossier.value!.dosBdd} exercice : ${selectedExercice.value!.eXEDATEDEB!.year} ",
        );
        Get.off(
          () => Home(),
          arguments: {'user': selectedUser.value, 'dossier': selectedDossier.value, 'exercice': selectedExercice.value},
        );
      } else {
        _showErrorSnackbar('Mot de passe incorrect');
      }
    } catch (e) {
      _showErrorSnackbar('Une erreur s\'est produite lors de la connexion');
      debugPrint('Login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Show server configuration dialog
  void showServerDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Form(
            key: formStateServer,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColor.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.dns_outlined, color: AppColor.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Paramètres du serveur',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Server input
                _buildServerInput(
                  controller: serverController,
                  label: 'Adresse du serveur',
                  hint: '192.168.1.1',
                  icon: Icons.computer_outlined,
                ),
                const SizedBox(height: 16),

                // Port input
                _buildServerInput(
                  controller: portController,
                  label: 'Port',
                  hint: '8181',
                  icon: Icons.settings_ethernet_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Connect button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleServerConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Connexion',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Build server input field
  Widget _buildServerInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColor.black, fontSize: 16, fontWeight: FontWeight.w600),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColor.primaryColor),
        filled: true,
        fillColor: AppColor.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.primaryColor, width: 2),
        ),
      ),
    );
  }

  // Handle server connection
  Future<void> _handleServerConnection() async {
    if (!formStateServer.currentState!.validate()) return;

    myServices.sharedPreferences.setString('server', serverController.text.trim());
    myServices.sharedPreferences.setString('port', portController.text.trim());

    dossiers.clear();
    exercices.clear();
    users.clear();
    selectedDossier.value = null;
    selectedExercice.value = null;
    selectedUser.value = null;

    Get.back();

    await fetchDossiers();
    update();
  }

  // Helper methods for snackbars
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Succès',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }
}
