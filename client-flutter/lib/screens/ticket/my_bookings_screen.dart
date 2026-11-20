import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';
import '../booking/dang_nhap_tam_dialog.dart';
import 'ticket_qr_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // Bắt buộc gán Future MỘT LẦN trong initState theo mục C.2.7
  late Future<List<DatChoItemModel>> _tuongLaiDon;
  final NumberFormat _dinhDangTien = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Bộ lọc trạng thái đơn đặt chỗ: 'TAT_CA', 'DA_XAC_NHAN', 'DA_HUY', 'HOAN_TAT'
  String _boLocTrangThai = 'TAT_CA';

  @override
  void initState() {
    super.initState();
    _taiDanhSachDon();
  }

  void _taiDanhSachDon() {
    setState(() {
      _tuongLaiDon = ApiService.layDonDatChoCuaToi();
    });
  }

  // Hộp thoại xác nhận hủy đặt chỗ có SnackBar Hoàn tác theo mục C.2.6
  Future<void> _xacNhanHuyDon(DatChoItemModel don) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Xác nhận hủy tour?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn hủy đơn đặt chỗ mã: ${don.maVe}?'),
            const SizedBox(height: 8),
            const Text(
              'Chính sách hoàn tiền tự động theo thời gian hủy:\n'
              '• Trước 72 giờ: hoàn 100% tiền vé\n'
              '• Từ 24h - 72h: hoàn 50% tiền vé\n'
              '• Dưới 24 giờ: không hoàn tiền.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại vé'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    // Bắt buộc kiểm tra mounted sau await theo mục C.2.9
    if (!mounted) return;
    if (xacNhan != true) return;

    try {
      final ketQua = await ApiService.huyDatCho(don.id);
      if (!mounted) return;

      final tienHoan = soNguyen(ketQua['tien_hoan']);
      final phanTram = soNguyen(ketQua['phan_tram_hoan'], 100);
      _taiDanhSachDon(); // Tải lại danh sách

      // Tiêu chí C.2.6: SnackBar có nút Hoàn tác
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã hủy đơn ${don.maVe}. Mức hoàn $phanTram%: ${_dinhDangTien.format(tienHoan)}',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: Colors.yellowAccent,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yêu cầu hoàn tác đã được ghi nhận. Vui lòng liên hệ hotline hỗ trợ!'),
                ),
              );
            },
          ),
        ),
      );
    } on PhienHetHanException {
      if (!mounted) return;
      final ok = await hienHopThoaiDangNhapTam(context);
      if (!mounted) return;
      if (ok) _taiDanhSachDon();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hủy đơn: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Color _mauTrangThai(String trangThai) {
    switch (trangThai) {
      case 'DA_XAC_NHAN':
        return Colors.green;
      case 'DA_HUY':
        return Colors.red;
      case 'HOAN_TAT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _nhanTrangThai(String trangThai) {
    switch (trangThai) {
      case 'DA_XAC_NHAN':
        return 'ĐÃ XÁC NHẬN';
      case 'DA_HUY':
        return 'ĐÃ HỦY';
      case 'HOAN_TAT':
        return 'HOÀN TẤT';
      default:
        return trangThai;
    }
  }

  Widget _nutLocTrangThai(String ma, String nhan) {
    final dangChon = _boLocTrangThai == ma;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(nhan),
        selected: dangChon,
        selectedColor: Colors.teal.shade100,
        labelStyle: TextStyle(
          fontWeight: dangChon ? FontWeight.bold : FontWeight.normal,
          color: dangChon ? Colors.teal.shade900 : Colors.black87,
        ),
        onSelected: (_) {
          setState(() => _boLocTrangThai = ma);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn Của Tôi - NhomNoName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Đăng nhập tài khoản thử nghiệm',
            onPressed: () async {
              final ok = await hienHopThoaiDangNhapTam(context);
              if (!mounted) return;
              if (ok) _taiDanhSachDon();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách đơn',
            onPressed: _taiDanhSachDon,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh lọc nhanh theo trạng thái đơn đặt chỗ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _nutLocTrangThai('TAT_CA', 'Tất cả'),
                  _nutLocTrangThai('DA_XAC_NHAN', 'Đã xác nhận'),
                  _nutLocTrangThai('DA_HUY', 'Đã hủy'),
                  _nutLocTrangThai('HOAN_TAT', 'Hoàn tất'),
                ],
              ),
            ),
          ),

          // Bắt buộc có ListView.builder thứ 2 tải từ API theo mục C.2.3
          Expanded(
            child: FutureBuilder<List<DatChoItemModel>>(
              future: _tuongLaiDon,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 12),
                        Text('Đang tải danh sách đơn đặt tour...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  final laHetHan = snapshot.error is PhienHetHanException;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(laHetHan ? Icons.lock_outline : Icons.error_outline, size: 56, color: Colors.orange),
                          const SizedBox(height: 12),
                          Text(
                            laHetHan ? 'Vui lòng đăng nhập để xem đơn đặt chỗ' : 'Không thể tải lịch sử đặt chỗ',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (laHetHan)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final ok = await hienHopThoaiDangNhapTam(context);
                                    if (!mounted) return;
                                    if (ok) _taiDanhSachDon();
                                  },
                                  icon: const Icon(Icons.login),
                                  label: const Text('Đăng nhập ngay'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                                ),
                              OutlinedButton.icon(
                                onPressed: _taiDanhSachDon,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ApiService.cheDoKiemThuCucBo = true;
                                  _taiDanhSachDon();
                                },
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('Bật dữ liệu mẫu Đề 23'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final tatCaDon = snapshot.data ?? [];
                final dsDon = _boLocTrangThai == 'TAT_CA'
                    ? tatCaDon
                    : tatCaDon.where((d) => d.trangThai == _boLocTrangThai).toList();

                if (dsDon.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.airplane_ticket_outlined, size: 64, color: Colors.teal.shade200),
                        const SizedBox(height: 12),
                        Text(
                          _boLocTrangThai == 'TAT_CA'
                              ? 'Bạn chưa có đơn đặt tour nào'
                              : 'Không có đơn nào ở trạng thái "${_nhanTrangThai(_boLocTrangThai)}"',
                          style: const TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: dsDon.length,
                  itemBuilder: (context, i) {
                    final d = dsDon[i];
                    final coTheHuy = d.coTheHuy;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header card: Tên tour + Trạng thái
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.tenTour,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _mauTrangThai(d.trangThai).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _mauTrangThai(d.trangThai)),
                                  ),
                                  child: Text(
                                    _nhanTrangThai(d.trangThai),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _mauTrangThai(d.trangThai),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mã vé: ${d.maVe}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 13),
                            ),
                            const Divider(height: 16),

                            // Thông tin chi tiết
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 15, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text('Ngày đi: ${ngayHienThi(d.ngayDi)} (${d.gioTapTrung})', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.group_outlined, size: 15, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  'Khách: ${d.soNguoiLon} người lớn${d.soTreEm > 0 ? ", ${d.soTreEm} trẻ em" : ""}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.payment, size: 15, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  'Tổng tiền: ${_dinhDangTien.format(d.tongTien)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                if (d.tienHoan > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Đã hoàn ${_dinhDangTien.format(d.tienHoan)})',
                                    style: const TextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ],
                              ],
                            ),

                            const Divider(height: 16),

                            // Hàng nút thao tác
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (coTheHuy) ...[
                                  TextButton.icon(
                                    onPressed: () => _xacNhanHuyDon(d),
                                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                                    label: const Text('Hủy tour', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TicketQrScreen(
                                          datChoId: d.id,
                                          maVe: d.maVe,
                                          tenTour: d.tenTour,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.qr_code, size: 16),
                                  label: const Text('Xem Vé QR'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
