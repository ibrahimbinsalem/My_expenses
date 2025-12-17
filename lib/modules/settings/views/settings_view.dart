import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_expenses/core/services/backup_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/api_keys.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(controller: controller),
          _ThemeCard(controller: controller),
          _TextScaleCard(controller: controller),
          _BudgetCard(controller: controller),
          _LanguageCard(controller: controller),
          _CurrenciesCard(controller: controller),
          _AiSettingsCard(controller: controller),
          _ReminderCard(controller: controller),
          _SecurityBackupCard(controller: controller),
          const _BillBookLink(),
          const _RecurringTasksLink(),
          const _HelpCard(),
          const _NotificationsLink(),
          const _CategoryLink(),
        ],
      ),
    );
  }
}

class _PinChangeResult {
  const _PinChangeResult({required this.currentPin, required this.newPin});

  final String currentPin;
  final String newPin;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          children: children,
        ),
      ),
    );
  }
}

class _SecurityBackupCard extends StatelessWidget {
  const _SecurityBackupCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final lockEnabled = controller.appLockEnabled.value;
      final backups = controller.backups;
      final lastBackup = backups.isNotEmpty ? backups.first : null;
      final biometricSupported =
          controller.securityController.isBiometricAvailable.value;
      final biometricEnabled =
          controller.securityController.biometricsEnabled.value;
      return _SettingsSection(
        icon: Icons.shield_outlined,
        title: 'securityCardTitle'.tr,
        subtitle: 'securityCardSubtitle'.tr,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: lockEnabled,
            title: Text('securityLockToggle'.tr),
            subtitle: Text('securityLockHint'.tr),
            onChanged: (value) => _handleLockToggle(context, value),
          ),
          if (biometricSupported)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: biometricEnabled,
              title: Text('securityBiometricToggle'.tr),
              subtitle: Text('securityBiometricHint'.tr),
              onChanged: lockEnabled
                  ? (value) => _handleBiometricToggle(context, value)
                  : null,
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'securityBiometricUnavailable'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ),
          if (biometricSupported)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'securityBiometricPermissionsTitle'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PermissionBadge(
                        icon: Icons.fingerprint,
                        title: 'securityBiometricPermissionBiometric'.tr,
                        code: 'USE_BIOMETRIC',
                      ),
                      _PermissionBadge(
                        icon: Icons.touch_app_outlined,
                        title: 'securityBiometricPermissionFingerprint'.tr,
                        code: 'USE_FINGERPRINT',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: lockEnabled
                ? Column(
                    key: const ValueKey('lock-enabled'),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _handleChangePin(context),
                              icon: const Icon(Icons.password_rounded),
                              label: Text('securityChangePin'.tr),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleDisableLock(context),
                              icon: const Icon(Icons.lock_open_outlined),
                              label: Text('securityDisableButton'.tr),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: controller.lockAppNow,
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: Text('securityLockNow'.tr),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    key: const ValueKey('lock-disabled'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'securityLockHelper'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ),
          ),
          const Divider(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: controller.isExportingBackup.value
                    ? null
                    : () => _exportBackup(context),
                icon: const Icon(Icons.file_download_outlined),
                label: controller.isExportingBackup.value
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text('backupCreateAction'.tr),
              ),
              OutlinedButton.icon(
                onPressed: controller.backups.isEmpty
                    ? null
                    : () => _showBackupsSheet(context),
                icon: const Icon(Icons.history_outlined),
                label: Text('backupRestoreAction'.tr),
              ),
              OutlinedButton.icon(
                onPressed: controller.backups.isEmpty
                    ? null
                    : () => _shareLatestBackup(context),
                icon: const Icon(Icons.ios_share),
                label: Text('backupShareAction'.tr),
              ),
              OutlinedButton.icon(
                onPressed: controller.backups.isEmpty
                    ? null
                    : () => _showBackupHistory(context),
                icon: const Icon(Icons.library_books_outlined),
                label: Text('backupHistoryAction'.tr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              lastBackup == null
                  ? 'backupNone'.tr
                  : 'backupLast'.trParams({
                      'date': controller.formatBackupDate(lastBackup.createdAt),
                      'size': lastBackup.formattedSize,
                    }),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          const Divider(height: 32),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: controller.autoBackupEnabled.value,
            title: Text('backupAutoToggle'.tr),
            subtitle: Text('backupAutoHint'.tr),
            onChanged: (value) => controller.toggleAutoBackup(value),
          ),
          if (controller.autoBackupEnabled.value)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: controller.autoBackupFrequency.value,
                    decoration: InputDecoration(
                      labelText: 'backupAutoFrequencyLabel'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text('backupAutoFrequency.daily'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('backupAutoFrequency.weekly'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('backupAutoFrequency.monthly'.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateAutoBackupFrequency(value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      controller.lastAutoBackup.value == null
                          ? 'backupAutoNever'.tr
                          : 'backupAutoLast'.trParams({
                              'date': DateFormat(
                                'dd MMM yyyy • HH:mm',
                              ).format(controller.lastAutoBackup.value!),
                            }),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Future<void> _handleLockToggle(BuildContext context, bool value) async {
    if (value) {
      final pin = await _showPinCreationSheet(
        context,
        title: 'securityLockSetupTitle'.tr,
      );
      if (pin == null) return;
      final success = await controller.enableAppLock(pin);
      if (success) {
        Get.snackbar('common.success'.tr, 'securityLockEnabled'.tr);
      } else {
        Get.snackbar('common.alert'.tr, 'securityPinError'.tr);
      }
    } else {
      final pin = await _showPinEntrySheet(
        context,
        title: 'securityLockDisableTitle'.tr,
      );
      if (pin == null) return;
      final success = await controller.disableAppLock(pin);
      if (!success) {
        Get.snackbar('common.alert'.tr, 'securityPinError'.tr);
      }
    }
  }

  Future<void> _handleChangePin(BuildContext context) async {
    final result = await _showPinChangeSheet(
      context,
      title: 'securityChangePin'.tr,
    );
    if (result == null) return;
    final success = await controller.changeAppLockPin(
      result.currentPin,
      result.newPin,
    );
    if (success) {
      Get.snackbar('common.success'.tr, 'securityPinChanged'.tr);
    } else {
      Get.snackbar('common.alert'.tr, 'securityPinError'.tr);
    }
  }

  Future<void> _handleBiometricToggle(BuildContext context, bool value) async {
    if (value) {
      await controller.securityController.refreshBiometricStatus();
      if (!controller.securityController.isBiometricAvailable.value) {
        Get.snackbar('common.alert'.tr, 'securityBiometricEnrollHint'.tr);
        return;
      }
      final confirmed = await controller.securityController
          .authenticateForSetup();
      if (!confirmed) {
        debugPrint(
          'Biometric confirmation failed while enabling lock: '
          '${controller.securityController.lastBiometricError}',
        );
        Get.snackbar('common.alert'.tr, 'securityBiometricConfirmFailed'.tr);
        return;
      }
    }
    final success = await controller.toggleBiometricLock(value);
    if (!success) {
      Get.snackbar('common.alert'.tr, 'securityBiometricUnavailable'.tr);
    } else if (value) {
      Get.snackbar('common.success'.tr, 'securityBiometricEnabled'.tr);
    }
  }

  Future<void> _handleDisableLock(BuildContext context) async {
    await _handleLockToggle(context, false);
  }

  Future<String?> _promptBackupName(BuildContext context) async {
    String name = '';
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            void submit() {
              final value = name.trim();
              if (value.isEmpty) {
                setState(() => errorText = 'backupNameRequired'.tr);
                return;
              }
              Navigator.of(dialogContext).pop(value);
            }

            return AlertDialog(
              title: Text('backupNameTitle'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('backupNameDescription'.tr),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    onChanged: (value) {
                      name = value;
                      if (errorText != null && errorText!.isNotEmpty) {
                        setState(() => errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'backupNameLabel'.tr,
                      hintText: 'backupNameHint'.tr,
                      helperText: 'backupNameHelper'.tr,
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('common.cancel'.tr),
                ),
                FilledButton(
                  onPressed: submit,
                  child: Text('common.save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  Future<void> _exportBackup(BuildContext context) async {
    final label = await _promptBackupName(context);
    if (label == null) return;
    final entry = await controller.exportBackup(label: label);
    if (entry != null) {
      Get.snackbar(
        'common.success'.tr,
        'backupCreateSuccess'.trParams({'path': entry.path}),
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar('common.alert'.tr, 'backupCreateError'.tr);
    }
  }

  Future<void> _showBackupsSheet(BuildContext context) async {
    await controller.refreshBackups();
    if (controller.backups.isEmpty) {
      Get.snackbar('common.alert'.tr, 'backupNone'.tr);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Obx(() {
          final entries = controller.backups;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'backupListTitle'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_open),
                  title: Text('backupRestoreCustom'.tr),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _restoreCustomBackup(context);
                  },
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.storage_rounded),
                            title: Text(entry.name),
                            subtitle: Text(
                              '${controller.formatBackupDate(entry.createdAt)} • ${entry.formattedSize}',
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'backupOpenFolderTooltip'.tr,
                                  icon: const Icon(Icons.folder_open_outlined),
                                  onPressed: () =>
                                      _openBackupFolder(context, entry),
                                ),
                                IconButton(
                                  tooltip: 'backupShareEntryTooltip'.tr,
                                  icon: const Icon(Icons.ios_share),
                                  onPressed: () =>
                                      _shareBackupEntry(context, entry),
                                ),
                                TextButton(
                                  onPressed: controller.isRestoringBackup.value
                                      ? null
                                      : () async {
                                          final success = await controller
                                              .restoreBackup(entry);
                                          if (!context.mounted) return;
                                          if (success) {
                                            Get.back();
                                            Get.snackbar(
                                              'common.success'.tr,
                                              'backupRestoreSuccess'.tr,
                                            );
                                          } else {
                                            Get.snackbar(
                                              'common.alert'.tr,
                                              'backupRestoreError'.tr,
                                            );
                                          }
                                        },
                                  child: controller.isRestoringBackup.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('backupRestoreButton'.tr),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: entries.length,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _showBackupHistory(BuildContext context) async {
    await controller.refreshBackups();
    if (controller.backups.isEmpty) {
      Get.snackbar('common.alert'.tr, 'backupNone'.tr);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Obx(() {
          final history = controller.backups;
          final theme = Theme.of(context);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    'backupHistoryTitle'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${controller.formatBackupDate(entry.createdAt)} • ${entry.formattedSize}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'backupPathLabel'.tr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  entry.path,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'backupOpenFolderTooltip'.tr,
                                      icon: const Icon(
                                        Icons.folder_open_outlined,
                                      ),
                                      onPressed: () =>
                                          _openBackupFolder(context, entry),
                                    ),
                                    IconButton(
                                      tooltip: 'backupShareEntryTooltip'.tr,
                                      icon: const Icon(Icons.ios_share),
                                      onPressed: () =>
                                          _shareBackupEntry(context, entry),
                                    ),
                                    IconButton(
                                      tooltip: 'backupDeleteAction'.tr,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: theme.colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          _confirmDeleteBackup(context, entry),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: history.length,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _shareLatestBackup(BuildContext context) async {
    await controller.refreshBackups();
    final latest = controller.backups.isEmpty ? null : controller.backups.first;
    if (latest == null) {
      Get.snackbar('common.alert'.tr, 'backupNone'.tr);
      return;
    }
    try {
      await Share.shareXFiles(
        [XFile(latest.path)],
        text: 'backupShareHint'.trParams({'name': latest.name}),
        subject: 'backupShareSubject'.tr,
      );
    } catch (e) {
      if (!context.mounted) return;
      Get.snackbar('common.alert'.tr, 'backupShareError'.tr);
    }
  }

  Future<void> _shareBackupEntry(
    BuildContext context,
    BackupEntry entry,
  ) async {
    try {
      await Share.shareXFiles(
        [XFile(entry.path)],
        text: 'backupShareHint'.trParams({'name': entry.name}),
        subject: 'backupShareSubject'.tr,
      );
    } catch (e) {
      debugPrint('Share backup error: $e');
      if (!context.mounted) return;
      Get.snackbar('common.alert'.tr, 'backupShareError'.tr);
    }
  }

  Future<void> _openBackupFolder(
    BuildContext context,
    BackupEntry entry,
  ) async {
    final directoryPath = File(entry.path).parent.path;
    final result = await OpenFilex.open(directoryPath);
    if (result.type != ResultType.done) {
      debugPrint('Open backup folder error: ${result.message}');
      if (!context.mounted) return;
      Get.snackbar('common.alert'.tr, 'backupOpenFolderError'.tr);
    }
  }

  Future<void> _confirmDeleteBackup(
    BuildContext context,
    BackupEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('backupDeleteAction'.tr),
          content: Text('backupDeleteConfirm'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('common.cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('common.confirm'.tr),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final success = await controller.deleteBackup(entry);
    if (!context.mounted) return;
    if (success) {
      Get.snackbar('common.success'.tr, 'backupDeleteSuccess'.tr);
    } else {
      Get.snackbar('common.alert'.tr, 'backupDeleteError'.tr);
    }
  }

  Future<void> _restoreCustomBackup(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'backupCustomPicker'.tr,
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return;
    final success = await controller.restoreBackupFromPath(path);
    if (!context.mounted) return;
    if (success) {
      Get.snackbar('common.success'.tr, 'backupRestoreSuccess'.tr);
    } else {
      Get.snackbar('common.alert'.tr, 'backupRestoreError'.tr);
    }
  }

  Future<String?> _showPinEntrySheet(
    BuildContext context, {
    required String title,
  }) async {
    final pinController = TextEditingController();
    String? error;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'securityPinLabel'.tr,
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (pinController.text.trim().length < 4) {
                          setState(() {
                            error = 'securityPinErrorShort'.tr;
                          });
                          return;
                        }
                        Navigator.of(context).pop(pinController.text.trim());
                      },
                      child: Text('common.confirm'.tr),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return result;
  }

  Future<String?> _showPinCreationSheet(
    BuildContext context, {
    required String title,
  }) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'securityPinLabel'.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'securityPinConfirmLabel'.tr,
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final pin = pinController.text.trim();
                        final confirm = confirmController.text.trim();
                        if (pin.length < 4) {
                          setState(() {
                            error = 'securityPinErrorShort'.tr;
                          });
                          return;
                        }
                        if (pin != confirm) {
                          setState(() {
                            error = 'securityPinMismatch'.tr;
                          });
                          return;
                        }
                        Navigator.of(context).pop(pin);
                      },
                      child: Text('common.confirm'.tr),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return result;
  }

  Future<_PinChangeResult?> _showPinChangeSheet(
    BuildContext context, {
    required String title,
  }) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    final result = await showModalBottomSheet<_PinChangeResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'securityPinCurrentLabel'.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'securityPinLabel'.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'securityPinConfirmLabel'.tr,
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final current = currentController.text.trim();
                        final pin = newController.text.trim();
                        final confirm = confirmController.text.trim();
                        if (pin.length < 4) {
                          setState(() {
                            error = 'securityPinErrorShort'.tr;
                          });
                          return;
                        }
                        if (pin != confirm) {
                          setState(() {
                            error = 'securityPinMismatch'.tr;
                          });
                          return;
                        }
                        Navigator.of(context).pop(
                          _PinChangeResult(currentPin: current, newPin: pin),
                        );
                      },
                      child: Text('common.confirm'.tr),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return result;
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.subtitleColor,
    this.iconBackground,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? iconBackground;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitleColor =
        titleColor ??
        theme.textTheme.titleMedium?.color ??
        theme.colorScheme.onSurface;
    final resolvedSubtitleColor =
        subtitleColor ?? theme.textTheme.bodySmall?.color ?? Colors.grey;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                iconBackground ??
                Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: resolvedTitleColor),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: resolvedSubtitleColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user.value;
      final avatarIndex = user?.avatarIndex ?? 0;
      final avatarEmoji = controller.avatarEmoji(avatarIndex);
      final avatarColor = controller.avatarColor(avatarIndex);
      final helperText = user == null
          ? 'settings.profile.complete'.tr
          : 'settings.profile.member_since'.trParams({
              'date': _formatDate(user.createdAt),
            });
      final theme = Theme.of(context);
      final gradientColors = theme.brightness == Brightness.dark
          ? const [Color(0xFF1F2C3A), Color(0xFF0D141C)]
          : const [Color(0xFF2F80ED), Color(0xFF56CCF2)];
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: avatarColor.withOpacity(0.18),
                    child: Text(
                      avatarEmoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'settings.profile.unknown'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showProfileEditor(context, controller, user),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _ProfileChip(
                  icon: Icons.person_outline,
                  label: user?.name ?? 'settings.profile.unknown'.tr,
                ),
                _ProfileChip(
                  icon: Icons.event_available_outlined,
                  label: helperText,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showProfileEditor(context, controller, user),
                child: Text('settings.profile.edit_button'.tr),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  const _PermissionBadge({
    required this.icon,
    required this.title,
    required this.code,
  });

  final IconData icon;
  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.7,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                code,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

void _showProfileEditor(
  BuildContext context,
  SettingsController controller,
  UserModel? user,
) {
  final nameController = TextEditingController(text: user?.name ?? '');
  var tempIndex = user?.avatarIndex ?? 0;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    'settings.profile.edit_title'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'settings.profile.name_label'.tr,
                      hintText: 'settings.profile.name_label'.tr,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'settings.profile.avatar_label'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'settings.profile.avatar_hint'.tr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemCount: controller.avatarEmojis.length,
                    itemBuilder: (context, index) {
                      final emoji = controller.avatarEmoji(index);
                      final color = controller.avatarColor(index);
                      final isSelected = tempIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => tempIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
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
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final success = await controller.updateUserProfile(
                              nameController.text,
                              tempIndex,
                            );
                            if (success) {
                              navigator.pop();
                              Get.snackbar(
                                'common.success'.tr,
                                'settings.profile.updated'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } else {
                              Get.snackbar(
                                'common.alert'.tr,
                                'settings.profile.name_required'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          child: Text('common.save'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() => nameController.dispose());
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.dark_mode,
      title: 'settings.theme.title'.tr,
      subtitle: 'settings.theme.subtitle'.tr,
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() {
                final isDark = controller.themeMode.value == ThemeMode.dark;
                return Text(
                  isDark ? 'Dark' : 'Light',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              }),
            ),
            Obx(() {
              final isDark = controller.themeMode.value == ThemeMode.dark;
              return Switch(value: isDark, onChanged: controller.toggleTheme);
            }),
          ],
        ),
      ],
    );
  }
}

class _TextScaleCard extends StatelessWidget {
  const _TextScaleCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scale = controller.textScale.value;
      return _SettingsSection(
        icon: Icons.format_size,
        title: 'settings.textscale.title'.tr,
        subtitle: 'settings.textscale.subtitle'.tr,
        children: [
          Row(
            children: [
              Text(
                'settings.textscale.preview'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(scale * 100).round()}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: scale,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            label: '${(scale * 100).round()}%',
            onChanged: controller.updateTextScaling,
          ),
          Text(
            'settings.textscale.helper'.tr,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );
    });
  }
}

class _CurrenciesCard extends StatelessWidget {
  const _CurrenciesCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currencies = controller.currencies;
      final preview = currencies.take(6).toList();
      final remaining = currencies.length - preview.length;
      final subtitle = currencies.isEmpty
          ? 'settings.currencies.subtitle'.tr
          : 'settings.currencies.count'.trParams({
              'count': currencies.length.toString(),
            });
      final theme = Theme.of(context);
      return _SettingsSection(
        icon: Icons.currency_exchange,
        title: 'settings.currencies.manage'.tr,
        subtitle: subtitle,
        children: [
          if (currencies.isEmpty)
            Text(
              'settings.currencies.empty_state'.tr,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preview
                  .map(
                    (currency) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.15,
                        ),
                        child: Text(
                          currency.code,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                      label: Text(currency.name),
                    ),
                  )
                  .toList(),
            ),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'settings.currencies.more_count'.trParams({
                    'count': remaining.toString(),
                  }),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    controller.loadCurrencies();
                    Get.toNamed(
                      AppRoutes.currencySettings,
                      arguments: {'autoPicker': true},
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text('settings.currencies.add_button'.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.loadCurrencies();
                    Get.toNamed(AppRoutes.currencySettings);
                  },
                  icon: const Icon(Icons.tune),
                  label: Text('settings.currencies.manage_button'.tr),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _AiSettingsCard extends StatelessWidget {
  const _AiSettingsCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.aiInsightsEnabled.value;
      final hasKey = ApiKeys.hasGeminiKey;
      final statusText = !hasKey
          ? 'settings.ai.key_missing'.tr
          : enabled
          ? 'settings.ai.status.enabled'.tr
          : 'settings.ai.status.disabled'.tr;
      final statusColor = !hasKey
          ? Colors.orange
          : enabled
          ? AppColors.success
          : Colors.grey;
      return _SettingsSection(
        icon: Icons.auto_awesome,
        title: 'settings.ai.title'.tr,
        subtitle: 'settings.ai.subtitle'.tr,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.ai.toggle_label'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(statusText, style: TextStyle(color: statusColor)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: (value) => controller.toggleAiInsights(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  hasKey ? Icons.vpn_key : Icons.warning_amber,
                  size: 18,
                  color: hasKey ? AppColors.success : Colors.orange,
                ),
                label: Text(
                  hasKey
                      ? 'settings.ai.key_ready'.tr
                      : 'settings.ai.key_missing'.tr,
                ),
              ),
              Chip(
                avatar: const Icon(Icons.wifi_tethering_off, size: 18),
                label: Text('settings.ai.offline_note'.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.insights),
              icon: const Icon(Icons.insights_outlined),
              label: Text('settings.ai.open_insights'.tr),
            ),
          ),
        ],
      );
    });
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.notificationsEnabled.value;
      return _SettingsSection(
        icon: Icons.notifications_active_outlined,
        title: 'settings.reminders.title'.tr,
        subtitle: 'settings.reminders.subtitle'.tr,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.reminders.toggle'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      enabled
                          ? 'settings.reminders.enabled'.tr
                          : 'settings.reminders.disabled'.tr,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.success
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: controller.toggleNotifications,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.alarm, size: 18),
                label: Text('settings.reminders.tip'.tr),
              ),
              Chip(
                avatar: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('settings.reminders.local'.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.remindersSettings),
              icon: const Icon(Icons.notifications),
              label: Text('settings.reminders.manage_button'.tr),
            ),
          ),
        ],
      );
    });
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    final tips = [
      'settings.help.tip_wallets'.tr,
      'settings.help.tip_goals'.tr,
      'settings.help.tip_backup'.tr,
    ];
    return _SettingsSection(
      icon: Icons.info_outline,
      title: 'settings.help.title'.tr,
      subtitle: 'settings.help.subtitle'.tr,
      children: [
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showHelpSheet(context),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text('settings.help.cta'.tr),
          ),
        ),
      ],
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final moreTips = [
          'settings.help.detail_wallets'.tr,
          'settings.help.detail_ai'.tr,
          'settings.help.detail_security'.tr,
          'settings.help.detail_support'.tr,
        ];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'settings.help.sheet_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'settings.help.sheet_desc'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ...moreTips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tip, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('common.ok'.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationsLink extends StatelessWidget {
  const _NotificationsLink();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.notifications,
      title: 'settings.notifications.center_title'.tr,
      subtitle: 'settings.notifications.center_subtitle'.tr,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.notifications),
            icon: const Icon(Icons.open_in_new),
            label: Text('settings.notifications.open_center'.tr),
          ),
        ),
      ],
    );
  }
}

class _CategoryLink extends StatelessWidget {
  const _CategoryLink();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.category_outlined,
      title: 'settings.categories.manage'.tr,
      subtitle: 'settings.categories.subtitle'.tr,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.categorySettings),
            icon: const Icon(Icons.tune),
            label: Text('settings.categories.manage_btn'.tr),
          ),
        ),
      ],
    );
  }
}

