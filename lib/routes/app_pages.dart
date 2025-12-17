import 'package:get/get.dart';

import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/goals/views/goals_view.dart';
import '../modules/insights/views/insights_view.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/receipts/views/receipts_view.dart';
import '../modules/settings/views/category_settings_view.dart';
import '../modules/settings/views/currency_settings_view.dart';
import '../modules/settings/views/reminders_settings_view.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/transactions/views/add_transaction_view.dart';
import '../modules/wallets/views/wallets_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.dashboard;

  static final pages = [
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardView()),
    GetPage(
      name: AppRoutes.addTransaction,
      page: () => const AddTransactionView(),
    ),
    GetPage(name: AppRoutes.wallets, page: () => const WalletsView()),
    GetPage(name: AppRoutes.goals, page: () => const GoalsView()),
    GetPage(name: AppRoutes.insights, page: () => const InsightsView()),
    GetPage(name: AppRoutes.receipts, page: () => const ReceiptsView()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView()),
    GetPage(
      name: AppRoutes.categorySettings,
      page: () => const CategorySettingsView(),
    ),
    GetPage(
      name: AppRoutes.currencySettings,
      page: () => const CurrencySettingsView(),
    ),
    GetPage(
      name: AppRoutes.remindersSettings,
      page: () => const RemindersSettingsView(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
    ),
  ];
}
