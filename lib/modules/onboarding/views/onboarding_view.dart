import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../../../widgets/currency_picker_field.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  children: const [
                    _IntroSlide(
                      title: 'تحكم كامل في مصاريفك',
                      description:
                          'كل عملية، كل محفظة، وكل هدف محفوظ محليًا بجهازك وبدون إنترنت.',
                      icon: Icons.security,
                    ),
                    _IntroSlide(
                      title: 'مساعد ذكي يعمل دون اتصال',
                      description:
                          'نصائح ادخار وتحليلات فورية لتعرف أين تذهب ميزانيتك.',
                      icon: Icons.auto_awesome,
                    ),
                    _SetupSlide(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: controller.pageController,
                      count: 3,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: AppColors.secondary,
                        dotColor: Colors.white24,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Row(
                        children: [
                          if (controller.currentPage.value < 2)
                            TextButton(
                              onPressed: () {
                                controller.pageController.animateToPage(
                                  2,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text('تخطي'),
                            )
                          else
                            const SizedBox(width: 68),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: controller.currentPage.value < 2
                                ? () {
                                    controller.pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : controller.isSaving.value
                                ? null
                                : controller.completeSetup,
                            child: controller.isSaving.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    controller.currentPage.value < 2
                                        ? 'التالي'
                                        : 'ابدأ بتنظيم مصاريفي',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.secondary, size: 90),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SetupSlide extends GetView<OnboardingController> {
  const _SetupSlide();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'لنجهز حسابك',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.walletNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المحفظة الأولى',
                        prefixIcon: Icon(Icons.wallet),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.startingBalanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الرصيد الابتدائي',
                        prefixIcon: Icon(Icons.savings),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CurrencyPickerField(
                      controller: controller.currencyController,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'اختر الفئات التي تناسبك',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          controller.recommendedCategories.length,
                          (index) {
                            final category =
                                controller.recommendedCategories[index];
                            final isSelected = controller.selectedCategories
                                .contains(index);
                            return ChoiceChip(
                              label: Text(category['name']! as String),
                              selected: isSelected,
                              onSelected: (_) =>
                                  controller.toggleCategory(index),
                              selectedColor: AppColors.secondary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.black87,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
