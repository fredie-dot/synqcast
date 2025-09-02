import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all necessary permissions for the app
  static Future<bool> requestAllPermissions() async {
    try {
      debugPrint('Requesting all permissions...');
      
      // Define permissions based on platform
      final permissions = <Permission>[
        Permission.camera,
        Permission.microphone,
      ];

      // Only add mobile-specific permissions on mobile platforms
      if (!kIsWeb) {
        permissions.addAll([
          Permission.storage,
          Permission.manageExternalStorage,
          Permission.notification,
        ]);
      } else {
        // For web, only add notification permission
        permissions.add(Permission.notification);
      }

      // Request each permission
      final results = <Permission, PermissionStatus>{};
      
      for (final permission in permissions) {
        try {
          final status = await permission.request();
          results[permission] = status;
          debugPrint('Permission ${permission.toString()}: $status');
        } catch (e) {
          debugPrint('Error requesting permission ${permission.toString()}: $e');
          // For web, don't fail on unsupported permissions
          if (kIsWeb) {
            results[permission] = PermissionStatus.granted; // Assume granted for web
          } else {
            results[permission] = PermissionStatus.denied;
          }
        }
      }

      // Check if critical permissions are granted
      final criticalPermissions = [
        Permission.camera,
        Permission.microphone,
      ];

      bool allCriticalGranted = true;
      for (final permission in criticalPermissions) {
        final status = results[permission];
        if (status != null && !status.isGranted) {
          debugPrint('Critical permission not granted: ${permission.toString()}');
          allCriticalGranted = false;
        }
      }

      // Log permission summary
      debugPrint('Permission request summary:');
      results.forEach((permission, status) {
        debugPrint('  ${permission.toString()}: $status');
      });

      return allCriticalGranted;
    } catch (e) {
      debugPrint('Error in requestAllPermissions: $e');
      return false;
    }
  }

  /// Check if specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking permission ${permission.toString()}: $e');
      return false;
    }
  }

  /// Request specific permission
  static Future<bool> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      debugPrint('Permission ${permission.toString()}: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting permission ${permission.toString()}: $e');
      return false;
    }
  }

  /// Check if storage permissions are granted
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb) return true; // Web doesn't need storage permission
    
    try {
      final storageStatus = await Permission.storage.status;
      final manageStorageStatus = await Permission.manageExternalStorage.status;
      
      debugPrint('Storage permission: $storageStatus');
      debugPrint('Manage storage permission: $manageStorageStatus');
      
      return storageStatus.isGranted || manageStorageStatus.isGranted;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Request storage permissions specifically
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true; // Web doesn't need storage permission
    
    try {
      debugPrint('Requesting storage permissions...');
      
      // Request both storage permissions
      final storageStatus = await Permission.storage.request();
      final manageStorageStatus = await Permission.manageExternalStorage.request();
      
      debugPrint('Storage permission result: $storageStatus');
      debugPrint('Manage storage permission result: $manageStorageStatus');
      
      return storageStatus.isGranted || manageStorageStatus.isGranted;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Open app settings if permissions are permanently denied
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      debugPrint('Opened app settings');
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }
}
