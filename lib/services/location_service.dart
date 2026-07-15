// lib/services/location_service.dart
import 'dart:async';

import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Timer? _timer;
  static bool _updating = false;

  static void startPeriodicUpdate() {
    _timer?.cancel();
    unawaited(_updateOnce(isOnline: true));
    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_updateOnce(isOnline: true)),
    );
  }

  static void stopPeriodicUpdate() {
    _timer?.cancel();
    _timer = null;
    unawaited(_sendToServer(isOnline: false));
  }

  static Future<void> _updateOnce({required bool isOnline}) async {
    if (_updating) return;
    _updating = true;
    try {
      final pos = await _resolvePosition();
      if (pos == null) {
        if (isOnline) {
          debugPrint(
            'LocationService: no position available (GPS off, denied, or timeout)',
          );
          // ยังต้องตั้ง isOnline ไว้ ไม่เช่นนั้น FCM เคสด่วนจะไม่ถูกส่ง
          await _sendToServer(isOnline: true);
        } else {
          await _sendToServer(isOnline: false);
        }
        return;
      }

      await UserProfileStore.instance.updateLocation(
        lat: pos.latitude,
        lng: pos.longitude,
      );
      await _sendToServer(isOnline: isOnline, pos: pos);
    } catch (e) {
      debugPrint('LocationService update error: $e');
    } finally {
      _updating = false;
    }
  }

  static Future<Position?> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.whileInUse &&
        perm != LocationPermission.always) {
      return null;
    }

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 5) return lastKnown;
      }
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 12),
      );
    } on TimeoutException {
      return lastKnown;
    } catch (e) {
      debugPrint('LocationService getCurrentPosition: $e');
      return lastKnown;
    }
  }

  static Future<void> _sendToServer({
    required bool isOnline,
    Position? pos,
  }) async {
    await UserProfileStore.instance.load();
    final code = UserProfileStore.instance.code;
    if (code.isEmpty) return;

    final lat = pos?.latitude ?? UserProfileStore.instance.lastLat;
    final lng = pos?.longitude ?? UserProfileStore.instance.lastLong;

    await postDio('$server/m/register/updateLocation', {
      'code': code,
      'lastLat': lat,
      'lastLng': lng,
      'isOnline': isOnline,
    });
  }
}
