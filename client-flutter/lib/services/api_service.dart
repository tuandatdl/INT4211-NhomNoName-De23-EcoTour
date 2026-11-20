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

  /// Chế độ giả lập máy chủ chuẩn seed.sql khi Render của nhóm chưa bật.
  /// Mặc định = false để luôn gọi API thật và hiện đúng trạng thái lỗi mạng theo mục C.2.7.
  static bool cheDoKiemThuCucBo = false;

  static final List<SuatModel> _dsSuatMau = [
    SuatModel(
      id: 1,
      tourId: 1,
      ngayDi: '2026-11-28',
      gioTapTrung: '06:30',
      diemTapTrung: 'Nhà Văn hóa Thanh Niên - Số 4 Phạm Ngọc Thạch, Quận 1, TP.HCM',
      phuongTien: 'Xe Limousine sinh thái 16 chỗ',
      soCho: 30,
      soChoConLai: 18,
      tenHdv: 'Nguyễn Minh Khôi (Thẻ HDV Quốc tế)',
      trangThai: 'NHAN_KHACH',
    ),
    SuatModel(
      id: 2,
      tourId: 1,
      ngayDi: '2026-11-30',
      gioTapTrung: '07:00',
      diemTapTrung: 'Bến phà Bình Khánh - Huỳnh Tấn Phát, Nhà Bè, TP.HCM',
      phuongTien: 'Xe du lịch 29 chỗ & Tàu cao tốc',
      soCho: 30,
      soChoConLai: 1, // Chỉ còn 1 chỗ để test lỗi 409 Conflict chống đặt vượt chỗ
      tenHdv: 'Trần Bảo Ngọc (Thẻ HDV Quốc tế)',
      trangThai: 'NHAN_KHACH',
    ),
    SuatModel(
      id: 3,
      tourId: 1,
      ngayDi: '2026-12-05',
      gioTapTrung: '06:30',
      diemTapTrung: 'Bến Bạch Đằng - Số 10B Tôn Đức Thắng, Quận 1, TP.HCM',
      phuongTien: 'Tàu cao tốc Greenlines DP',
      soCho: 30,
      soChoConLai: 0, // Hết chỗ để test khóa nút chọn
      tenHdv: 'Lê Quốc Tuấn (Thẻ HDV Nội địa)',
      trangThai: 'DA_KHOA',
    ),
  ];

  static final List<DatChoItemModel> _dsDonMau = [
    DatChoItemModel(
      id: 101,
      suatId: 1,
      tourId: 1,
      tenTour: 'Tour 1: Khám phá Rừng Sác Cần Giờ - Đảo Khỉ 1 Ngày',
      ngayDi: '2026-11-28',
      gioTapTrung: '06:30',
      diemTapTrung: 'Nhà Văn hóa Thanh Niên - Số 4 Phạm Ngọc Thạch, Quận 1, TP.HCM',
      phuongTien: 'Xe Limousine sinh thái 16 chỗ',
      soNguoiLon: 2,
      soTreEm: 1,
      tongTien: 2110000,
      tienHoan: 0,
      maVe: 'VE-CGVT-0101',
      trangThai: 'DA_XAC_NHAN',
      datLuc: '2026-11-18T08:30:00',
    ),
    DatChoItemModel(
      id: 102,
      suatId: 2,
      tourId: 3,
      tenTour: 'Tour 3: Liên tuyến Tàu cao tốc Cần Giờ - Vũng Tàu 2N1Đ',
      ngayDi: '2026-11-10',
      gioTapTrung: '07:00',
      diemTapTrung: 'Bến Bạch Đằng - Quận 1, TP.HCM',
      phuongTien: 'Tàu cao tốc Greenlines DP',
      soNguoiLon: 2,
      soTreEm: 0,
      tongTien: 3300000,
      tienHoan: 0,
      maVe: 'VE-CGVT-0102',
      trangThai: 'HOAN_TAT',
      datLuc: '2026-11-05T14:15:00',
    ),
    DatChoItemModel(
      id: 103,
      suatId: 1,
      tourId: 2,
      tenTour: 'Tour 2: Sinh thái Vàm Sát - Đầm Dơi - Sân Chim 1 Ngày',
      ngayDi: '2026-11-25',
      gioTapTrung: '06:30',
      diemTapTrung: 'Nhà Văn hóa Thanh Niên - Quận 1, TP.HCM',
      phuongTien: 'Xe du lịch 29 chỗ',
      soNguoiLon: 1,
      soTreEm: 0,
      tongTien: 790000,
      tienHoan: 790000,
      maVe: 'VE-CGVT-0103',
      trangThai: 'DA_HUY',
      datLuc: '2026-11-12T10:00:00',
    ),
  ];

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
  // ---------------------------------------------------------------------------
  static Future<void> dangNhap(String email, String matKhau) async {
    if (cheDoKiemThuCucBo) {
      if (matKhau != '123456') {
        throw ApiException(401, 'Email hoặc mật khẩu không đúng (mật khẩu mẫu: 123456)');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'DEMO_JWT_TOKEN_NHOMNONAME');
      return;
    }

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
    if (cheDoKiemThuCucBo) {
      return List<SuatModel>.from(_dsSuatMau);
    }
    final res = await http
        .get(Uri.parse('$baseUrl/tour/$tourId/suat'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return _layDanhSach(data).map((e) => SuatModel.fromJson(e)).toList();
  }

  // GET /danh-muc/dich-vu-kem - Danh sách dịch vụ kèm theo (API của TV2)
  static Future<List<DichVuKemModel>> layDanhSachDichVuKem() async {
    if (cheDoKiemThuCucBo) {
      return [
        DichVuKemModel(id: 1, ten: 'Suất ăn trưa hải sản sinh thái Cần Giờ', gia: 180000, donVi: 'suất'),
        DichVuKemModel(id: 2, ten: 'Thuê xe đạp xuyên rừng ngập mặn', gia: 80000, donVi: 'chiếc/ngày'),
        DichVuKemModel(id: 3, ten: 'Vé cano tham quan Đầm Dơi & Tràm Chim', gia: 150000, donVi: 'vé'),
        DichVuKemModel(id: 4, ten: 'Vé cáp treo Hồ Mây Park Vũng Tàu', gia: 400000, donVi: 'vé'),
        DichVuKemModel(id: 5, ten: 'Combo chèo thuyền Kayak rừng Sác', gia: 120000, donVi: 'lượt'),
        DichVuKemModel(id: 6, ten: 'Lều cắm trại sinh thái qua đêm bãi biển', gia: 250000, donVi: 'lều'),
      ];
    }
    final res = await http
        .get(Uri.parse('$baseUrl/danh-muc/dich-vu-kem'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return _layDanhSach(data).map((e) => DichVuKemModel.fromJson(e)).toList();
  }

  // POST /dat-cho - Máy chủ kiểm tra và trừ chỗ trong 1 transaction có FOR UPDATE.
  static Future<Map<String, dynamic>> taoDatCho({
    required int suatId,
    required List<HanhKhachModel> dsHanhKhach,
    required List<DichVuKemModel> dsDichVu,
  }) async {
    if (cheDoKiemThuCucBo) {
      final idx = _dsSuatMau.indexWhere((s) => s.id == suatId);
      final suat = idx != -1 ? _dsSuatMau[idx] : _dsSuatMau.first;
      final soNL = dsHanhKhach.where((k) => k.loaiVe == 'NGUOI_LON').length;
      final soTE = dsHanhKhach.where((k) => k.loaiVe == 'TRE_EM').length;
      final tongKhach = soNL + soTE;

      if (tongKhach > suat.soChoConLai) {
        throw ApiException(
          409,
          'Giao dịch FOR UPDATE từ chối: Suất chỉ còn ${suat.soChoConLai} chỗ trống, không đủ cho đoàn $tongKhach khách!',
        );
      }

      int tienDV = 0;
      for (final dv in dsDichVu) {
        tienDV += dv.gia * dv.soLuong;
      }
      final tongTien = (soNL * 650000) + (soTE * 450000) + tienDV;
      final idMoi = 100 + _dsDonMau.length + 1;
      final maVe = 'VE-CGVT-0$idMoi';

      // Trừ số chỗ còn lại của suất
      if (idx != -1) {
        _dsSuatMau[idx] = SuatModel(
          id: suat.id,
          tourId: suat.tourId,
          ngayDi: suat.ngayDi,
          gioTapTrung: suat.gioTapTrung,
          diemTapTrung: suat.diemTapTrung,
          phuongTien: suat.phuongTien,
          soCho: suat.soCho,
          soChoConLai: suat.soChoConLai - tongKhach,
          tenHdv: suat.tenHdv,
          trangThai: (suat.soChoConLai - tongKhach) <= 0 ? 'DA_KHOA' : suat.trangThai,
        );
      }

      _dsDonMau.insert(
        0,
        DatChoItemModel(
          id: idMoi,
          suatId: suat.id,
          tourId: suat.tourId,
          tenTour: 'Tour 1: Khám phá Rừng Sác Cần Giờ - Đảo Khỉ 1 Ngày',
          ngayDi: suat.ngayDi,
          gioTapTrung: suat.gioTapTrung,
          diemTapTrung: suat.diemTapTrung,
          phuongTien: suat.phuongTien,
          soNguoiLon: soNL,
          soTreEm: soTE,
          tongTien: tongTien,
          tienHoan: 0,
          maVe: maVe,
          trangThai: 'DA_XAC_NHAN',
          datLuc: DateTime.now().toIso8601String(),
        ),
      );

      return {
        'id': idMoi,
        'ma_ve': maVe,
        'tong_tien': tongTien,
        'so_nguoi_lon': soNL,
        'so_tre_em': soTE,
      };
    }

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
    if (cheDoKiemThuCucBo) {
      return List<DatChoItemModel>.from(_dsDonMau);
    }
    final res = await http
        .get(Uri.parse('$baseUrl/dat-cho/cua-toi'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return _layDanhSach(data).map((e) => DatChoItemModel.fromJson(e)).toList();
  }

  // GET /dat-cho/:id/ve - Chi tiết vé, hành khách, dịch vụ kèm, trạng thái điểm danh
  static Future<VeChiTietModel> layChiTietVe(int datChoId) async {
    if (cheDoKiemThuCucBo) {
      final don = _dsDonMau.firstWhere((d) => d.id == datChoId, orElse: () => _dsDonMau.first);
      return VeChiTietModel(
        id: don.id,
        maVe: don.maVe,
        tenTour: don.tenTour,
        soNgay: 1,
        ngayDi: don.ngayDi,
        gioTapTrung: don.gioTapTrung,
        diemTapTrung: don.diemTapTrung,
        phuongTien: don.phuongTien ?? 'Xe Limousine sinh thái 16 chỗ',
        hoTenHdv: 'Nguyễn Minh Khôi',
        sdtHdv: '0918111001',
        hoTenKhach: 'Bùi Quang Duy',
        sdtKhach: '0902000002',
        soNguoiLon: don.soNguoiLon,
        soTreEm: don.soTreEm,
        tongTien: don.tongTien,
        tienHoan: don.tienHoan,
        trangThai: don.trangThai,
        datLuc: don.datLuc,
        daDiemDanhDu: don.trangThai == 'HOAN_TAT',
        dsHanhKhach: [
          HanhKhachVeModel(
            id: 1,
            hoTen: 'Bùi Quang Duy (Trưởng đoàn)',
            namSinh: 1996,
            cccd: '079096001234',
            loaiVe: 'NGUOI_LON',
            thoiDiemDiemDanh: don.trangThai == 'HOAN_TAT' ? '06:35' : null,
          ),
          if (don.soNguoiLon > 1)
            HanhKhachVeModel(
              id: 2,
              hoTen: 'Nguyễn Văn Đồng Hành',
              namSinh: 1998,
              cccd: '079098005678',
              loaiVe: 'NGUOI_LON',
              thoiDiemDiemDanh: '06:36',
            ),
          if (don.soTreEm > 0)
            HanhKhachVeModel(
              id: 3,
              hoTen: 'Bé Minh Anh',
              namSinh: 2018,
              loaiVe: 'TRE_EM',
              thoiDiemDiemDanh: null,
            ),
        ],
        dsDichVu: [
          DichVuKemModel(id: 1, ten: 'Suất ăn trưa hải sản sinh thái Cần Giờ', gia: 180000, donVi: 'suất', soLuong: 2),
          DichVuKemModel(id: 3, ten: 'Vé cano tham quan Đầm Dơi & Tràm Chim', gia: 150000, donVi: 'vé', soLuong: 1),
        ],
      );
    }

    final res = await http
        .get(Uri.parse('$baseUrl/dat-cho/$datChoId/ve'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return VeChiTietModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // PATCH /dat-cho/:id/huy - Máy chủ tự tính tiền hoàn theo bảng chinh_sach_huy
  static Future<Map<String, dynamic>> huyDatCho(int datChoId) async {
    if (cheDoKiemThuCucBo) {
      final idx = _dsDonMau.indexWhere((d) => d.id == datChoId);
      int tienHoan = 0;
      if (idx != -1) {
        final cu = _dsDonMau[idx];
        tienHoan = cu.tongTien; // Trước 72h hoàn 100%
        _dsDonMau[idx] = DatChoItemModel(
          id: cu.id,
          suatId: cu.suatId,
          tourId: cu.tourId,
          tenTour: cu.tenTour,
          ngayDi: cu.ngayDi,
          gioTapTrung: cu.gioTapTrung,
          diemTapTrung: cu.diemTapTrung,
          phuongTien: cu.phuongTien,
          soNguoiLon: cu.soNguoiLon,
          soTreEm: cu.soTreEm,
          tongTien: cu.tongTien,
          tienHoan: tienHoan,
          maVe: cu.maVe,
          trangThai: 'DA_HUY',
          datLuc: cu.datLuc,
        );
      }
      return {
        'id': datChoId,
        'trang_thai': 'DA_HUY',
        'tien_hoan': tienHoan,
        'phan_tram_hoan': 100,
      };
    }

    final res = await http
        .patch(Uri.parse('$baseUrl/dat-cho/$datChoId/huy'), headers: await _headers())
        .timeout(_timeout);
    final data = _xuLyPhanHoi(res);
    return Map<String, dynamic>.from(data as Map);
  }
}
