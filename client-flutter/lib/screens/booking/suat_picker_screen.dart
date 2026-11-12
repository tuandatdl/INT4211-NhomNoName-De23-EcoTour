import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';
import 'booking_form_screen.dart';

class SuatPickerScreen extends StatefulWidget {
  final int tourId;
  final String tenTour;
  final int giaNguoiLon;
  final int giaTreEm;

  const SuatPickerScreen({
    super.key,
    this.tourId = 1,
    this.tenTour = 'Tour 1: Khám phá Rừng Sác Cần Giờ - Đảo Khỉ 1 Ngày',
    this.giaNguoiLon = 650000,
    this.giaTreEm = 450000,
  });

  @override
  State<SuatPickerScreen> createState() => _SuatPickerScreenState();
}

class _SuatPickerScreenState extends State<SuatPickerScreen> {
  // Bắt buộc gán Future MỘT LẦN trong initState theo mục C.2.7 & Phụ lục 3
  late Future<List<SuatModel>> _tuongLaiSuat;
  final NumberFormat _dinhDangTien = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _taiDanhSachSuat();
  }

  void _taiDanhSachSuat() {
    setState(() {
      _tuongLaiSuat = ApiService.layDanhSachSuat(widget.tourId);
    });
  }

  String _dinhDangNgay(String ngayStr) {
    try {
      final date = DateTime.parse(ngayStr);
      return DateFormat('dd/MM/yyyy (EEEE)', 'vi_VN').format(date);
    } catch (_) {
      return ngayStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Suất Khởi Hành - NhomNoName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tóm tắt thông tin tour
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              border: Border(bottom: BorderSide(color: Colors.teal.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tenTour,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Người lớn: ${_dinhDangTien.format(widget.giaNguoiLon)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Trẻ em: ${_dinhDangTien.format(widget.giaTreEm)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CÁC SUẤT ĐANG MỞ BÁN',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.black54),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                  tooltip: 'Tải lại danh sách suất',
                  onPressed: _taiDanhSachSuat,
                ),
              ],
            ),
          ),

          // Hiển thị đầy đủ 3 trạng thái: Đang tải / Lỗi / Dữ liệu
          Expanded(
            child: FutureBuilder<List<SuatModel>>(
              future: _tuongLaiSuat,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 12),
                        Text('Đang kiểm tra số chỗ từ máy chủ...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 56, color: Colors.orange),
                          const SizedBox(height: 12),
                          const Text(
                            'Không thể kết nối đến máy chủ Render',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _taiDanhSachSuat,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final dsSuat = snapshot.data ?? [];
                if (dsSuat.isEmpty) {
                  return const Center(
                    child: Text('Hiện chưa có suất khởi hành nào mở cho tour này'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: dsSuat.length,
                  itemBuilder: (context, i) {
                    final s = dsSuat[i];
                    final hetCho = s.soChoConLai <= 0;
                    final sapHet = s.soChoConLai > 0 && s.soChoConLai <= 8;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: hetCho ? Colors.grey.shade300 : (sapHet ? Colors.orange.shade300 : Colors.teal.shade200),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: hetCho
                            ? null
                            : () async {
                                // Điều hướng sang Form Đặt chỗ
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => BookingFormScreen(
                                      suat: s,
                                      tenTour: widget.tenTour,
                                      giaNguoiLon: widget.giaNguoiLon,
                                      giaTreEm: widget.giaTreEm,
                                    ),
                                  ),
                                );

                                // Bắt buộc kiểm tra mounted sau await theo mục C.2.9
                                if (!mounted) return;
                                if (res == true) {
                                  _taiDanhSachSuat(); // Tải lại số chỗ sau khi đặt thành công
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
                                      const SizedBox(width: 8),
                                      Text(
                                        _dinhDangNgay(s.ngayDi),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  // Badge trạng thái số chỗ còn lại
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hetCho
                                          ? Colors.red.shade100
                                          : (sapHet ? Colors.orange.shade100 : Colors.green.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      hetCho
                                          ? 'HẾT CHỖ'
                                          : (sapHet ? 'Chỉ còn ${s.soChoConLai} chỗ!' : 'Còn ${s.soChoConLai} chỗ'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: hetCho
                                            ? Colors.red.shade800
                                            : (sapHet ? Colors.orange.shade900 : Colors.green.shade900),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Text('Tập trung: ${s.gioTapTrung}', style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.directions_bus, size: 16, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s.phuongTien,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s.diemTapTrung,
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                              if (s.tenHdv != null && s.tenHdv!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.teal),
                                    const SizedBox(width: 6),
                                    Text('HDV: ${s.tenHdv}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: hetCho
                                      ? null
                                      : () async {
                                          final res = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => BookingFormScreen(
                                                suat: s,
                                                tenTour: widget.tenTour,
                                                giaNguoiLon: widget.giaNguoiLon,
                                                giaTreEm: widget.giaTreEm,
                                              ),
                                            ),
                                          );
                                          if (!mounted) return;
                                          if (res == true) _taiDanhSachSuat();
                                        },
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: Text(hetCho ? 'Đã khóa' : 'Chọn suất này'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: hetCho ? Colors.grey : Colors.teal,
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
