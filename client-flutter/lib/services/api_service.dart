import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

/// Lỗi phiên đăng nhập hết hạn (HTTP 401) - màn hình bắt lỗi này để yêu cầu đăng nhập lại.
class PhienHetHanException implements Exception {
  final String thongBao;
  PhienHetHanException([this.thongBao = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại']);
  @override
  String toString() => thongBao;
}

/// Lỗi trả về từ máy chủ kèm mã HTTP và thông báo tiếng Việt.
class ApiException implements Exception {
  final int maLoi;
  final String thongBao;
  ApiException(this.maLoi, this.thongBao);
  @override
  String toString() => thongBao;
}

class ApiService {
  // Đổi máy chủ khi chạy thử mà không cần sửa code:
  //   flutter run -d chrome --dart-define=API_URL=http://localhost:3000
  //   flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ecotour-nhomnoname.onrender.com',
  );
  static const String logTag = 'NhomNoName_Log';

  // Render gói Free ngủ sau 15 phút, lần gọi đầu mất khoảng 1 phút để thức dậy
  static const Duration _timeout = Duration(seconds: 90);

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Giải mã body bằng utf8 để không lỗi font tiếng Việt.
  static dynamic _giaiMa(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  /// Backend của nhóm có 2 kiểu trả lỗi: {loi: ...} (TV1) và {thongBao: ...} (TV2).
  static String _layThongBaoLoi(dynamic data, int maLoi) {
    if (data is Map) {
      final tb = data['loi'] ?? data['thongBao'];
      if (tb != null) return tb.toString();
    }
    return 'Lỗi máy chủ ($maLoi)';
  }

  /// Backend có route trả mảng thẳng, có route bọc trong {duLieu: [...]}.
  static List _layDanhSach(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['duLieu'] is List) return data['duLieu'] as List;
    return [];
  }

  /// Kiểm tra mã trạng thái, ném lỗi rõ ràng để màn hình hiển thị trạng thái lỗi.
  static dynamic _xuLyPhanHoi(http.Response res) {
    final data = _giaiMa(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    if (res.statusCode == 401) {
      throw PhienHetHanException(_layThongBaoLoi(data, 401));
    }
    throw ApiException(res.statusCode, _layThongBaoLoi(data, res.statusCode));
  }

  // ---------------------------------------------------------------------------
  // Đăng nhập tạm để TV4 tự kiểm thử khi màn hình Đăng nhập của TV3 chưa có.
  // Khi TV3 hoàn thành màn hình Đăng nhập, token sẽ được lưu cùng khóa 'token'.
  // ---------------------------------------------------------------------------
  static Future<void> dangNhap(String email, String matKhau) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/dang-nhap'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'matKhau': matKhau}),
        )
        .timeout(_timeout);

    final data = _xuLyPhanHoi(res);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']?.toString() ?? '');
  }

  static Future<bool> daDangNhap() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('token') ?? '').isNotEmpty;
  }

  // GET /tour/:id/suat - Danh sách suất kèm số chỗ còn lại (máy chủ tính)
  static Future<List<SuatModel>> layDanhSachSuat(int tourId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/tour/$tourId/suat'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return _layDanhSach(data).map((e) => SuatModel.fromJson(e)).toList();
  }

  // GET /danh-muc/dich-vu-kem - Danh sách dịch vụ kèm theo (API của TV2)
  static Future<List<DichVuKemModel>> layDanhSachDichVuKem() async {
    final res = await http
        .get(Uri.parse('$baseUrl/danh-muc/dich-vu-kem'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return _layDanhSach(data).map((e) => DichVuKemModel.fromJson(e)).toList();
  }

  // POST /dat-cho - Máy chủ kiểm tra và trừ chỗ trong 1 transaction có FOR UPDATE.
  // Giá tiền do máy chủ tính, app chỉ gửi danh sách hành khách và dịch vụ.
  // Trả về đơn vừa tạo; ném ApiException(409) khi suất không còn đủ chỗ.
  static Future<Map<String, dynamic>> taoDatCho({
    required int suatId,
    required List<HanhKhachModel> dsHanhKhach,
    required List<DichVuKemModel> dsDichVu,
  }) async {
    final body = {
      'suatId': suatId,
      'dsHanhKhach': dsHanhKhach.map((hk) => hk.toJson()).toList(),
      'dsDichVu': dsDichVu.where((dv) => dv.soLuong > 0).map((dv) => dv.toDatDichVuJson()).toList(),
    };

    final res = await http
        .post(Uri.parse('$baseUrl/dat-cho'), headers: await _headers(), body: jsonEncode(body))
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return Map<String, dynamic>.from(data as Map);
  }

  // GET /dat-cho/cua-toi - Danh sách đơn của khách đang đăng nhập
  static Future<List<DatChoItemModel>> layDonDatChoCuaToi() async {
    final res = await http
        .get(Uri.parse('$baseUrl/dat-cho/cua-toi'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return _layDanhSach(data).map((e) => DatChoItemModel.fromJson(e)).toList();
  }

  // GET /dat-cho/:id/ve - Chi tiết vé, hành khách, dịch vụ kèm, trạng thái điểm danh
  static Future<VeChiTietModel> layChiTietVe(int datChoId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/dat-cho/$datChoId/ve'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return VeChiTietModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // PATCH /dat-cho/:id/huy - Máy chủ tự tính tiền hoàn theo bảng chinh_sach_huy
  static Future<Map<String, dynamic>> huyDatCho(int datChoId) async {
    final res = await http
        .patch(Uri.parse('$baseUrl/dat-cho/$datChoId/huy'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return Map<String, dynamic>.from(data as Map);
  }
}
