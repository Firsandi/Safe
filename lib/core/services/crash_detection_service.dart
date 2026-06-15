import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service untuk deteksi tabrakan kendaraan menggunakan accelerometer.
///
/// Algoritma deteksi:
/// 1. Threshold G-force tinggi (4G minimum)
/// 2. Sustained impact: harus terdeteksi 3 pembacaan berturut-turut
/// 3. Sudden stillness: setelah impact, cek apakah gerakan berhenti mendadak
/// 4. Cooldown 30 detik setelah trigger (agar tidak spam)
/// 5. Pattern filtering: abaikan guncangan vertikal saja (HP jatuh)
class CrashDetectionService {
  // === THRESHOLD CONFIGURATION ===
  static const double _impactThresholdG = 8.0; // Kalibrasi: Dinaikkan ke 8.0G agar tidak mudah terpicu oleh guncangan kecil / jatuh biasa
  static const double _gravityMs2 = 9.81; // 1G dalam m/s²
  static const double _impactThresholdMs2 = _impactThresholdG * _gravityMs2; // ~78.48 m/s²
  static const int _sustainedImpactCount = 3; // Jumlah pembacaan berturut yang harus melebihi threshold
  static const double _stillnessThresholdMs2 = 1.5; // Kalibrasi: Diperketat menjadi 1.5 m/s² agar deteksi berhenti total pasca benturan lebih presisi
  static const Duration _stillnessCheckDelay = Duration(seconds: 2); // Delay sebelum cek stillness
  static const Duration _stillnessCheckWindow = Duration(milliseconds: 500); // Window untuk cek stillness
  static const Duration _cooldownDuration = Duration(seconds: 30); // Cooldown setelah trigger
  static const double _horizontalRatio = 0.3; // Minimal rasio komponen horizontal vs total

  // === STATE ===
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int _consecutiveImpactCount = 0;
  DateTime? _lastTriggerTime;
  bool _isCheckingStillness = false;
  bool _isActive = false;

  // Callback saat crash terdeteksi
  VoidCallback? onCrashDetected;

  /// Memulai monitoring sensor accelerometer.
  void start() {
    if (_isActive) return;
    _isActive = true;
    _consecutiveImpactCount = 0;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20 Hz sampling
    ).listen(_onAccelerometerEvent);

    debugPrint('[CrashDetection] Service started — threshold: ${_impactThresholdG}G');
  }

  /// Menghentikan monitoring sensor.
  void stop() {
    _isActive = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _consecutiveImpactCount = 0;
    debugPrint('[CrashDetection] Service stopped');
  }

  /// Memulai cooldown (dipanggil setelah crash terdeteksi atau user cancel countdown).
  void startCooldown() {
    _lastTriggerTime = DateTime.now();
    _consecutiveImpactCount = 0;
    debugPrint('[CrashDetection] Cooldown started — ${_cooldownDuration.inSeconds}s');
  }

  /// Cek apakah sedang dalam cooldown period.
  bool get _isInCooldown {
    if (_lastTriggerTime == null) return false;
    return DateTime.now().difference(_lastTriggerTime!) < _cooldownDuration;
  }

  /// Handler untuk setiap pembacaan accelerometer.
  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isActive || _isInCooldown || _isCheckingStillness) return;

    // Hitung total acceleration (termasuk gravity ~9.81 m/s²)
    final totalAccel = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Hitung komponen horizontal (x dan y)
    final horizontalAccel = sqrt(event.x * event.x + event.y * event.y);

    // Hitung acceleration deviation dari gravity (seharusnya ~9.81 saat diam)
    final accelDeviation = (totalAccel - _gravityMs2).abs();

    // Cek apakah ini impact yang signifikan
    if (accelDeviation >= _impactThresholdMs2) {
      // Filter: pastikan ada komponen horizontal yang signifikan
      // (HP jatuh dari meja = mostly vertikal, tabrakan = ada horizontal)
      final horizontalContribution = horizontalAccel / totalAccel;

      if (horizontalContribution >= _horizontalRatio) {
        _consecutiveImpactCount++;
        debugPrint(
          '[CrashDetection] Impact #$_consecutiveImpactCount — '
          'deviation: ${accelDeviation.toStringAsFixed(1)} m/s² '
          '(${(accelDeviation / _gravityMs2).toStringAsFixed(1)}G) '
          'horizontal: ${(horizontalContribution * 100).toStringAsFixed(0)}%',
        );
      } else {
        // Mostly vertical — kemungkinan HP jatuh, reset counter
        _consecutiveImpactCount = 0;
      }
    } else {
      // Tidak ada impact, reset counter
      _consecutiveImpactCount = 0;
    }

    // Cek apakah sustained impact tercapai
    if (_consecutiveImpactCount >= _sustainedImpactCount) {
      _consecutiveImpactCount = 0;
      debugPrint('[CrashDetection] Sustained impact detected! Checking for stillness...');
      _checkSuddenStillness();
    }
  }

  /// Cek sudden stillness setelah impact terdeteksi.
  /// Tabrakan nyata: impact keras → langsung berhenti (kendaraan berhenti mendadak).
  /// False positive (jalan berlubang, olahraga): gerakan berlanjut.
  Future<void> _checkSuddenStillness() async {
    _isCheckingStillness = true;

    // Tunggu sebentar setelah impact
    await Future.delayed(_stillnessCheckDelay);

    if (!_isActive) {
      _isCheckingStillness = false;
      return;
    }

    // Kumpulkan pembacaan selama window period
    final readings = <double>[];
    StreamSubscription<AccelerometerEvent>? stillnessSubscription;

    stillnessSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      final totalAccel = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      // Deviation dari gravity = seberapa banyak gerakan
      readings.add((totalAccel - _gravityMs2).abs());
    });

    // Tunggu selama window period
    await Future.delayed(_stillnessCheckWindow);
    await stillnessSubscription.cancel();

    _isCheckingStillness = false;

    if (readings.isEmpty || !_isActive) return;

    // Hitung rata-rata deviation dari gravity
    final avgDeviation = readings.reduce((a, b) => a + b) / readings.length;

    debugPrint(
      '[CrashDetection] Stillness check — avg deviation: ${avgDeviation.toStringAsFixed(2)} m/s² '
      '(threshold: $_stillnessThresholdMs2 m/s²)',
    );

    if (avgDeviation <= _stillnessThresholdMs2) {
      // Sudden stillness confirmed → kemungkinan besar tabrakan nyata
      debugPrint('[CrashDetection] ✅ CRASH DETECTED — sudden stillness confirmed!');
      startCooldown();
      onCrashDetected?.call();
    } else {
      debugPrint('[CrashDetection] ❌ Not a crash — movement continues after impact');
    }
  }

  /// Dispose service dan bersihkan resources.
  void dispose() {
    stop();
    onCrashDetected = null;
  }
}
