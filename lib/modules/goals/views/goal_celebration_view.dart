import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../routes/app_routes.dart';

class GoalCelebrationView extends StatefulWidget {
  const GoalCelebrationView({super.key});

  @override
  State<GoalCelebrationView> createState() => _GoalCelebrationViewState();
}

class _GoalCelebrationViewState extends State<GoalCelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final goalName = args['goalName'] as String? ?? '—';
    final goalAmount = args['targetAmount'] as num? ?? 0;
    final currency = args['currency'] as String? ?? 'SAR';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2B50), Color(0xFF10152A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final scale = 0.9 + (_controller.value * 0.1);
                        final rotate = (_controller.value - 0.5) * 0.15;
                        return Transform.rotate(
                          angle: rotate,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary.withOpacity(0.15),
                            ),
                          ),
                          Container(
                            width: 170,
                            height: 170,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFFD75E),
                                  Color(0xFFFFB347),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.emoji_events,
                            size: 120,
                            color: Colors.white,
                          ),
                          Positioned(
                            top: 12,
                            child: Row(
                              children: List.generate(
                                12,
                                (index) => Transform.rotate(
                                  angle: (math.pi / 6) * index,
                                  child: Container(
                                    width: 2,
                                    height: 30,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'goals.celebration.title'.tr,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'goals.celebration.subtitle'
                          .trParams({'name': goalName}),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'goals.celebration.message'.trParams({
                        'amount': Formatters.currency(
                          goalAmount,
                          symbol: currency,
                        ),
                      }),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Get.offAllNamed(AppRoutes.dashboard);
                        },
                        child: Text('goals.celebration.button.home'.tr),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.offAllNamed(AppRoutes.goals),
                      child: Text(
                        'goals.celebration.button.goals'.tr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
