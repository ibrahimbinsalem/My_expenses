import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../core/controllers/security_controller.dart';

class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({required this.controller, super.key});

  final SecurityController controller;

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> {
  final TextEditingController _pinController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      if (!widget.controller.isOverlayVisible.value ||
          !widget.controller.isLockEnabled.value) {
        return const SizedBox.shrink();
      }
      return Positioned.fill(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF21A2A3A), Color(0xF20B101A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'securityOverlayTitle'.tr,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'securityOverlaySubtitle'.tr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_canUseBiometrics) ...[
                        _BiometricPrompt(
                          isProcessing: _isProcessing,
                          onAuthenticate: _unlockWithBiometric,
                          errorText: _error,
                        ),
                      ] else ...[
                        _PinInputField(
                          controller: _pinController,
                          errorText: _error,
                          onChanged: (value) {
                            if (_error != null && value.isNotEmpty) {
                              setState(() => _error = null);
                            }
                          },
                          onCompleted: () {
                            if (!_isProcessing) {
                              _unlock();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isProcessing ? null : _unlock,
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text('securityOverlayButton'.tr),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  bool get _canUseBiometrics =>
      widget.controller.biometricsEnabled.value &&
      widget.controller.isBiometricAvailable.value;

  Future<void> _unlock() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    final success = await widget.controller.unlock(_pinController.text.trim());
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (!success) {
        _error = 'securityOverlayError'.tr;
      } else {
        _pinController.clear();
      }
    });
  }

  Future<void> _unlockWithBiometric() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    final success = await widget.controller.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _error = success ? null : 'securityOverlayError'.tr;
    });
  }
}

class _BiometricPrompt extends StatelessWidget {
  const _BiometricPrompt({
    required this.isProcessing,
    required this.onAuthenticate,
    this.errorText,
  });

  final bool isProcessing;
  final VoidCallback onAuthenticate;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          child: Icon(
            Icons.fingerprint,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text('securityBiometricButton'.tr, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (errorText != null)
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          Text(
            'securityBiometricHint'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isProcessing ? null : onAuthenticate,
            icon: const Icon(Icons.fingerprint),
            label: isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text('securityBiometricButton'.tr),
          ),
        ),
      ],
    );
  }
}

class _PinInputField extends StatelessWidget {
  const _PinInputField({
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.2 : 0.8,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
    );
    return Pinput(
      controller: controller,
      length: 6,
      obscureText: true,
      defaultPinTheme: baseTheme,
      focusedPinTheme: baseTheme.copyWith(
        decoration: baseTheme.decoration?.copyWith(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      errorPinTheme: baseTheme.copyWith(
        decoration: baseTheme.decoration?.copyWith(
          border: Border.all(color: theme.colorScheme.error, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      showCursor: true,
      errorText: errorText,
      forceErrorState: errorText != null,
      errorTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
      onChanged: onChanged,
      onCompleted: (_) => onCompleted?.call(),
      autofocus: true,
    );
  }
}
