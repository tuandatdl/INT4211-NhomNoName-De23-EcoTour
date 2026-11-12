import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

class ApiService {
  // Đường dẫn Backend Render của nhóm (hoặc đổi thành http://10.0.2.2:3000 khi chạy emulator local)
  static String baseUrl = 'https://ecotour-cangio-vungtau.onrender.com';
  static const String logTag = 'NhomNoName_Log';

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Đăng nhập và lưu token vào SharedPreferences
  static Future<bool> dangNhap({String email = 'khach1@gmail.com', String matKhau = '123456'}) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/dang-nhap');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'matKhau': matKhau}),
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] ?? '');
        if (data['nguoiDung'] != null) {
          await prefs.setString('hoTen', data['nguoiDung']['hoTen'] ?? '');
          await prefs.setString('email', data['nguoiDung']['email'] ?? '');
          await prefs.setString('vaiTro', data['nguoiDung']['vaiTro'] ?? '');
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Lấy token hiện tại hoặc tự động đăng nhập tài khoản test nếu chưa có
  static Future<String> layTokenHoacDangNhapTest() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      await dangNhap();
      token = prefs.getString('token') ?? '';
    }
    return token;
  }

  // Lấy danh sách Suất khởi hành kèm số chỗ còn lại (GET /tour/:id/suat)
  static Future<List<SuatModel>> layDanhSachSuat(int tourId) async {
    final uri = Uri.parse('$baseUrl/tour/$tourId/suat');
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 90));

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => SuatModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi máy chủ khi lấy suất khởi hành: ${res.statusCode}');
  }

  // Lấy danh sách Dịch vụ kèm theo (GET /dich-vu-kem)
  static Future<List<DichVuKemModel>> layDanhSachDichVuKem() async {
    final uri = Uri.parse('$baseUrl/dich-vu-kem');
    try {
      final res = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => DichVuKemModel.fromJson(e)).toList();
      }
    } catch (_) {}

    // Dữ liệu fallback chuẩn theo seed.sql của Đề 23
    return [
      DichVuKemModel(id: 1, ten: 'Suất ăn trưa hải sản sinh thái Cần Giờ', gia: 180000, donVi: 'suất'),
      DichVuKemModel(id: 2, ten: 'Thuê xe đạp xuyên rừng ngập mặn', gia: 80000, donVi: 'chiếc/ngày'),
      DichVuKemModel(id: 3, ten: 'Vé cano tham quan Đầm Dơi & Tràm Chim', gia: 150000, donVi: 'vé'),
      DichVuKemModel(id: 4, ten: 'Vé cáp treo Hồ Mây Park Vũng Tàu', gia: 400000, donVi: 'vé'),
      DichVuKemModel(id: 5, ten: 'Combo chèo thuyền Kayak rừng Sác', gia: 120000, donVi: 'lượt'),
      DichVuKemModel(id: 6, ten: 'Lều cắm trại sinh thái qua đêm bãi biển', gia: 250000, donVi: 'lều'),
    ];
  }

  // POST /dat-cho - Nghiệp vụ then chốt có transaction FOR UPDATE chống vượt chỗ
  static Future<Map<String, dynamic>> taoDatCho({
    required int suatId,
    required List<HanhKhachModel> dsHanhKhach,
    required List<DichVuKemModel> dsDichVu,
  }) async {
    await layTokenHoacDangNhapTest();
    final uri = Uri.parse('$baseUrl/dat-cho');

    final body = {
      'suatId': suatId,
      'dsHanhKhach': dsHanhKhach.map((hk) => hk.toJson()).toList(),
      'dsDichVu': dsDichVu
          .where((dv) => dv.soLuong > 0)
          .map((dv) => dv.toDatDichVuJson())
          .toList(),
    };

    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 201) {
      return {'thanhCong': true, 'data': data};
    } else if (res.statusCode == 409) {
      // Bắt mã lỗi 409 khi hết chỗ (Điểm nhấn kỹ thuật đề 23)
      return {
        'thanhCong': false,
        'maLoi': 409,
        'loi': data['loi'] ?? 'Số chỗ trống không đủ cho đoàn. Vui lòng chọn suất khác!',
      };
    } else {
      return {
        'thanhCong': false,
        'maLoi': res.statusCode,
        'loi': data['loi'] ?? 'Đã xảy ra lỗi đặt chỗ (${res.statusCode})',
      };
    }
  }

  // GET /dat-cho/cua-toi - Danh sách đơn của tôi (ListView.builder thứ 2)
  static Future<List<DatChoItemModel>> layDonDatChoCuaToi() async {
    await layTokenHoacDangNhapTest();
    final uri = Uri.parse('$baseUrl/dat-cho/cua-toi');

    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 90));

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => DatChoItemModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi khi tải lịch sử đơn đặt chỗ: ${res.statusCode}');
  }

  // GET /dat-cho/:id/ve - Lấy chi tiết vé điện tử kèm mã QR
  static Future<VeChiTietModel> layChiTietVe(int datChoId) async {
    await layTokenHoacDangNhapTest();
    final uri = Uri.parse('$baseUrl/dat-cho/$datChoId/ve');

    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 90));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return VeChiTietModel.fromJson(data);
    }
    throw Exception('Không lấy được thông tin vé điện tử: ${res.statusCode}');
  }

  // PATCH /dat-cho/:id/huy - Hủy đơn đặt chỗ & tính tiền hoàn tự động
  static Future<Map<String, dynamic>> huyDatCho(int datChoId) async {
    await layTokenHoacDangNhapTest();
    final uri = Uri.parse('$baseUrl/dat-cho/$datChoId/huy');

    final res = await http
        .patch(uri, headers: await _headers())
        .timeout(const Duration(seconds: 90));

    final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200) {
      return {'thanhCong': true, 'data': data};
    }
    return {
      'thanhCong': false,
      'loi': data['loi'] ?? 'Không thể hủy đơn này (${res.statusCode})',
    };
  }
}
