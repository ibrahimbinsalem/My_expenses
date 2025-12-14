import 'package:get/get.dart';

import '../../core/controllers/theme_controller.dart';
import '../../core/services/settings_service.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/local_expense_repository.dart';
import '../../data/services/ai_insight_service.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/voice_entry_service.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/goals/controllers/goals_controller.dart';
import '../../modules/insights/controllers/insights_controller.dart';
import '../../modules/onboarding/controllers/onboarding_controller.dart';
import '../../modules/receipts/controllers/receipts_controller.dart';
import '../../modules/settings/controllers/settings_controller.dart';
import '../../modules/transactions/controllers/transactions_controller.dart';
import '../../modules/wallets/controllers/wallets_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    final settingsService = Get.find<SettingsService>();
    final themeController = Get.find<ThemeController>();

    if (!Get.isRegistered<AppDatabase>()) {
      Get.put<AppDatabase>(AppDatabase.instance, permanent: true);
    }
    if (!Get.isRegistered<LocalExpenseRepository>()) {
      Get.put<LocalExpenseRepository>(
        LocalExpenseRepository(Get.find<AppDatabase>()),
        permanent: true,
      );
    }
    Get.lazyPut<LocalInsightService>(() => LocalInsightService(), fenix: true);
    Get.lazyPut<ReceiptOcrService>(() => ReceiptOcrService(), fenix: true);
    Get.lazyPut<VoiceEntryService>(() => VoiceEntryService(), fenix: true);

    Get.lazyPut<OnboardingController>(
      () => OnboardingController(Get.find(), settingsService),
      fenix: true,
    );
    Get.lazyPut<DashboardController>(
      () => DashboardController(Get.find(), Get.find()),
      fenix: true,
    );
    Get.lazyPut<TransactionsController>(
      () => TransactionsController(Get.find(), Get.find(), Get.find()),
      fenix: true,
    );
    Get.lazyPut<WalletsController>(
      () => WalletsController(Get.find()),
      fenix: true,
    );
    Get.lazyPut<GoalsController>(
      () => GoalsController(Get.find()),
      fenix: true,
    );
    Get.lazyPut<InsightsController>(
      () => InsightsController(Get.find()),
      fenix: true,
    );
    Get.lazyPut<ReceiptsController>(
      () => ReceiptsController(Get.find()),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(
      () => SettingsController(Get.find(), themeController),
      fenix: true,
    );
  }
}
