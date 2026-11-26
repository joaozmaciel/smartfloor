import 'package:flutter/foundation.dart';

enum MeasurementUnit { meters, feet }

enum CaptureQuality { high, low }

class SettingsController extends ChangeNotifier {
  MeasurementUnit _measurementUnit = MeasurementUnit.meters;
  CaptureQuality _captureQuality = CaptureQuality.high;
  bool _automaticSaving = true;
  bool _notificationsEnabled = true;

  MeasurementUnit get measurementUnit => _measurementUnit;
  CaptureQuality get captureQuality => _captureQuality;
  bool get automaticSaving => _automaticSaving;
  bool get notificationsEnabled => _notificationsEnabled;

  void setMeasurementUnit(MeasurementUnit value) {
    if (_measurementUnit == value) return;
    _measurementUnit = value;
    notifyListeners();
  }

  void setCaptureQuality(CaptureQuality value) {
    if (_captureQuality == value) return;
    _captureQuality = value;
    notifyListeners();
  }

  void setAutomaticSaving(bool value) {
    if (_automaticSaving == value) return;
    _automaticSaving = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
  }
}
