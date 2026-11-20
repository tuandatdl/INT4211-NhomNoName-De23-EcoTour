import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';
import '../ticket/ticket_qr_screen.dart';
import 'dang_nhap_tam_dialog.dart';

class BookingFormScreen extends StatefulWidget {
  final SuatModel suat;
  final String tenTour;
  final int giaNguoiLon;
  final int giaTreEm;

  const BookingFormScreen({
    super.key,
    required this.suat,
    required this.tenTour,
    required this.giaNguoiLon,
    required this.giaTreEm,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _dinhDangTien = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  int _soNguoiLon = 1;
  int _soTreEm = 0;
  bool _dangGui = false;

  // Danh sách hành khách nhập trong Form
  List<HanhKhachModel> _dsHanhKhach = [];
  // Danh sách dịch vụ sinh thái đi kèm
  List<DichVuKemModel> _dsDichVu = [];
  bool _dangTaiDichVu = true;
  String? _loiDichVu;

  @override
  void initState() {
    super.initState();
    _dongBoDanhSachHanhKhach();
    _taiDichVuKem();
  }

  Future<void> _taiDichVuKem() async {
    try {
      final dv = await ApiService.layDanhSachDichVuKem();
      if (!mounted) return;
      setState(() {
        _dsDichVu = dv;
        _dangTaiDichVu = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dangTaiDichVu = false;
        _loiDichVu = 'Không tải được dịch vụ kèm: $e';
      });
    }
  }

  /// Giữ lại thông tin đã nhập khi tăng/giảm số khách, chỉ thêm/bớt ô ở cuối mỗi nhóm.
  /// Không gọi setState ở đây - nơi gọi tự bọc trong setState.
  void _dongBoDanhSachHanhKhach() {
    final nguoiLonCu = _dsHanhKhach.where((k) => k.loaiVe == 'NGUOI_LON').toList();
    final treEmCu = _dsHanhKhach.where((k) => k.loaiVe == 'TRE_EM').toList();

    final List<HanhKhachModel> moi = [];
    for (int i = 0; i < _soNguoiLon; i++) {
      moi.add(i < nguoiLonCu.length
          ? nguoiLonCu[i]
          : HanhKhachModel(hoTen: '', namSinh: 0, cccd: '', loaiVe: 'NGUOI_LON'));
    }
    for (int i = 0; i < _soTreEm; i++) {
      moi.add(i < treEmCu.length
          ? treEmCu[i]
          : HanhKhachModel(hoTen: '', namSinh: 0, cccd: '', loaiVe: 'TRE_EM'));
    }
    _dsHanhKhach = moi;
  }

  int get _tongTienVe => (_soNguoiLon * widget.giaNguoiLon) + (_soTreEm * widget.giaTreEm);

  int get _tongTienDichVu {
    int sum = 0;
    for (final dv in _dsDichVu) {
      sum += dv.gia * dv.soLuong;
    }
    return sum;
  }

  int get _tongTienTamTinh => _tongTienVe + _tongTienDichVu;

  Future<void> _xacNhanDatCho() async {
    // 1. Kiểm tra validator của Form (Mục C.2.4)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại các trường thông tin hành khách chưa hợp lệ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final tongKhach = _soNguoiLon + _soTreEm;
    if (tongKhach > widget.suat.soChoConLai) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số khách ($tongKhach) vượt quá số chỗ còn lại (${widget.suat.soChoConLai})!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _dangGui = true);

    try {
      // POST /dat-cho: máy chủ khóa dòng suất (FOR UPDATE), kiểm tra chỗ và tính tiền
      final don = await ApiService.taoDatCho(
        suatId: widget.suat.id,
        dsHanhKhach: _dsHanhKhach,
        dsDichVu: _dsDichVu,
      );

      // Bắt buộc kiểm tra mounted sau await theo mục C.2.9
      if (!mounted) return;
      setState(() => _dangGui = false);

      final maVe = don['ma_ve']?.toString() ?? '';
      final datChoId = soNguyen(don['id']);
      // Hiển thị tổng tiền DO MÁY CHỦ TÍNH, không dùng số tạm tính của app
      final tongTienMayChu = soNguyen(don['tong_tien']);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Đặt Tour Thành Công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mã vé điện tử: $maVe', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 8),
              Text('Tổng tiền: ${_dinhDangTien.format(tongTienMayChu)}'),
              const SizedBox(height: 6),
              Text('Số khách: $_soNguoiLon người lớn, $_soTreEm trẻ em'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true); // Trả kết quả về màn hình trước theo C.2.2
              },
              child: const Text('Đóng'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketQrScreen(datChoId: datChoId, maVe: maVe, tenTour: widget.tenTour),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              icon: const Icon(Icons.qr_code),
              label: const Text('Xem Vé QR'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);

      if (e.maLoi == 409) {
        // Điểm nhấn kỹ thuật đề 23: người khác vừa đặt mất chỗ cuối, máy chủ từ chối
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Không đủ chỗ'),
              ],
            ),
            content: Text(e.thongBao),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true); // Quay về để tải lại số chỗ mới nhất
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Chọn suất khác'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.thongBao), backgroundColor: Colors.redAccent),
        );
      }
    } on PhienHetHanException {
      if (!mounted) return;
      setState(() => _dangGui = false);
      final daDangNhap = await hienHopThoaiDangNhapTam(context);
      if (!mounted) return;
      if (daDangNhap) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng nhập, bấm Xác nhận đặt chỗ lần nữa')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối máy chủ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tongKhach = _soNguoiLon + _soTreEm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Đặt Tour - NhomNoName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin suất đã chọn
            Card(
              color: Colors.teal.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.teal.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.tenTour, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                    const SizedBox(height: 6),
                    Text('Ngày đi: ${widget.suat.ngayDi} | Giờ tập trung: ${widget.suat.gioTapTrung}'),
                    Text('Điểm đón: ${widget.suat.diemTapTrung}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      'Số chỗ còn nhận: ${widget.suat.soChoConLai} chỗ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              '1. CHỌN SỐ LƯỢNG HÀNH KHÁCH',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Bộ tăng giảm số lượng Người lớn & Trẻ em
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Người lớn (từ 12 tuổi)', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(_dinhDangTien.format(widget.giaNguoiLon), style: const TextStyle(color: Colors.teal, fontSize: 13)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _soNguoiLon > 1
                                  ? () {
                                      setState(() {
                                        _soNguoiLon--;
                                        _dongBoDanhSachHanhKhach();
                                      });
                                    }
                                  : null,
                            ),
                            Text('$_soNguoiLon', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                              onPressed: tongKhach < widget.suat.soChoConLai
                                  ? () {
                                      setState(() {
                                        _soNguoiLon++;
                                        _dongBoDanhSachHanhKhach();
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trẻ em (dưới 12 tuổi)', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(_dinhDangTien.format(widget.giaTreEm), style: const TextStyle(color: Colors.teal, fontSize: 13)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _soTreEm > 0
                                  ? () {
                                      setState(() {
                                        _soTreEm--;
                                        _dongBoDanhSachHanhKhach();
                                      });
                                    }
                                  : null,
                            ),
                            Text('$_soTreEm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                              onPressed: tongKhach < widget.suat.soChoConLai
                                  ? () {
                                      setState(() {
                                        _soTreEm++;
                                        _dongBoDanhSachHanhKhach();
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              '2. DANH SÁCH HÀNH KHÁCH (BẮT BUỘC KHAI BÁO)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Form nhập từng hành khách
            ..._dsHanhKhach.asMap().entries.map((entry) {
              final index = entry.key;
              final hk = entry.value;
              final laNguoiLon = hk.loaiVe == 'NGUOI_LON';

              return Card(
                // Gắn key theo đối tượng để ô nhập không bị lệch dữ liệu khi thêm/bớt khách
                key: ObjectKey(hk),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Khách #${index + 1}: ${laNguoiLon ? "Người lớn" : "Trẻ em"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: laNguoiLon ? Colors.teal : Colors.orange.shade800,
                            ),
                          ),
                          if (index == 0)
                            const Chip(
                              label: Text('Trưởng đoàn', style: TextStyle(fontSize: 11)),
                              backgroundColor: Colors.tealAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: hk.hoTen,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên hành khách';
                          }
                          if (val.trim().length < 2) {
                            return 'Họ tên quá ngắn';
                          }
                          return null;
                        },
                        onChanged: (val) => hk.hoTen = val.trim(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: hk.namSinh == 0 ? '' : hk.namSinh.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Năm sinh *',
                                prefixIcon: Icon(Icons.calendar_month),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                final nam = int.tryParse(val ?? '');
                                if (nam == null || nam < 1920 || nam > DateTime.now().year) {
                                  return 'Năm sinh không hợp lệ';
                                }
                                if (laNguoiLon && (DateTime.now().year - nam < 12)) {
                                  return 'Người lớn phải >= 12 tuổi';
                                }
                                if (!laNguoiLon && (DateTime.now().year - nam >= 12)) {
                                  return 'Trẻ em phải < 12 tuổi';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                final n = int.tryParse(val);
                                if (n != null) hk.namSinh = n;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: hk.cccd,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: laNguoiLon ? 'Số CCCD ${index == 0 ? "*" : ""}' : 'CCCD (nếu có)',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                if (laNguoiLon && index == 0 && (val == null || val.trim().isEmpty)) {
                                  return 'Trưởng đoàn cần CCCD';
                                }
                                if (val != null && val.trim().isNotEmpty && !RegExp(r'^\d{12}$').hasMatch(val.trim())) {
                                  return 'CCCD phải gồm đúng 12 chữ số';
                                }
                                return null;
                              },
                              onChanged: (val) => hk.cccd = val.trim(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            const Text(
              '3. DỊCH VỤ SINH THÁI KÈM THEO (TÙY CHỌN)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            if (_dangTaiDichVu)
              const Center(child: CircularProgressIndicator())
            else if (_loiDichVu != null)
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.cloud_off, color: Colors.orange),
                  title: Text(_loiDichVu!, style: const TextStyle(fontSize: 13)),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() {
                        _dangTaiDichVu = true;
                        _loiDichVu = null;
                      });
                      _taiDichVuKem();
                    },
                    child: const Text('Thử lại'),
                  ),
                ),
              )
            else
              ..._dsDichVu.map((dv) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dv.ten, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(
                                '${_dinhDangTien.format(dv.gia)} / ${dv.donVi}',
                                style: const TextStyle(color: Colors.teal, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: dv.soLuong > 0
                                  ? () {
                                      setState(() => dv.soLuong--);
                                    }
                                  : null,
                            ),
                            Text('${dv.soLuong}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                              onPressed: () {
                                setState(() => dv.soLuong++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Bảng tổng hợp chi phí tạm tính
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiền vé ($tongKhach khách):'),
                      Text(_dinhDangTien.format(_tongTienVe), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_tongTienDichVu > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dịch vụ kèm theo:'),
                        Text(_dinhDangTien.format(_tongTienDichVu), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG TIỀN TẠM TÍNH:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        _dinhDangTien.format(_tongTienTamTinh),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nút bấm đặt chỗ có chặn spam click
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _dangGui ? null : _xacNhanDatCho,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _dangGui
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _dangGui ? 'ĐANG GỬI XÁC NHẬN...' : 'XÁC NHẬN ĐẶT CHỖ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
