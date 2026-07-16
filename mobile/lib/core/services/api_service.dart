import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/brand.dart';
import '../models/user_info.dart';
import '../models/cart.dart';
import '../models/wishlist.dart';

class ApiService {
  // ==================== CẤU HÌNH ĐƯỜNG DẪN MÁY CHỦ API ====================
  // Hướng dẫn cấu hình:
  // LỰA CHỌN 1: Dùng API deploy Render (máy chủ thật):
  static const String baseUrl = 'https://phone-store-api-4bah.onrender.com/api';
  
  // LỰA CHỌN 2: Dùng API chạy local dưới máy tính của bạn:
  // - Nếu chạy máy ảo Android (Android Emulator): Dùng 'http://10.0.2.2:5000/api' (hoặc port khác của dotnet)
  // - Nếu chạy máy ảo iOS (Simulator) hoặc Web: Dùng 'http://localhost:5000/api'
  // - Nếu chạy trên điện thoại thật: Dùng IP của máy tính, ví dụ: 'http://192.168.1.10:5000/api'
  // static const String baseUrl = 'http://localhost:5000/api';
  // =======================================================================

  // Key names for local storage
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Helper to get request headers with optional Bearer Token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Get auth token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get currently logged-in user profile from local storage
  static Future<UserInfo?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userKey);
      if (userJsonStr != null) {
        return UserInfo.fromJson(jsonDecode(userJsonStr));
      }
    } catch (_) {}
    return null;
  }

  // Authenticate user (Login)
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        final token = data['token'] ?? '';
        final userMap = data['user'];

        if (token.isNotEmpty && userMap != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_userKey, jsonEncode(userMap));
          
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Đăng nhập thành công!',
            'user': UserInfo.fromJson(userMap),
          };
        }
      }
      
      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại email/mật khẩu.',
      };
    } catch (e) {
      print('API Login Error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e. Hãy kiểm tra xem máy chủ API có đang chạy hoặc cấu hình đúng URL chưa.',
      };
    }
  }

  // Register new account
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'phone': phone,
        }),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        final token = data['token'] ?? '';
        final userMap = data['user'];

        if (token.isNotEmpty && userMap != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_userKey, jsonEncode(userMap));

          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Đăng ký tài khoản thành công!',
            'user': UserInfo.fromJson(userMap),
          };
        }
      }

      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Đăng ký thất bại. Vui lòng kiểm tra lại thông tin.',
      };
    } catch (e) {
      print('API Register Error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e. Hãy kiểm tra xem máy chủ API có đang chạy hoặc cấu hình đúng URL chưa.',
      };
    }
  }

  // Sign out user (Remove credentials)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Fetch all brands
  static Future<List<Brand>> getBrands() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/brands'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> brandList = jsonResponse['data'];
          return brandList.map((brandJson) => Brand.fromJson(brandJson)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch products with optional filtering by Brand or Search keyword
  static Future<List<Product>> getProducts({String? brandId, String? search}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/products?page=1&pageSize=100&includeInactive=false';
      if (brandId != null && brandId.isNotEmpty) {
        url += '&brandId=${Uri.encodeComponent(brandId)}';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final dynamic data = jsonResponse['data'];
          final List<dynamic> productList = data['items'] ?? [];
          return productList.map((productJson) => Product.fromJson(productJson)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lấy chi tiết sản phẩm theo ID
  static Future<Product?> getProductById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Product.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Get Product Detail Error: $e');
      return null;
    }
  }

  // Send message to AI Agent (Gemini)
  static Future<Map<String, dynamic>> sendAIChatMessage(String message, String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'response': 'Đã có lỗi xảy ra từ máy chủ (${response.statusCode}). Vui lòng thử lại.',
          'sessionId': sessionId,
        };
      }
    } catch (e) {
      return {
        'response': 'Không thể kết nối đến Trợ lý AI. Vui lòng kiểm tra lại mạng Internet.',
        'sessionId': sessionId,
      };
    }
  }

  // ==================== GIỎ HÀNG (CART API) ====================

  // Lấy giỏ hàng hiện tại
  static Future<Cart?> getCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Cart.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Get Cart Error: $e');
      return null;
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  static Future<Cart?> addToCart({
    required String productId,
    int quantity = 1,
    String storage = '',
    String color = '',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: headers,
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
          'storage': storage,
          'color': color,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Cart.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Add To Cart Error: $e');
      return null;
    }
  }

  // Cập nhật số lượng hoặc phân loại của item trong giỏ hàng
  static Future<Cart?> updateCartItem({
    required String productId,
    required int quantity,
    String storage = '',
    String color = '',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/cart/$productId'),
        headers: headers,
        body: jsonEncode({
          'quantity': quantity,
          'storage': storage,
          'color': color,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Cart.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Update Cart Item Error: $e');
      return null;
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng
  static Future<Cart?> removeFromCart(String productId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$productId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Cart.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Remove From Cart Error: $e');
      return null;
    }
  }

  // Xóa sạch giỏ hàng
  static Future<bool> clearCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/cart'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['success'] == true;
      }
      return false;
    } catch (e) {
      print('Clear Cart Error: $e');
      return false;
    }
  }

  // ==================== DANH SÁCH YÊU THÍCH (WISHLIST API) ====================

  // Lấy danh sách yêu thích
  static Future<Wishlist?> getWishlist() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Wishlist.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Get Wishlist Error: $e');
      return null;
    }
  }

  // Thêm sản phẩm vào danh sách yêu thích
  static Future<Wishlist?> addToWishlist(String productId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/$productId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Wishlist.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Add To Wishlist Error: $e');
      return null;
    }
  }

  // Xóa sản phẩm khỏi danh sách yêu thích
  static Future<Wishlist?> removeFromWishlist(String productId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/$productId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Wishlist.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Remove From Wishlist Error: $e');
      return null;
    }
  }

  // Cập nhật hồ sơ người dùng
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    required String avatar,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/Users/profile'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'address': address,
          'avatar': avatar,
        }),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final userMap = jsonResponse['data'];
        if (userMap != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(userMap));
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Cập nhật thông tin thành công!',
            'user': UserInfo.fromJson(userMap),
          };
        }
      }

      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Cập nhật thất bại. Vui lòng kiểm tra lại thông tin.',
      };
    } catch (e) {
      print('API Update Profile Error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e. Không thể cập nhật thông tin.',
      };
    }
  }

  // ==================== THANH TOÁN & ĐƠN HÀNG (CHECKOUT & ORDERS) ====================

  // Lấy thông tin voucher bằng mã code
  static Future<Map<String, dynamic>?> getVoucherByCode(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/code/$code'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get Voucher Error: $e');
      return null;
    }
  }

  // Tạo đơn hàng mới
  static Future<Map<String, dynamic>?> createOrder({
    required String receiverName,
    required String phone,
    required String shippingAddress,
    String note = '',
    required String paymentMethod,
    String? voucherCode,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: jsonEncode({
          'receiverName': receiverName,
          'phone': phone,
          'shippingAddress': shippingAddress,
          'note': note,
          'paymentMethod': paymentMethod,
          'voucherCode': voucherCode,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data') && jsonResponse['data'] != null) {
            return jsonResponse['data'];
          }
          return jsonResponse;
        }
      }
      return null;
    } catch (e) {
      print('Create Order Error: $e');
      return null;
    }
  }

  // Tạo liên kết thanh toán trực tuyến qua PayOS
  static Future<String?> createPaymentLink(String orderId) async {
    try {
      final headers = await _getHeaders();
      final returnUrl = 'https://phone-store-api-4bah.onrender.com/history';
      final cancelUrl = 'https://phone-store-api-4bah.onrender.com/history';
      final response = await http.post(
        Uri.parse('$baseUrl/payment/create-link/$orderId?returnUrl=$returnUrl&cancelUrl=$cancelUrl'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['success'] == true) {
            return data['data'];
          }
          if (data is String) {
            return data;
          }
        } catch (_) {
          return response.body;
        }
      }
      return null;
    } catch (e) {
      print('Create Payment Link Error: $e');
      return null;
    }
  }

  // Lấy danh sách bài đăng / tin tức khuyến mãi
  static Future<List<dynamic>> getArticles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/articles'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Get Articles Error: $e');
      return [];
    }
  }

  // Lấy lịch sử đơn hàng của người dùng
  static Future<List<dynamic>> getMyOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders?page=1&pageSize=50'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          if (data is Map && data.containsKey('items')) {
            return data['items'] as List<dynamic>;
          }
        }
      }
      return [];
    } catch (e) {
      print('Get My Orders Error: $e');
      return [];
    }
  }

  // Kiểm tra trạng thái thanh toán từ PayOS
  static Future<Map<String, dynamic>?> checkPaymentStatus(int orderCode) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/payment/check-status/$orderCode'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      }
      return null;
    } catch (e) {
      print('Check Payment Status Error: $e');
      return null;
    }
  }

  // ==================== CẤU HÌNH API DÀNH CHO STAFF / ADMIN ====================

  // Lấy dữ liệu Dashboard thống kê
  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Get Dashboard Stats Error: $e');
      return null;
    }
  }

  // Lấy danh sách tất cả các đơn hàng toàn hệ thống
  static Future<List<dynamic>> getAllOrders({String? status, String? paymentStatus}) async {
    try {
      final headers = await _getHeaders();
      var urlStr = '$baseUrl/orders?page=1&pageSize=100';
      if (status != null && status.isNotEmpty) {
        urlStr += '&status=$status';
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        urlStr += '&paymentStatus=$paymentStatus';
      }
      
      final response = await http.get(
        Uri.parse(urlStr),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          if (data is Map && data.containsKey('items')) {
            return data['items'] as List<dynamic>;
          }
        }
      }
      return [];
    } catch (e) {
      print('Get All Orders Error: $e');
      return [];
    }
  }

  // Cập nhật trạng thái đơn hàng (Staff / Admin)
  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } catch (e) {
      print('Update Order Status Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Cập nhật trạng thái thanh toán đơn hàng (Staff / Admin)
  static Future<Map<String, dynamic>> updateOrderPaymentStatus(String orderId, String paymentStatus) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/payment-status'),
        headers: headers,
        body: jsonEncode({'status': paymentStatus}),
      );
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } catch (e) {
      print('Update Payment Status Error: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Lấy chi tiết đơn hàng kèm Audit Log
  static Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Get Order Detail Error: $e');
      return null;
    }
  }

  // Lấy session chat active của Customer (nếu chưa có tự động tạo mới)
  static Future<Map<String, dynamic>?> getActiveChatSession() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/session/active'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Get Active Chat Session Error: $e');
      return null;
    }
  }

  // Lấy danh sách các session chat hiện tại (Staff / Admin)
  static Future<List<dynamic>> getChatSessions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Get Chat Sessions Error: $e');
      return [];
    }
  }

  // Phân công Staff hỗ trợ session chat
  static Future<Map<String, dynamic>?> assignStaffToSession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/sessions/$sessionId/assign'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Assign Staff Error: $e');
      return null;
    }
  }

  // Lấy lịch sử tin nhắn của một phiên chat
  static Future<List<dynamic>> getChatMessages(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages/$sessionId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Get Chat Messages Error: $e');
      return [];
    }
  }

  // Gửi tin nhắn trong phiên chat
  static Future<Map<String, dynamic>?> sendChatMessage(String sessionId, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/messages/$sessionId'),
        headers: headers,
        body: jsonEncode(content),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Send Chat Message Error: $e');
      return null;
    }
  }

  // Admin: Lấy danh sách người dùng
  static Future<List<dynamic>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Admin: Get Users Error: $e');
      return [];
    }
  }

  // Admin: Tạo tài khoản nhân viên mới
  static Future<Map<String, dynamic>?> adminCreateUser(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/admin-create'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      }
      return null;
    } catch (e) {
      print('Admin: Create User Error: $e');
      return null;
    }
  }

  // Admin: Xóa tài khoản người dùng
  static Future<bool> deleteUser(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['success'] == true;
      }
      return false;
    } catch (e) {
      print('Admin: Delete User Error: $e');
      return false;
    }
  }

  // Admin: Khóa / Mở khóa tài khoản người dùng
  static Future<Map<String, dynamic>?> toggleUserStatus(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/toggle-status'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Admin: Toggle User Status Error: $e');
      return null;
    }
  }

  // Admin: Xem lịch sử hoạt động AI Traces
  static Future<List<dynamic>> getAITraces() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/ai/traces'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(response.body);
        if (decodedResponse is Map && decodedResponse['success'] == true && decodedResponse['data'] != null) {
          return decodedResponse['data'] as List<dynamic>;
        } else if (decodedResponse is List) {
          return decodedResponse;
        }
      }
      return [];
    } catch (e) {
      print('Admin: Get AI Traces Error: $e');
      return [];
    }
  }
}
