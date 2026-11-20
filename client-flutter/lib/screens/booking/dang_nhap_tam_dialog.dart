import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Hộp thoại đăng nhập TẠM THỜI để TV4 tự kiểm thử luồng đặt chỗ
/// trong lúc màn hình Đăng nhập/Đăng ký của TV3 chưa hoàn thành.
/// Khi TV3 xong, các màn hình chỉ cần điều hướng sang màn hình Đăng nhập chính thức.
/// Trả về true nếu đăng nhập thành công.
Future<bool> hienHopThoaiDangNhapTam(BuildContext context) async {
  final ketQua = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DangNhapTamDialog(),
  );
  return ketQua == true;
}

class _DangNhapTamDialog extends StatefulWidget {
  const _DangNhapTamDialog();

  @override
  State<_DangNhapTamDialog> createState() => _DangNhapTamDialogState();
}

class _DangNhapTamDialogState extends State<_DangNhapTamDialog> {
  final _formKey = GlobalKey<FormState>();
  // Tài khoản thử nghiệm ghi trong README của nhóm (mật khẩu chung 123456)
  final _emailCtrl = TextEditingController(text: 'khach2@gmail.com');
  final _matKhauCtrl = TextEditingController();
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _matKhauCtrl.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await ApiService.dangNhap(_emailCtrl.text.trim(), _matKhauCtrl.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dangGui = false;
        _loi = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cần đăng nhập để đặt chỗ'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
            ),
            TextFormField(
              controller: _matKhauCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
            ),
            if (_loi != null) ...[
              const SizedBox(height: 8),
              Text(_loi!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Để sau'),
        ),
        ElevatedButton(
          onPressed: _dangGui ? null : _dangNhap,
          child: _dangGui
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Đăng nhập'),
        ),
      ],
    );
  }
}
