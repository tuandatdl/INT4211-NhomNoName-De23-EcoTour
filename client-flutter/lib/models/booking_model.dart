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

  factory SuatModel.fromJson(Map<String, dynamic> json) {
    return SuatModel(
      id: json['id'] as int? ?? 0,
      tourId: json['tour_id'] as int? ?? 0,
      ngayDi: json['ngay_di']?.toString() ?? '',
      gioTapTrung: json['gio_tap_trung']?.toString() ?? '',
      diemTapTrung: json['diem_tap_trung']?.toString() ?? '',
      phuongTien: json['phuong_tien']?.toString() ?? 'Xe du lịch & Tàu cao tốc',
      soCho: json['so_cho'] as int? ?? 0,
      soChoConLai: (json['so_cho_con_lai'] != null)
          ? int.tryParse(json['so_cho_con_lai'].toString()) ?? 0
          : (json['so_cho'] as int? ?? 0),
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
      id: json['id'] as int? ?? 0,
      ten: json['ten']?.toString() ?? '',
      gia: json['gia'] as int? ?? 0,
      donVi: json['don_vi']?.toString() ?? 'lượt',
      soLuong: 0,
    );
  }

  Map<String, dynamic> toDatDichVuJson() {
    return {
      'dichVuId': id,
      'soLuong': soLuong,
    };
  }
}

class DatChoItemModel {
  final int id;
  final int suatId;
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

  factory DatChoItemModel.fromJson(Map<String, dynamic> json) {
    return DatChoItemModel(
      id: json['id'] as int? ?? 0,
      suatId: json['suat_id'] as int? ?? 0,
      tenTour: json['ten_tour']?.toString() ?? 'Tour Cần Giờ - Vũng Tàu',
      anhTour: json['anh_tour']?.toString(),
      ngayDi: json['ngay_di']?.toString() ?? '',
      gioTapTrung: json['gio_tap_trung']?.toString() ?? '',
      diemTapTrung: json['diem_tap_trung']?.toString() ?? '',
      phuongTien: json['phuong_tien']?.toString(),
      soNguoiLon: json['so_nguoi_lon'] as int? ?? 0,
      soTreEm: json['so_tre_em'] as int? ?? 0,
      tongTien: json['tong_tien'] as int? ?? 0,
      tienHoan: json['tien_hoan'] as int? ?? 0,
      maVe: json['ma_ve']?.toString() ?? '',
      trangThai: json['trang_thai']?.toString() ?? 'DA_XAC_NHAN',
      datLuc: json['dat_luc']?.toString(),
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
  final List<dynamic> dsHanhKhach;
  final List<dynamic> dsDichVu;

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
    required this.dsHanhKhach,
    required this.dsDichVu,
  });

  factory VeChiTietModel.fromJson(Map<String, dynamic> json) {
    return VeChiTietModel(
      id: json['id'] as int? ?? 0,
      maVe: json['ma_ve']?.toString() ?? '',
      tenTour: json['ten_tour']?.toString() ?? '',
      soNgay: json['so_ngay'] as int? ?? 1,
      ngayDi: json['ngay_di']?.toString() ?? '',
      gioTapTrung: json['gio_tap_trung']?.toString() ?? '',
      diemTapTrung: json['diem_tap_trung']?.toString() ?? '',
      phuongTien: json['phuong_tien']?.toString() ?? 'Xe du lịch & Tàu cao tốc',
      hoTenHdv: json['ho_ten_hdv']?.toString(),
      sdtHdv: json['sdt_hdv']?.toString(),
      hoTenKhach: json['ho_ten_khach']?.toString() ?? '',
      sdtKhach: json['sdt_khach']?.toString(),
      soNguoiLon: json['so_nguoi_lon'] as int? ?? 0,
      soTreEm: json['so_tre_em'] as int? ?? 0,
      tongTien: json['tong_tien'] as int? ?? 0,
      tienHoan: json['tien_hoan'] as int? ?? 0,
      trangThai: json['trang_thai']?.toString() ?? 'DA_XAC_NHAN',
      dsHanhKhach: json['hanh_khach'] as List<dynamic>? ?? [],
      dsDichVu: json['dich_vu'] as List<dynamic>? ?? [],
    );
  }
}
