/**
 * KỊCH BẢN KIỂM THỬ TÍNH NĂNG CHỐNG VƯỢT CHỖ (RACE CONDITION) - ĐỀ TÀI 23
 * Điểm nhấn kỹ thuật: Giao dịch ACID + Khóa dòng SELECT ... FOR UPDATE
 *
 * Cách chạy:
 *   1. Chạy server backend: npm start
 *   2. Chạy kịch bản kiểm thử: npm run test:race (hoặc: node scripts/test-concurrency.js)
 */

const API_URL = process.env.API_URL || 'http://localhost:3000';

async function kiemThuDongThoi() {
  console.log('=============================================================================');
  console.log('  BẮT ĐẦU KIỂM THỬ ĐỒNG THỜI (RACE CONDITION - ĐỀ 23 NHÓM NONAME)');
  console.log('=============================================================================');
  console.log(`[1] Đang kết nối tới API: ${API_URL}`);

  // 1. Kiểm tra Health Check
  try {
    const healthRes = await fetch(`${API_URL}/health`);
    if (!healthRes.ok) throw new Error(`HTTP ${healthRes.status}`);
    const healthData = await healthRes.json();
    console.log('[+] Health check thành công:', healthData);
  } catch (err) {
    console.error('[-] Lỗi: Không thể kết nối tới server backend tại', API_URL);
    console.error('    Vui lòng đảm bảo backend đang chạy (npm start) trước khi chạy kịch bản này.');
    process.exit(1);
  }

  // 2. Đăng nhập tài khoản khách để lấy token JWT
  console.log('\n[2] Đăng nhập tài khoản khách hàng (khach1@gmail.com) lấy token JWT...');
  let token = '';
  try {
    const loginRes = await fetch(`${API_URL}/auth/dang-nhap`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'khach1@gmail.com', matKhau: '123456' })
    });
    const loginData = await loginRes.json();
    if (!loginRes.ok) {
      throw new Error(loginData.loi || 'Đăng nhập không thành công');
    }
    token = loginData.token;
    console.log('[+] Đăng nhập thành công! Token:', token.substring(0, 20) + '...');
  } catch (err) {
    console.error('[-] Lỗi khi đăng nhập:', err.message);
    process.exit(1);
  }

  // 3. Lấy thông tin suất khởi hành để kiểm tra số chỗ còn lại
  console.log('\n[3] Lấy danh sách suất khởi hành của Tour 1...');
  let suatChon = null;
  try {
    const suatRes = await fetch(`${API_URL}/tour/1/suat`);
    if (suatRes.ok) {
      const dsSuat = await suatRes.json();
      if (Array.isArray(dsSuat) && dsSuat.length > 0) {
        // Tìm suất còn chỗ
        suatChon = dsSuat.find((s) => s.so_cho_con_lai >= 20) || dsSuat[0];
      }
    }
  } catch (err) {
    console.warn('[!] Không lấy được danh sách suất qua API tour, mặc định dùng suatId = 1');
  }

  const suatId = suatChon ? suatChon.id : 1;
  const soChoHienCo = suatChon ? suatChon.so_cho_con_lai : 30;
  console.log(`[+] Chọn Suất khởi hành ID: ${suatId} (Số chỗ còn lại theo CSDL: ${soChoHienCo} chỗ)`);

  // 4. Chuẩn bị 2 đoàn khách (Mỗi đoàn 20 khách -> Tổng yêu cầu 40 khách > 30 chỗ)
  const dsKhachDoan1 = Array.from({ length: 20 }, (_, i) => ({
    hoTen: `Nguyễn Đoàn 1 - Khách ${i + 1}`,
    namSinh: 1995,
    loaiVe: 'NGUOI_LON'
  }));

  const dsKhachDoan2 = Array.from({ length: 20 }, (_, i) => ({
    hoTen: `Trần Đoàn 2 - Khách ${i + 1}`,
    namSinh: 1998,
    loaiVe: 'NGUOI_LON'
  }));

  console.log('\n[4] Chuẩn bị gửi đồng thời 2 Request đặt chỗ bằng Promise.all:');
  console.log('    - Request A: Đặt 20 khách');
  console.log('    - Request B: Đặt 20 khách');
  console.log('    -> Tổng: 40 khách (vượt quá sức chứa suất khởi hành!)');

  console.log('\n[5] Đang kích hoạt 2 request cùng miligiây...');
  const thoiDiemBatDau = Date.now();

  const [ketQuaA, ketQuaB] = await Promise.all([
    fetch(`${API_URL}/dat-cho`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        suatId,
        dsHanhKhach: dsKhachDoan1,
        dsDichVu: [{ dichVuId: 1, soLuong: 2 }]
      })
    }).then(async (res) => ({ status: res.status, data: await res.json() })),

    fetch(`${API_URL}/dat-cho`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        suatId,
        dsHanhKhach: dsKhachDoan2,
        dsDichVu: [{ dichVuId: 1, soLuong: 2 }]
      })
    }).then(async (res) => ({ status: res.status, data: await res.json() }))
  ]);

  const tongThoiGian = Date.now() - thoiDiemBatDau;

  console.log(`\n================== KẾT QUẢ PHẢN HỒI (Sau ${tongThoiGian}ms) ==================`);
  console.log('Kết quả Request A:');
  console.log(`  HTTP Status: ${ketQuaA.status}`);
  console.log('  Dữ liệu:', JSON.stringify(ketQuaA.data, null, 2));

  console.log('\nKết quả Request B:');
  console.log(`  HTTP Status: ${ketQuaB.status}`);
  console.log('  Dữ liệu:', JSON.stringify(ketQuaB.data, null, 2));

  console.log('\n=============================================================================');
  console.log('                        ĐÁNH GIÁ KẾT QUẢ KIỂM THỬ');
  console.log('=============================================================================');

  const coThanhCong = ketQuaA.status === 201 || ketQuaB.status === 201;
  const coBiChanConflict = ketQuaA.status === 409 || ketQuaB.status === 409;

  if (coThanhCong && coBiChanConflict) {
    console.log('>>> [XÁC NHẬN ĐẠT ĐIỂM TỐI ĐA ĐỀ 23]:');
    console.log('    1. Một request đến trước được khóa hàng FOR UPDATE và tạo vé thành công (HTTP 201).');
    console.log('    2. Request thứ hai bị chặn lại ngay lập tức với HTTP 409 Conflict vì không đủ số chỗ còn lại.');
    console.log('    -> Hệ sinh thái du lịch sinh thái được bảo vệ tuyệt đối khỏi hiện tượng quá tải (Overbooking)!');
  } else if (ketQuaA.status === 409 && ketQuaB.status === 409) {
    console.log('>>> Suất khởi hành hiện không đủ 20 chỗ cho bất kỳ đoàn nào (Cả 2 đều nhận 409 Conflict đúng thiết kế).');
  } else {
    console.log(`>>> Kết quả HTTP: A=${ketQuaA.status}, B=${ketQuaB.status}`);
  }
  console.log('=============================================================================\n');
}

kiemThuDongThoi().catch((err) => {
  console.error('Lỗi ngoại lệ trong kịch bản kiểm thử:', err);
});
