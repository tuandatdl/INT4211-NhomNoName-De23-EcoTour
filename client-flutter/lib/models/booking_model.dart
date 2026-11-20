// Model dữ liệu cho luồng đặt chỗ, vé QR và đơn của tôi (phần của TV4).
// Tên khóa JSON giữ nguyên snake_case khớp cột CSDL theo quy chuẩn chung của nhóm.

/// Đọc số nguyên an toàn: PostgreSQL có lúc trả số dạng chuỗi (SUM, COUNT, NUMERIC).
int soNguyen(dynamic v, [int macDinh = 0]) {
  if (v == null) return macDinh;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? macDinh;
}

/// Cột DATE của PostgreSQL về JSON dạng "2026-11-20T00:00:00.000Z" -> hiển thị "20/11/2026".
String ngayHienThi(String raw) {
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  final local = d.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year}';
}

class SuatModel {
  final int id;
  final int tourId;
  final String ngayDi;
  final String gioTapTrung;
  final String diemTapTrung;
  final String phuongTien;
  final int soCho;
  final int soChoConLai;
  final String? tenHdv;
  final String trangThai;

  SuatModel({
    required this.id,
    required this.tourId,
    required this.ngayDi,
    required this.gioTapTrung,
    required this.diemTapTrung,
    required this.phuongTien,
    required this.soCho,
    required this.soChoConLai,
    this.tenHdv,
    required this.trangThai,
  });

  /// Suất chỉ nhận khách khi đang mở bán và còn chỗ (máy chủ vẫn kiểm tra lại khi đặt).
  bool get conNhanKhach => soChoConLai > 0 && (trangThai == 'NHAN_KHACH' || trangThai == 'MO_BAN');

  factory SuatModel.fromJson(Map<String, dynamic> json) {
    final soCho = soNguyen(json['so_cho']);
    return SuatModel(
      id: soNguyen(json['id']),
      tourId: soNguyen(json['tour_id']),
      ngayDi: json['ngay_di']?.toString() ?? '',
      gioTapTrung: json['gio_tap_trung']?.toString() ?? '',
      diemTapTrung: json['diem_tap_trung']?.toString() ?? '',
      phuongTien: json['phuong_tien']?.toString() ?? '',
      soCho: soCho,
      soChoConLai: soNguyen(json['so_cho_con_lai'], soCho),
      tenHdv: json['ten_hdv']?.toString(),
      trangThai: json['trang_thai']?.toString() ?? 'NHAN_KHACH',
    );
  }
}

class HanhKhachModel {
  String hoTen;
  int namSinh;
  String? cccd;
  String loaiVe; // 'NGUOI_LON' hoac 'TRE_EM'

  HanhKhachModel({
    required this.hoTen,
    required this.namSinh,
    this.cccd,
    required this.loaiVe,
  });

  // Khóa camelCase theo đúng body mà API POST /dat-cho của TV1 đọc
  Map<String, dynamic> toJson() {
    return {
      'hoTen': hoTen,
      'namSinh': namSinh,
      if (cccd != null && cccd!.isNotEmpty) 'cccd': cccd,
      'loaiVe': loaiVe,
    };
  }
}

class DichVuKemModel {
  final int id;
  final String ten;
  final int gia;
  final String donVi;
  int soLuong;

  DichVuKemModel({
    required this.id,
    required this.ten,
    required this.gia,
    required this.donVi,
    this.soLuong = 0,
  });

  factory DichVuKemModel.fromJson(Map<String, dynamic> json) {
    return DichVuKemModel(
      id: soNguyen(json['id']),
      ten: json['ten']?.toString() ?? '',
      gia: soNguyen(json['gia']),
      donVi: json['don_vi']?.toString() ?? '',
      soLuong: soNguyen(json['so_luong']),
    );
  }

  Map<String, dynamic> toDatDichVuJson() => {'dichVuId': id, 'soLuong': soLuong};
}

class DatChoItemModel {
  final int id;
  final int suatId;
  final int tourId;
  final String tenTour;
  final String? anhTour;
  final String ngayDi;
  final String gioTapTrung;
  final String diemTapTrung;
  final String? phuongTien;
  final int soNguoiLon;
  final int soTreEm;
  final int tongTien;
  final int tienHoan;
  final String maVe;
  final String trangThai; // 'DA_XAC_NHAN', 'DA_HUY', 'HOAN_TAT'
  final String? datLuc;

  DatChoItemModel({
    required this.id,
    required this.suatId,
    required this.tourId,
    required this.tenTour,
    this.anhTour,
    required this.ngayDi,
    required this.gioTapTrung,
    required this.diemTapTrung,
    this.phuongTien,
    required this.soNguoiLon,
    required this.soTreEm,
    required this.tongTien,
    required this.tienHoan,
    required this.maVe,
    required this.trangThai,
    this.datLuc,
  });

  bool get coTheHuy => trangThai == 'DA_XAC_NHAN';

