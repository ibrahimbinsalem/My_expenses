import 'package:get/get.dart';

import '../modules/bills/views/bills_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/goals/views/goals_view.dart';
import '../modules/goals/views/goal_details_view.dart';
import '../modules/goals/views/goal_celebration_view.dart';
import '../modules/insights/views/insights_view.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/reports/controllers/activity_report_controller.dart';
import '../modules/reports/controllers/category_report_controller.dart';
import '../modules/reports/controllers/goals_report_controller.dart';
import '../modules/reports/controllers/wallet_report_controller.dart';
import '../modules/reports/views/activity_report_view.dart';
import '../modules/reports/views/category_report_view.dart';
import '../modules/reports/views/goals_report_view.dart';
import '../modules/reports/views/wallet_report_view.dart';
import '../modules/receipts/views/receipts_view.dart';
import '../modules/settings/views/category_settings_view.dart';
import '../modules/settings/views/currency_settings_view.dart';
import '../modules/settings/views/reminders_settings_view.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/transactions/views/add_transaction_view.dart';
import '../modules/wallets/views/wallets_view.dart';
import '../modules/tasks/views/tasks_view.dart';
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
    GetPage(
      name: AppRoutes.goalDetails,
      page: () => const GoalDetailsView(),
    ),
    GetPage(
      name: AppRoutes.goalCelebration,
      page: () => const GoalCelebrationView(),
    ),
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
    GetPage(
      name: AppRoutes.billBook,
      page: () => const BillsView(),
    ),
    GetPage(
      name: AppRoutes.tasks,
      page: () => const TasksView(),
    ),
    GetPage(
      name: AppRoutes.reportsCategory,
      page: () => const CategoryReportView(),
      binding: BindingsBuilder(
        () => Get.put(CategoryReportController(Get.find())),
      ),
    ),
    GetPage(
      name: AppRoutes.reportsWallet,
      page: () => const WalletReportView(),
      binding: BindingsBuilder(
        () => Get.put(WalletReportController(Get.find())),
      ),
    ),
    GetPage(
      name: AppRoutes.reportsGoals,
      page: () => const GoalsReportView(),
      binding: BindingsBuilder(
        () => Get.put(GoalsReportController(Get.find())),
      ),
    ),
    GetPage(
      name: AppRoutes.reportsActivity,
      page: () => const ActivityReportView(),
      binding: BindingsBuilder(
        () => Get.put(ActivityReportController(Get.find())),
      ),
    ),
  ];
}
