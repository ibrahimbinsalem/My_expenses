import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../services/security_service.dart';

class SecurityController extends GetxController
    with WidgetsBindingObserver {
  SecurityController(this._service);

  final SecurityService _service;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final isLockEnabled = false.obs;
  final isOverlayVisible = false.obs;
  final isBiometricAvailable = false.obs;
  final biometricsEnabled = false.obs;
  bool _isAutoPrompting = false;
  String? lastBiometricError;
  DateTime? _lastUnlockAt;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    isLockEnabled.value = _service.isLockEnabled;
    biometricsEnabled.value = _service.biometricsEnabled;
    _initializeBiometrics();
    if (isLockEnabled.value) {
      lockNow();
    }
  }

  Future<void> _initializeBiometrics() async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      final hasHardware = deviceSupported && (canCheck || types.isNotEmpty);
      final available = hasHardware && types.isNotEmpty;
      isBiometricAvailable.value = available;
      if (!available) {
        biometricsEnabled.value = false;
        await _service.setBiometricsEnabled(false);
      } else {
        biometricsEnabled.value =
            _service.biometricsEnabled && isLockEnabled.value;
      }
    } catch (e) {
      lastBiometricError = '$e';
      debugPrint('Biometric init error: $e');
      isBiometricAvailable.value = false;
      biometricsEnabled.value = false;
      await _service.setBiometricsEnabled(false);
    }
  }

  Future<void> refreshBiometricStatus() async {
    await _initializeBiometrics();
  }

  Future<bool> enableLock(String pin) async {
    if (pin.length < 4) return false;
    await _service.enableLock(pin);
    isLockEnabled.value = true;
    lockNow();
    return true;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    if (!_service.verifyPin(currentPin)) return false;
    if (newPin.length < 4) return false;
    await _service.changePin(newPin);
    return true;
  }

  Future<bool> disableLock(String currentPin) async {
    if (!_service.verifyPin(currentPin)) return false;
    await _service.disableLock();
    isLockEnabled.value = false;
    isOverlayVisible.value = false;
    biometricsEnabled.value = false;
    return true;
  }

  Future<bool> unlock(String pin) async {
    final isValid = _service.verifyPin(pin);
    if (isValid) {
      _markUnlocked();
    }
    return isValid;
  }

  void lockNow() {
    if (isLockEnabled.value) {
      if (_isRecentlyUnlocked()) return;
      isOverlayVisible.value = true;
      _tryBiometricUnlock();
    }
  }

  Future<void> _tryBiometricUnlock() async {
    if (!biometricsEnabled.value ||
        !isBiometricAvailable.value ||
        _isAutoPrompting) {
      return;
    }
    _isAutoPrompting = true;
    final success = await authenticateWithBiometrics();
    _isAutoPrompting = false;
    if (success) {
      isOverlayVisible.value = false;
    }
  }

  Future<bool> toggleBiometrics(bool enable) async {
    if (!isLockEnabled.value) return false;
    if (enable) {
      if (!isBiometricAvailable.value) return false;
      await _service.setBiometricsEnabled(true);
      biometricsEnabled.value = true;
      return true;
    } else {
      await _service.setBiometricsEnabled(false);
      biometricsEnabled.value = false;
      await _localAuth.stopAuthentication();
      _lastUnlockAt = null;
      return true;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!biometricsEnabled.value || !isBiometricAvailable.value) return false;
    final result = await _authenticateInternal(updateOverlay: true);
    await _service.setLastBiometricUnlockSuccessful(result);
    return result;
  }

  Future<bool> authenticateForSetup() async {
    if (!isBiometricAvailable.value) {
      lastBiometricError = 'biometric not available';
      return false;
    }
    return _authenticateInternal(updateOverlay: false);
  }

  Future<bool> _authenticateInternal({required bool updateOverlay}) async {
    try {
      lastBiometricError = null;
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'securityBiometricReason'.tr,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate && updateOverlay) {
        _markUnlocked();
      } else {
        lastBiometricError ??= 'authentication returned false';
      }
      return didAuthenticate;
    } catch (e) {
      lastBiometricError = '$e';
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  void _markUnlocked() {
    _lastUnlockAt = DateTime.now();
    isOverlayVisible.value = false;
  }

  bool _isRecentlyUnlocked() {
    if (_lastUnlockAt == null) return false;
    return DateTime.now().difference(_lastUnlockAt!) <
        const Duration(seconds: 3);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _service.updateBackgroundTimestamp();
    } else if (state == AppLifecycleState.resumed) {
      lockNow();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