  factory DatChoItemModel.fromJson(Map<String, dynamic> json) {
    return DatChoItemModel(
      id: soNguyen(json['id']),
      suatId: soNguyen(json['suat_id']),
      tourId: soNguyen(json['tour_id']),
      tenTour: json['ten_tour']?.toString() ?? '',
      anhTour: json['anh_tour']?.toString(),
      ngayDi: json['ngay_di']?.toString() ?? '',
      gioTapTrung: json['gio_tap_trung']?.toString() ?? '',
      diemTapTrung: json['diem_tap_trung']?.toString() ?? '',
      phuongTien: json['phuong_tien']?.toString(),
      soNguoiLon: soNguyen(json['so_nguoi_lon']),
      soTreEm: soNguyen(json['so_tre_em']),
      tongTien: soNguyen(json['tong_tien']),
      tienHoan: soNguyen(json['tien_hoan']),
      maVe: json['ma_ve']?.toString() ?? '',
      trangThai: json['trang_thai']?.toString() ?? 'DA_XAC_NHAN',
      datLuc: json['dat_luc']?.toString(),
    );
  }
}

/// Hành khách trên vé, kèm trạng thái đã được HDV quét điểm danh hay chưa.
class HanhKhachVeModel {
  final int id;
  final String hoTen;
  final int namSinh;
  final String? cccd;
  final String loaiVe;
  final String? thoiDiemDiemDanh;

  HanhKhachVeModel({
    required this.id,
    required this.hoTen,
    required this.namSinh,
    this.cccd,
    required this.loaiVe,
    this.thoiDiemDiemDanh,
  });

  bool get daDiemDanh => thoiDiemDiemDanh != null;

  factory HanhKhachVeModel.fromJson(Map<String, dynamic> json) {
    return HanhKhachVeModel(
      id: soNguyen(json['id']),
      hoTen: json['ho_ten']?.toString() ?? '',
      namSinh: soNguyen(json['nam_sinh']),
      cccd: json['cccd']?.toString(),
      loaiVe: json['loai_ve']?.toString() ?? 'NGUOI_LON',
      thoiDiemDiemDanh: json['thoi_diem_diem_danh']?.toString(),
    );
  }
}

class VeChiTietModel {
  final int id;
  final String maVe;
  final String tenTour;
  final int soNgay;
  final String ngayDi;
  final String gioTapTrung;
  final String diemTapTrung;
  final String phuongTien;
  final String? hoTenHdv;
  final String? sdtHdv;
  final String hoTenKhach;
  final String? sdtKhach;
  final int soNguoiLon;
  final int soTreEm;
  final int tongTien;
  final int tienHoan;
  final String trangThai;
  final String? datLuc;
  final List<HanhKhachVeModel> dsHanhKhach;
  final List<DichVuKemModel> dsDichVu;
  final bool daDiemDanhDu;

  VeChiTietModel({
    required this.id,
    required this.maVe,
    required this.tenTour,
    required this.soNgay,
    required this.ngayDi,
    required this.gioTapTrung,
    required this.diemTapTrung,
    required this.phuongTien,
    this.hoTenHdv,
    this.sdtHdv,
    required this.hoTenKhach,
    this.sdtKhach,
    required this.soNguoiLon,
    required this.soTreEm,
    required this.tongTien,
    required this.tienHoan,
    required this.trangThai,
    this.datLuc,
    required this.dsHanhKhach,
    required this.dsDichVu,
    required this.daDiemDanhDu,
  });

  /// Tổng tiền dịch vụ kèm, dùng để tách bảng kê (tổng tiền vẫn lấy từ máy chủ).
  int get tienDichVu => dsDichVu.fold(0, (s, dv) => s + dv.gia * dv.soLuong);
  int get tienVe => tongTien - tienDichVu;

  factory VeChiTietModel.fromJson(Map<String, dynamic> json) {
    final dsHk = (json['hanh_khach'] as List? ?? [])
        .map((e) => HanhKhachVeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final dsDv = (json['dich_vu_kem'] as List? ?? [])
        .map((e) => DichVuKemModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return VeChiTietModel(
      id: soNguyen(json['id']),
      maVe: json['ma_ve']?.toString() ?? '',
      tenTour: json['ten_tour']?.toString() ?? '',
      soNgay: soNguyen(json['so_ngay'], 1),
      ngayDi: json['ngay_di']?.toString() ?? '',
      gioTapTrung: json['gio_tap_trung']?.toString() ?? '',
      diemTapTrung: json['diem_tap_trung']?.toString() ?? '',
      phuongTien: json['phuong_tien']?.toString() ?? '',
      hoTenHdv: json['ho_ten_hdv']?.toString(),
      sdtHdv: json['sdt_hdv']?.toString(),
      hoTenKhach: json['ho_ten_khach']?.toString() ?? '',
      sdtKhach: json['sdt_khach']?.toString(),
      soNguoiLon: soNguyen(json['so_nguoi_lon']),
      soTreEm: soNguyen(json['so_tre_em']),
      tongTien: soNguyen(json['tong_tien']),
      tienHoan: soNguyen(json['tien_hoan']),
      trangThai: json['trang_thai']?.toString() ?? 'DA_XAC_NHAN',
      datLuc: json['dat_luc']?.toString(),
      dsHanhKhach: dsHk,
      dsDichVu: dsDv,
      daDiemDanhDu: json['da_diem_danh_du'] == true,
    );
  }
}
