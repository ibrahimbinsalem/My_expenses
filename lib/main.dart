import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/bindings/root_binding.dart';
import 'core/controllers/locale_controller.dart';
import 'core/controllers/security_controller.dart';
import 'core/controllers/theme_controller.dart';
import 'core/localization/app_translations.dart';
import 'core/services/auto_backup_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/security_service.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/repositories/local_expense_repository.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'widgets/app_lock_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  await GetStorage.init();
  final settings = await SettingsService().init();
  Get.put<SettingsService>(settings, permanent: true);
  final securityService = await SecurityService().init();
  Get.put<SecurityService>(securityService, permanent: true);
  final database = AppDatabase.instance;
  Get.put<AppDatabase>(database, permanent: true);
  Get.put<LocalExpenseRepository>(
    LocalExpenseRepository(database),
    permanent: true,
  );
  Get.put<BackupService>(BackupService(database), permanent: true);
  final notificationService = await NotificationService().init();
  Get.put<NotificationService>(notificationService, permanent: true);
  final autoBackupService = await AutoBackupService().init();
  Get.put<AutoBackupService>(autoBackupService, permanent: true);
  Get.put<SecurityController>(
    SecurityController(securityService),
    permanent: true,
  );
  if (settings.notificationsEnabled) {
    await notificationService.rescheduleAllReminders();
  }
  final translations = await AppTranslations.load();
  runApp(MyExpensesApp(translations: translations));
}

class MyExpensesApp extends StatelessWidget {
  const MyExpensesApp({required this.translations, super.key});

  final AppTranslations translations;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final themeController = Get.put(ThemeController(settings), permanent: true);
    final localeController = Get.put(LocaleController(settings), permanent: true);
    final securityController = Get.find<SecurityController>();
    final initialRoute = settings.isOnboarded
        ? AppRoutes.dashboard
        : AppRoutes.onboarding;

    return Obx(
      () => GetMaterialApp(
        title: 'app.title'.tr,
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        initialBinding: RootBinding(),
        getPages: AppPages.pages,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        locale: localeController.locale.value,
        translations: translations,
        fallbackLocale: const Locale('en'),
        defaultTransition: Transition.cupertino,
        builder: (context, child) {
          final overlay = Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => child ?? const SizedBox.shrink(),
              ),
              OverlayEntry(
                builder: (_) => AppLockOverlay(
                  controller: securityController,
                ),
              ),
            ],
          );
          return Obx(() {
            final scale = settings.textScaleNotifier.value;
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaleFactor: scale.clamp(0.8, 1.4),
              ),
              child: overlay,
            );
          });
        },
      ),
    );
  }
}
