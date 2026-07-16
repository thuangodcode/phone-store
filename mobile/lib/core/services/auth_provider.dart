import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/user_info.dart';

class AuthProvider extends ChangeNotifier {
  UserInfo? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserInfo? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;
  String get role => _currentUser?.role ?? '';

  AuthProvider() {
    initialize();
  }

  // Khôi phục session từ local storage khi khởi động ứng dụng
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedInLocal = await ApiService.isLoggedIn();
      if (isLoggedInLocal) {
        _currentUser = await ApiService.getSavedUser();
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print('Error initializing AuthProvider: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Đăng nhập tài khoản
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);
      if (result['success'] == true && result['user'] != null) {
        _currentUser = result['user'] as UserInfo;
      }
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi hệ thống: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đăng xuất tài khoản
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
      _currentUser = null;
    } catch (e) {
      print('Error logging out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Làm mới thông tin profile sau khi cập nhật
  Future<void> refreshProfile() async {
    try {
      final user = await ApiService.getSavedUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing profile: $e');
    }
  }
}
