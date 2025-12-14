import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/root_binding.dart';
import 'core/controllers/theme_controller.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/repositories/local_expense_repository.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final settings = await SettingsService().init();
  Get.put<SettingsService>(settings, permanent: true);
  final database = AppDatabase.instance;
  Get.put<AppDatabase>(database, permanent: true);
  Get.put<LocalExpenseRepository>(
    LocalExpenseRepository(database),
    permanent: true,
  );
  runApp(const MyExpensesApp());
}

class MyExpensesApp extends StatelessWidget {
  const MyExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    final themeController = Get.put(ThemeController(settings), permanent: true);
    final initialRoute = settings.isOnboarded
        ? AppRoutes.dashboard
        : AppRoutes.onboarding;

    return Obx(
      () => GetMaterialApp(
        title: 'My Expenses AI',
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        initialBinding: RootBinding(),
        getPages: AppPages.pages,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        defaultTransition: Transition.cupertino,
        translations: _FallbackTranslations(),
        locale: const Locale('ar'),
        fallbackLocale: const Locale('en'),
      ),
    );
  }
}

class _FallbackTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar': {'welcome': 'أهلًا بك'},
    'en': {'welcome': 'Welcome'},
  };
}
