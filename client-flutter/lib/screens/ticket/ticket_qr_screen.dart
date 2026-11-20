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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại thông tin vé',
            onPressed: _taiLai,
          ),
        ],
      ),
      body: FutureBuilder<VeChiTietModel>(
        future: _tuongLaiVe,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _xayDungGiaoDienVeDuPhong();
          }

          final ve = snapshot.data!;

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
                      const SizedBox(height: 6),
                      Chip(
                        avatar: Icon(
                          ve.daDiemDanhDu ? Icons.verified : Icons.schedule,
                          size: 16,
                          color: ve.daDiemDanhDu ? Colors.green : Colors.orange,
                        ),
                        label: Text(
                          ve.daDiemDanhDu ? 'Đoàn đã điểm danh đủ' : 'Chưa điểm danh tại điểm đón',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 16),

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
                        'Đưa mã QR này cho Hướng dẫn viên quét điểm danh tại bến tàu/xe',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                      ),

                      const Divider(height: 32),

                      // Thông tin chi tiết chuyến đi
                      _dongThongTin(Icons.calendar_month, 'Ngày khởi hành', ngayHienThi(ve.ngayDi)),
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
                      if (ve.tienHoan > 0)
                        _dongThongTin(Icons.replay, 'Số tiền đã hoàn', _dinhDangTien.format(ve.tienHoan)),

                      const Divider(height: 24),

                      // Danh sách hành khách kèm trạng thái điểm danh
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
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  hk.daDiemDanh ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: hk.daDiemDanh ? Colors.green : Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${hk.hoTen} (${hk.namSinh}) - ${hk.loaiVe == 'NGUOI_LON' ? 'Người lớn' : 'Trẻ em'}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  hk.daDiemDanh ? 'Đã lên xe' : 'Chờ quét',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hk.daDiemDanh ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Dịch vụ sinh thái đi kèm
                      if (ve.dsDichVu.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DỊCH VỤ SINH THÁI KÈM THEO:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...ve.dsDichVu.map((dv) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('• ${dv.ten} (x${dv.soLuong})', style: const TextStyle(fontSize: 13)),
                                ),
                                Text(
                                  _dinhDangTien.format(dv.gia * dv.soLuong),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
