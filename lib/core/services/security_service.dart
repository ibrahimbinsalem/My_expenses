import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SecurityService extends GetxService {
  static const _lockEnabledKey = 'security.lock.enabled';
  static const _pinKey = 'security.lock.pin';
  static const _lastBackgroundKey = 'security.lock.last_bg';
  static const _biometricKey = 'security.lock.biometric';

  final GetStorage _box = GetStorage();

  bool _lockEnabled = false;
  String? _storedPin;
  DateTime? _lastBackground;
  bool _biometricEnabled = false;

  Future<SecurityService> init() async {
    _lockEnabled = _box.read<bool>(_lockEnabledKey) ?? false;
    _storedPin = _box.read<String>(_pinKey);
    final lastBackground = _box.read<String>(_lastBackgroundKey);
    if (lastBackground != null) {
      _lastBackground = DateTime.tryParse(lastBackground);
    }
    _biometricEnabled = _box.read<bool>(_biometricKey) ?? false;
    return this;
  }

  bool get isLockEnabled => _lockEnabled;
  DateTime? get lastBackgroundAt => _lastBackground;
  bool get biometricsEnabled => _biometricEnabled;
  bool get lastBiometricUnlockSuccessful =>
      _box.read<bool>('security.lock.last_bio') ?? false;

  Future<void> enableLock(String pin) async {
    _lockEnabled = true;
    _storedPin = _encodePin(pin);
    await _box.write(_pinKey, _storedPin);
    await _box.write(_lockEnabledKey, true);
  }

  Future<void> changePin(String newPin) async {
    if (!_lockEnabled) return;
    _storedPin = _encodePin(newPin);
    await _box.write(_pinKey, _storedPin);
  }

  Future<void> disableLock() async {
    _lockEnabled = false;
    _storedPin = null;
    await _box.remove(_pinKey);
    await _box.write(_lockEnabledKey, false);
    await setBiometricsEnabled(false);
  }

  bool verifyPin(String pin) {
    if (!_lockEnabled || _storedPin == null) return false;
    return _encodePin(pin) == _storedPin;
  }

  Future<void> updateBackgroundTimestamp() async {
    final now = DateTime.now();
    _lastBackground = now;
    await _box.write(_lastBackgroundKey, now.toIso8601String());
  }

  Future<void> setBiometricsEnabled(bool value) async {
    _biometricEnabled = value;
    await _box.write(_biometricKey, value);
  }

  Future<void> setLastBiometricUnlockSuccessful(bool value) async {
    await _box.write('security.lock.last_bio', value);
  }

  String _encodePin(String pin) {
    final reversed = pin.split('').reversed.join();
    final salted = 'mx$reversed!';
    return base64UrlEncode(utf8.encode(salted));
  }
}
