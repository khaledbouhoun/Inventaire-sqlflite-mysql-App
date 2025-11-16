import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/login_controller.dart';
import 'package:invontaire_local/data/model/exercice_model.dart';
import 'package:invontaire_local/data/model/dossei_model.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/fonctions/alertexitapp.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: GetBuilder<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return WillPopScope(
            onWillPop: alertExitApp,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Modern App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    expandedHeight: 0,
                    scrolledUnderElevation: 0,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16, top: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: controller.showServerDialog,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: AppColor.primaryColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.settings_outlined, color: AppColor.primaryColor, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Main Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: controller.formStateLogin,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Connection Status Badge
                            Obx(() => _buildConnectionBadge(controller)),

                            const SizedBox(height: 40),

                            // Logo or Brand Section
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: AppColor.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 50),
                            ),

                            const SizedBox(height: 32),

                            // Welcome Text
                            const Text(
                              'Bienvenue',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColor.black, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Veuillez vous connecter pour continuer',
                              style: TextStyle(fontSize: 16, color: AppColor.black.withOpacity(0.6), fontWeight: FontWeight.w500),
                            ),

                            const SizedBox(height: 48),

                            // Dossier Dropdown
                            Obx(
                              () => _buildModernDropdown<DossierModel>(
                                icon: Icons.folder_outlined,
                                label: "Sélectionner le dossier",
                                value: controller.selectedDossier.value,
                                items: controller.dossiers.map((dossier) {
                                  return DropdownMenuItem(
                                    value: dossier,
                                    child: Text(
                                      '${dossier.dosNo} : ${dossier.dosNom}',
                                      style: const TextStyle(
                                        fontFamily: "Nunito",
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primaryColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: controller.onDossierChanged,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Exercice Dropdown
                            Obx(
                              () => _buildModernDropdown<ExerciceModel>(
                                icon: Icons.calendar_today_outlined,
                                label: "Sélectionner l'exercice",
                                value: controller.selectedExercice.value,
                                items: controller.exercices.map((exercice) {
                                  String label = exercice.eXEDATEDEB!.year == exercice.eXEDATEFIN!.year
                                      ? '${exercice.eXEDATEDEB!.year}'
                                      : '${exercice.eXEDATEDEB!.year} - ${exercice.eXEDATEFIN!.year}';
                                  return DropdownMenuItem(
                                    value: exercice,
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontFamily: "Nunito",
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primaryColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: controller.onExerciceChanged,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // User Dropdown
                            Obx(
                              () => _buildModernDropdown<UserModel>(
                                icon: Icons.person_outline,
                                label: "Sélectionner l'utilisateur",
                                value: controller.selectedUser.value,
                                items: controller.users.map((user) {
                                  return DropdownMenuItem(
                                    value: user,
                                    child: Text(
                                      user.userLogin!,
                                      style: const TextStyle(
                                        fontFamily: "Nunito",
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primaryColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: controller.onUserChanged,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password Field
                            Obx(() => _buildPasswordField(controller)),

                            const SizedBox(height: 40),

                            // Login Button
                            Obx(() => _buildLoginButton(controller)),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Connection Status Badge
  Widget _buildConnectionBadge(LoginController controller) {
    final isConnected = controller.isConnected.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected ? [Colors.green.shade400, Colors.green.shade600] : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: (isConnected ? Colors.green : Colors.red).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isConnected ? 'Connecté' : 'Déconnecté',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Modern Dropdown Field
  Widget _buildModernDropdown<T>({
    required IconData icon,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: value != null ? AppColor.primaryColor.withOpacity(0.3) : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.primaryColor, size: 28),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColor.primaryColor.withOpacity(0.15), AppColor.primaryColor.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColor.primaryColor, size: 24),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: AppColor.primaryColor.withOpacity(0.8),
            fontFamily: "Nunito",
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        dropdownColor: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        style: const TextStyle(color: AppColor.primaryColor, fontFamily: "Nunito", fontSize: 16, fontWeight: FontWeight.w600),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // Password Field
  Widget _buildPasswordField(LoginController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller.passwordController,
        obscureText: controller.obscurePassword.value,
        style: const TextStyle(color: AppColor.black, fontFamily: "Nunito", fontSize: 16, fontWeight: FontWeight.w600),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un mot de passe';
          }
          return null;
        },
        cursorColor: AppColor.primaryColor,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          labelText: 'Mot de passe',
          labelStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.8), fontWeight: FontWeight.w600),
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColor.primaryColor.withOpacity(0.15), AppColor.primaryColor.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lock_outline, color: AppColor.primaryColor, size: 24),
          ),
          suffixIcon: IconButton(
            onPressed: controller.togglePasswordVisibility,
            icon: Icon(
              controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColor.primaryColor,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  // Login Button
  Widget _buildLoginButton(LoginController controller) {
    final isLoading = controller.isLoading.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : controller.login,
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se connecter',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
