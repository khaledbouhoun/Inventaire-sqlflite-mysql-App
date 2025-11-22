import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invontaire_local/controoler/app_controller.dart';
import 'dart:ui';

class OnlineLoginWidget extends StatefulWidget {
  const OnlineLoginWidget({super.key});

  @override
  State<OnlineLoginWidget> createState() => _OnlineLoginWidgetState();
}

class _OnlineLoginWidgetState extends State<OnlineLoginWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  AppController get controller => Get.find<AppController>();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF19CF74);
    const red = Color(0xFFFF4242);

    return Obx(
      () => Hero(
        tag: "online-status",
        child: AnimatedContainer(
          height: 60,
          width: 60,
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            gradient: LinearGradient(
              colors: controller.isOnline.value ? [green.withOpacity(0.8), green] : [red.withOpacity(0.8), red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: controller.isOnline.value ? green.withOpacity(0.45) : red.withOpacity(0.45),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.65), blurRadius: 10, spreadRadius: 2)],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: controller.isOnline.value ? green : red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: controller.isOnline.value ? green : red.withOpacity(0.65), blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                          child: Icon(
                            controller.isOnline.value ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnlineWidget extends StatefulWidget {
  const OnlineWidget({super.key});

  @override
  State<OnlineWidget> createState() => _OnlineWidgetState();
}

class _OnlineWidgetState extends State<OnlineWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  AppController get controller => Get.find<AppController>();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF19CF74);
    const red = Color(0xFFFF4242);

    return Obx(
      () => Hero(
        tag: "online-status",
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            gradient: LinearGradient(
              colors: controller.isOnline.value ? [green.withOpacity(0.8), green] : [red.withOpacity(0.8), red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: controller.isOnline.value ? green.withOpacity(0.45) : red.withOpacity(0.45),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.65), blurRadius: 10, spreadRadius: 2)],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: controller.isOnline.value ? green : red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: controller.isOnline.value ? green : red.withOpacity(0.65), blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                          child: Icon(
                            controller.isOnline.value ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// online widget mini

class MiniOnlineWidget extends StatefulWidget {
  const MiniOnlineWidget({super.key});

  @override
  State<MiniOnlineWidget> createState() => _MiniOnlineWidgetState();
}

class _MiniOnlineWidgetState extends State<MiniOnlineWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  AppController get controller => Get.find<AppController>();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF19CF74);
    const red = Color(0xFFFF4242);

    return Obx(
      () => Hero(
        tag: "online-status",
        child: AnimatedContainer(
          alignment: .center,
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            gradient: LinearGradient(
              colors: controller.isOnline.value ? [green.withOpacity(0.8), green] : [red.withOpacity(0.8), red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: controller.isOnline.value ? green.withOpacity(0.45) : red.withOpacity(0.45),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Icon(controller.isOnline.value ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
