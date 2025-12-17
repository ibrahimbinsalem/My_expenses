import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/world_currencies.dart';
import '../../../core/utils/currency_utils.dart';
import '../controllers/onboarding_controller.dart';

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
                      titleKey: 'onboarding.slide1.title',
                      descriptionKey: 'onboarding.slide1.description',
                      icon: Icons.security,
                    ),
                    _IntroSlide(
                      titleKey: 'onboarding.slide2.title',
                      descriptionKey: 'onboarding.slide2.description',
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
                    Obx(() {
                      final isLastPage = controller.currentPage.value >= 2;
                      final isProcessing = controller.isSaving.value;
                      final canSubmit = controller.isSetupValid.value;
                      return Row(
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
                              child: Text('common.skip'.tr),
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
                            onPressed: isLastPage
                                ? (isProcessing || !canSubmit
                                      ? null
                                      : controller.completeSetup)
                                : () {
                                    controller.pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                            child: isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    isLastPage
                                        ? 'ابدأ بتنظيم مصاريفي'.tr
                                        : 'common.next'.tr,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                          ),
                        ],
                      );
                    }),
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
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
  });

  final String titleKey;
  final String descriptionKey;
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
            titleKey.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            descriptionKey.tr,
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
                    _InitialCurrencySelector(controller: controller),
                    const SizedBox(height: 12),
                    Text(
                      'لنجهز حسابك'.tr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم'.tr,
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ستقوم بإنشاء محافظك وإدخال أرصدتك بعد الدخول للتطبيق من قسم المحافظ.'
                          .tr,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'اختر الفئات التي تناسبك'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                              label: Text(
                                (category['name']! as String).tr,
                              ),
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

class _InitialCurrencySelector extends StatelessWidget {
  const _InitialCurrencySelector({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حدد العملات التي تريد استخدامها'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final currencies = controller.currencies;
              if (currencies.isEmpty) {
                return Text(
                  'لم تحدد أي عملة بعد. اختر من القائمة العالمية لبدء الاستخدام.'
                      .tr,
                  style: const TextStyle(color: Colors.black54),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currencies
                    .map(
                      (currency) => Chip(
                        backgroundColor: AppColors.secondary.withValues(
                          alpha: 0.2,
                        ),
                        label: Text('${currency.name} (${currency.code})'),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => controller.removeCurrency(currency),
                      ),
                    )
                    .toList(),
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showWorldCurrencyPicker(context, controller),
              icon: const Icon(Icons.public),
              label: Text('اختيار العملات من العالم'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showWorldCurrencyPicker(
  BuildContext context,
  OnboardingController controller,
) async {
  final existingCodes = controller.currencies
      .map((currency) => currency.code.toUpperCase())
      .toSet();
  final available = worldCurrencies
      .where(
        (currency) =>
            !existingCodes.contains((currency['code'] as String).toUpperCase()),
      )
      .toList();
  if (available.isEmpty) {
    Get.snackbar(
      'common.alert'.tr,
      'جميع العملات متاحة بالفعل في حسابك.'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  final selected = <String>{};
  final searchController = TextEditingController();

  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
          final query = searchController.text.toLowerCase();
          final filtered = available.where((currency) {
            final nameAr =
                (currency['nameAr'] ?? currency['name'] ?? '').toLowerCase();
            final nameEn =
                (currency['nameEn'] ?? currency['name'] ?? '').toLowerCase();
            final code = (currency['code'] as String).toLowerCase();
            return nameAr.contains(query) ||
                nameEn.contains(query) ||
                code.contains(query);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'اختر العملات'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'common.currency_search'.tr,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('common.no_results'.tr),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final currency = filtered[index];
                        final code = currency['code'] as String;
                        final name = localizedCurrencyName(
                          currency.cast<String, String>(),
                        );
                        final isSelected = selected.contains(code);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(code);
                              } else {
                                selected.remove(code);
                              }
                            });
                          },
                          title: Text(name),
                          subtitle: Text(code),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('common.cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final selections = available
                                    .where(
                                      (currency) => selected.contains(
                                        currency['code'] as String,
                                      ),
                                    )
                                    .map(
                                      (currency) => {
                                        'code': currency['code'] as String,
                                        'name': localizedCurrencyName(
                                          currency.cast<String, String>(),
                                        ),
                                      },
                                    )
                                    .toList();
                                final success = await controller
                                    .addInitialCurrencies(selections);
                                navigator.pop();
                                if (success) {
                                  Get.snackbar(
                                    'common.added'.tr,
                                    'تم حفظ العملات المختارة.'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } else {
                                  Get.snackbar(
                                    'common.alert'.tr,
                                    'لم يتم إضافة أي عملة جديدة.'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        child: Text('حفظ العملات'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          },
        );
      },
    );
  } finally {
    searchController.dispose();
  }
}
