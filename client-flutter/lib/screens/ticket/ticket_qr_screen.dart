import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';

class TicketQrScreen extends StatefulWidget {
  final int datChoId;
  final String maVe;
  final String tenTour;

  const TicketQrScreen({
    super.key,
    required this.datChoId,
    required this.maVe,
    required this.tenTour,
  });

  @override
  State<TicketQrScreen> createState() => _TicketQrScreenState();
}

class _TicketQrScreenState extends State<TicketQrScreen> {
  late Future<VeChiTietModel> _tuongLaiVe;
  final NumberFormat _dinhDangTien = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    // Bắt buộc gán Future MỘT LẦN trong initState theo mục C.2.7
    _tuongLaiVe = ApiService.layChiTietVe(widget.datChoId);
  }

  void _taiLai() {
    setState(() {
      _tuongLaiVe = ApiService.layChiTietVe(widget.datChoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vé Điện Tử EcoTour - NhomNoName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<VeChiTietModel>(
        future: _tuongLaiVe,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            // Trường hợp lỗi mạng, vẫn hiển thị mã QR tĩnh từ widget.maVe dự phòng
            return _xayDungGiaoDienVeDuPhong();
          }

          final ve = snapshot.data;
          if (ve == null) {
            return _xayDungGiaoDienVeDuPhong();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Tên tour và mã vé
                      Text(
                        ve.tenTour,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text(
                          'MÃ VÉ: ${ve.maVe}',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.teal),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mã QR Code dùng để HDV quét điểm danh lên xe/tàu
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.shade300, blurRadius: 8, spreadRadius: 2),
                          ],
                        ),
                        child: QrImageView(
                          data: ve.maVe,
                          version: QrVersions.auto,
                          size: 200.0,
                          gapless: true,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        'Quét mã này tại điểm đón để điểm danh lên xe/tàu',
                        style: TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                      ),

                      const Divider(height: 32),

                      // Thông tin chi tiết chuyến đi
                      _dongThongTin(Icons.calendar_month, 'Ngày khởi hành', ve.ngayDi),
                      _dongThongTin(Icons.access_time, 'Giờ tập trung', ve.gioTapTrung),
                      _dongThongTin(Icons.location_on, 'Điểm đón', ve.diemTapTrung),
                      _dongThongTin(Icons.directions_bus, 'Phương tiện', ve.phuongTien),
                      if (ve.hoTenHdv != null && ve.hoTenHdv!.isNotEmpty)
                        _dongThongTin(Icons.person, 'Hướng dẫn viên', '${ve.hoTenHdv} (${ve.sdtHdv ?? ""})'),
                      _dongThongTin(
                        Icons.group,
                        'Số lượng khách',
                        '${ve.soNguoiLon} người lớn, ${ve.soTreEm} trẻ em',
                      ),
                      _dongThongTin(Icons.payment, 'Tổng tiền đã thanh toán', _dinhDangTien.format(ve.tongTien)),

                      const Divider(height: 24),

                      // Danh sách tên hành khách trong vé
                      if (ve.dsHanhKhach.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DANH SÁCH HÀNH KHÁCH ĐI CÙNG:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...ve.dsHanhKhach.map((hk) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${hk['ho_ten']} (${hk['nam_sinh']}) - ${hk['loai_ve'] == 'NGUOI_LON' ? 'Người lớn' : 'Trẻ em'}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại danh sách'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dongThongTin(IconData icon, String tieuDe, String noiDung) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(text: '$tieuDe: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: noiDung),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _xayDungGiaoDienVeDuPhong() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.tenTour,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 8),
                Text('MÃ VÉ: ${widget.maVe}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 20),
                QrImageView(data: widget.maVe, size: 200),
                const SizedBox(height: 16),
                const Text('Mã vé ngoại tuyến sẵn sàng để điểm danh tại bến.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: _taiLai, icon: const Icon(Icons.refresh), label: const Text('Tải lại chi tiết')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