class _BillBookLink extends StatelessWidget {
  const _BillBookLink();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.receipt_long,
      title: 'billBook.sectionTitle'.tr,
      subtitle: 'billBook.sectionSubtitle'.tr,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.billBook),
            icon: const Icon(Icons.open_in_new),
            label: Text('billBook.open'.tr),
          ),
        ),
      ],
    );
  }
}

class _RecurringTasksLink extends StatelessWidget {
  const _RecurringTasksLink();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.repeat_on,
      title: 'tasks.sectionTitle'.tr,
      subtitle: 'tasks.sectionSubtitle'.tr,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.tasks),
            icon: const Icon(Icons.open_in_new),
            label: Text('tasks.open'.tr),
          ),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.translate,
      title: 'settings.language.title'.tr,
      subtitle: 'settings.language.subtitle'.tr,
      children: [
        Text(
          'settings.language.count'.trParams({
            'count': controller.supportedLocales.length.toString(),
          }),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final currentCode = controller.localeNotifier.value.languageCode;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: controller.supportedLocales.map((locale) {
              final code = locale.languageCode;
              final isSelected = code == currentCode;
              final label = code == 'ar'
                  ? 'settings.language.ar'.tr
                  : 'settings.language.en'.tr;
              return _LanguageOptionChip(
                label: label,
                code: code.toUpperCase(),
                isSelected: isSelected,
                onTap: () => controller.changeLanguage(locale),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _SettingsSection(
        icon: Icons.savings_outlined,
        title: 'settings.budget.title'.tr,
        subtitle: 'settings.budget.subtitle'.tr,
        children: [
          TextField(
            controller: controller.budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'settings.budget.input_label'.tr,
              suffixText: 'settings.budget.currency_suffix'.tr,
            ),
            onSubmitted: (_) => controller.submitBudgetFromText(),
          ),
          const SizedBox(height: 12),
          Slider(
            value: controller.monthlyBudget.value.clamp(500, 100000),
            min: 500,
            max: 100000,
            divisions: 100,
            label: controller.monthlyBudget.value.toStringAsFixed(0),
            onChanged: controller.updateMonthlyBudget,
          ),
          Text(
            'settings.budget.helper'.tr,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionChip extends StatelessWidget {
  const _LanguageOptionChip({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withOpacity(0.4);
    final foreground = isSelected
        ? theme.colorScheme.primary
        : theme.textTheme.bodyMedium?.color;
    final background = isSelected
        ? theme.colorScheme.primary.withOpacity(0.1)
        : theme.colorScheme.surfaceVariant.withOpacity(0.2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: foreground),
            ),
            const SizedBox(width: 6),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: foreground,
            ),
          ],
        ),
      ),
    );
  }
}
