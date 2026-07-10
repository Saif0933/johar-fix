import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  int _avatarIndex = 0;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  int get avatarIndex => _avatarIndex;

  AuthProvider() {
    // Connect api client unauthorized callback to logout trigger
    ApiClient.instance.onUnauthorized = () {
      _handleSessionExpiry();
    };
    checkAuthStatus();
  }

  // Check if token exists in local storage and verify it against server
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.instance.getUserToken();
      if (token != null) {
        final response = await ApiClient.instance.get('/customer/profile');
        if (response.data != null && response.data['success'] == true) {
          _profile = ProfileModel.fromJson(response.data['data']);
          _isAuthenticated = true;
          
          // Load avatar index
          final savedAvatar = await StorageService.instance.read('userAvatarIndex');
          if (savedAvatar != null) {
            _avatarIndex = int.tryParse(savedAvatar) ?? 0;
          }
        } else {
          await logout();
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('CheckAuthStatus error (falling back to offline status): $e');
      // If we have a cached user doc, we can restore offline
      final cachedUser = await StorageService.instance.getUserDoc();
      final token = await StorageService.instance.getUserToken();
      if (cachedUser != null && token != null) {
        try {
          _profile = ProfileModel.fromJson(jsonDecode(cachedUser));
          _isAuthenticated = true;
        } catch (_) {
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request OTP from server
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post('/customer/send-otp', data: {'phone': phone});
      return response.data != null && response.data['success'] == true;
    } catch (e) {
      debugPrint('sendOtp error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend OTP from server
  Future<bool> resendOtp(String phone) async {
    try {
      final response = await ApiClient.instance.post('/customer/resend-otp', data: {'phone': phone});
      return response.data != null && response.data['success'] == true;
    } catch (e) {
      debugPrint('resendOtp error: $e');
      return false;
    }
  }

  // Verify OTP and capture session credentials
  // Returns map containing success status and whether the user is new
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post('/customer/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });

      if (response.data != null && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final userJson = response.data['user'];
        final isNewUser = response.data['is_new_user'] == true;

        await StorageService.instance.saveUserToken(token);
        await StorageService.instance.saveUserDoc(jsonEncode(userJson));

        _profile = ProfileModel.fromJson(userJson);
        _isAuthenticated = true;
        
        return {'success': true, 'isNewUser': isNewUser};
      }
      return {'success': false, 'message': 'Invalid OTP'};
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      return {'success': false, 'message': 'Verification failed'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile details
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.put('/customer/profile', data: updates);
      if (response.data != null && response.data['success'] == true) {
        _profile = ProfileModel.fromJson(response.data['data']);
        await StorageService.instance.saveUserDoc(jsonEncode(_profile!.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save profile Avatar Index
  Future<bool> saveAvatarIndex(int index) async {
    try {
      await StorageService.instance.write('userAvatarIndex', index.toString());
      _avatarIndex = index;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('saveAvatarIndex error: $e');
      return false;
    }
  }

  // System session expiry trigger (clears storage but avoids notifyListeners loops)
  void _handleSessionExpiry() {
    _profile = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Regular logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.instance.clearAll();
    } catch (e) {
      debugPrint('logout clearStorage error: $e');
    }

    _profile = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
}
