import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/constant/color.dart';
import 'package:invontaire_local/controoler/login_controller.dart';
import 'package:invontaire_local/data/model/user_model.dart';
import 'package:invontaire_local/fonctions/alertexitapp.dart';
import 'package:invontaire_local/view/widget/onlinewidget.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    print("Login screen initialized.");
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    // Fade in animation for the whole content
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    // Slide up animation for the main form content
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    // Start the animation when the screen is built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Enhanced Background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColor.background, AppColor.background.withOpacity(0.95)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GetBuilder<LoginController>(
          init: LoginController(),
          builder: (controller) {
            return WillPopScope(
              onWillPop: alertExitApp,
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => controller.fetchUsers(),
                  color: AppColor.primaryColor,
                  backgroundColor: AppColor.background,
                  child: CustomScrollView(
                    // physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),

                      // Main Content (Fade and Slide In)
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _opacityAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Form(
                                key: controller.formStateLogin,
                                child: Column(
                                  children: [
                                    // Logo or Brand Section (with subtle scaling)
                                    OnlineLoginWidget(),
                                    const SizedBox(height: 50),
                                    _buildLogo(),

                                    const SizedBox(height: 32),

                                    // Welcome Text
                                    const Text(
                                      'Bienvenue',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.black,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Veuillez vous connecter pour continuer',
                                      style: TextStyle(fontSize: 16, color: AppColor.black.withOpacity(0.6), fontWeight: FontWeight.w500),
                                    ),

                                    const SizedBox(height: 48),

                                    // Dossier Dropdown
                                    Obx(
                                      () => _buildModernDropdown<User>(
                                        icon: Icons.person_outline,
                                        label: "Sélectionner l'utilisateur",
                                        value: controller.selectedUser.value,
                                        items: controller.users.map((user) {
                                          return DropdownMenuItem(
                                            value: user,
                                            child: Text(
                                              user.usrNom!,
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

                                    // // Remember Me Checkbox
                                    // _buildCheckBox(controller),

                                    // const SizedBox(height: 40),

                                    // Login Button
                                    Obx(() => _buildLoginButton(controller)),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Logo Widget
  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30), // Slightly less rounded for a modern look
        boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 60),
    );
  }

  // Modern Dropdown Field (Slightly refined)
  Widget _buildModernDropdown<T>({
    required IconData icon,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: value != null ? AppColor.primaryColor.withOpacity(0.3) : Colors.transparent, width: 1.5),
        boxShadow: [BoxShadow(color: AppColor.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColor.primaryColor, size: 30),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: AppColor.primaryColor, size: 24),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: AppColor.primaryColor.withOpacity(0.8),
            fontFamily: "Nunito",
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
        ),
        dropdownColor: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        style: const TextStyle(color: AppColor.black, fontFamily: "Nunito", fontSize: 16, fontWeight: FontWeight.w600),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // Password Field (Refined with smoother error handling)
  Widget _buildPasswordField(LoginController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColor.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
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
          labelStyle: TextStyle(color: AppColor.primaryColor.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColor.primaryColor.withOpacity(0.5), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCheckBox(LoginController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColor.primaryColor.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Obx(
            () => Checkbox(
              value: controller.rememberMe.value,
              onChanged: (value) => controller.rememberMe.value = value!,
              activeColor: AppColor.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),

          const SizedBox(width: 5),

          const Text(
            'Rester connecté',
            style: TextStyle(fontFamily: "Nunito", fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Login Button (Modern, animated, with loading state)
  Widget _buildLoginButton(LoginController controller) {
    final isLoading = controller.isLoading.value;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : controller.login,
        style:
            ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: isLoading ? 0 : 15,
              shadowColor: AppColor.primaryColor.withOpacity(0.4),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withOpacity(0.1);
                }
                return null;
              }),
            ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (widget, animation) {
                return ScaleTransition(scale: animation, child: widget);
              },
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Row(
                      key: ValueKey('text'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Se connecter',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
