const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const { truyVan, trongGiaoDich } = require('./db');
const { xacThuc, choPhep } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'chuoi_bi_mat_ngau_nhien_it_nhat_32_ky_tu_nhom_noname';

app.use(cors());
app.use(express.json());

// =============================================================================
// 1. HEALTH CHECK
// =============================================================================
app.get('/health', (req, res) => {
  res.json({
    trangThai: 'OK',
    thoiGian: new Date().toISOString(),
    nhom: 'Nhóm NoName',
    deTai: 'Đề 23 - Hệ thống đặt tour du lịch sinh thái Cần Giờ – Vũng Tàu',
    hocPhan: 'INT4211 - Phát triển ứng dụng di động và phân tán',
    thanhVien: [
      { mssv: '231A290089', hoTen: 'Đỗ Lê Tuấn Đạt', vaiTro: 'Nhóm trưởng / Backend' },
      { mssv: '231A010060', hoTen: 'Nguyễn Nhật Duy', vaiTro: 'Database / Admin Dev' },
      { mssv: '221A010146', hoTen: 'Phan Thị Anh Thư', vaiTro: 'Client Flutter' },
      { mssv: '231A290127', hoTen: 'Bùi Quang Duy', vaiTro: 'Client Flutter' }
    ]
  });
});

// =============================================================================
// 2. AUTHENTICATION (ĐĂNG KÝ / ĐĂNG NHẬP)
// =============================================================================

/**
 * Đăng ký tài khoản Khách du lịch mới
 * POST /auth/dang-ky
 */
app.post('/auth/dang-ky', async (req, res) => {
  try {
    const { email, mat_khau, ho_ten, sdt } = req.body;

    if (!email || !mat_khau || !ho_ten) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: email, mat_khau, ho_ten'
      });
    }

    // Kiểm tra email đã tồn tại hay chưa
    const kiemTra = await truyVan('SELECT id FROM nguoi_dung WHERE email = $1', [email.toLowerCase().trim()]);
    if (kiemTra.rows.length > 0) {
      return res.status(409).json({
        thanhCong: false,
        thongBao: 'Email này đã được đăng ký trong hệ thống'
      });
    }

    // Mã hóa mật khẩu
    const salt = await bcrypt.genSalt(10);
    const matKhauHash = await bcrypt.hash(mat_khau, salt);

    // Mặc định người dùng đăng ký qua App là KHACH
    const sqlInsert = `
      INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, vai_tro, tao_luc)
      VALUES ($1, $2, $3, $4, 'KHACH', NOW())
      RETURNING id, email, ho_ten, sdt, vai_tro, tao_luc
    `;
    const ketQua = await truyVan(sqlInsert, [email.toLowerCase().trim(), matKhauHash, ho_ten.trim(), sdt || null]);
    const nguoiDungMoi = ketQua.rows[0];

    // Tạo JWT token
    const token = jwt.sign(
      {
        id: nguoiDungMoi.id,
        email: nguoiDungMoi.email,
        ho_ten: nguoiDungMoi.ho_ten,
        vai_tro: nguoiDungMoi.vai_tro
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Đăng ký tài khoản thành công',
      duLieu: {
        nguoiDung: nguoiDungMoi,
        token
      }
    });
  } catch (error) {
    console.error('Lỗi API /auth/dang-ky:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi đăng ký tài khoản',
      chiTiet: error.message
    });
  }
});

/**
 * Đăng nhập hệ thống
 * POST /auth/dang-nhap
 */
app.post('/auth/dang-nhap', async (req, res) => {
  try {
    const { email, mat_khau } = req.body;

    if (!email || !mat_khau) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp email và mật khẩu'
      });
    }

    const sql = 'SELECT id, email, mat_khau_hash, ho_ten, sdt, vai_tro FROM nguoi_dung WHERE email = $1';
    const ketQua = await truyVan(sql, [email.toLowerCase().trim()]);

    if (ketQua.rows.length === 0) {
      return res.status(401).json({
        thanhCong: false,
        thongBao: 'Tài khoản hoặc mật khẩu không chính xác'
      });
    }

    const nguoiDung = ketQua.rows[0];
    const matKhauDung = await bcrypt.compare(mat_khau, nguoiDung.mat_khau_hash);

    if (!matKhauDung) {
      return res.status(401).json({
        thanhCong: false,
        thongBao: 'Tài khoản hoặc mật khẩu không chính xác'
      });
    }

    const token = jwt.sign(
      {
        id: nguoiDung.id,
        email: nguoiDung.email,
        ho_ten: nguoiDung.ho_ten,
        vai_tro: nguoiDung.vai_tro
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    delete nguoiDung.mat_khau_hash;

    res.json({
      thanhCong: true,
      thongBao: 'Đăng nhập thành công',
      duLieu: {
        nguoiDung,
        token
      }
    });
  } catch (error) {
    console.error('Lỗi API /auth/dang-nhap:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi đăng nhập',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// 3. TOUR & LỊCH TRÌNH & SUẤT KHỞI HÀNH
// =============================================================================

/**
 * Danh sách Tour du lịch sinh thái (có hỗ trợ lọc khu vực, số ngày, giá)
 * GET /tour
 */
app.get('/tour', async (req, res) => {
  try {
    const { khu_vuc, so_ngay, gia_max, tu_khoa } = req.query;

    let sql = `
      SELECT t.id, t.ten, t.mo_ta, t.so_ngay, t.gia_nguoi_lon, t.gia_tre_em, t.anh_url, t.trang_thai,
             COALESCE(ROUND(AVG(dg.so_sao_tour), 1), 5.0) AS danh_gia_sao,
             COUNT(DISTINCT dg.id)::INT AS so_luot_danh_gia
      FROM tour t
      LEFT JOIN suat_khoi_hanh s ON t.id = s.tour_id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id
      LEFT JOIN danh_gia dg ON dc.id = dg.dat_cho_id
      WHERE t.trang_thai = 'HOAT_DONG'
    `;
    const params = [];

    if (so_ngay) {
      params.push(parseInt(so_ngay, 10));
      sql += ` AND t.so_ngay = $${params.length}`;
    }

    if (gia_max) {
      params.push(parseFloat(gia_max));
      sql += ` AND t.gia_nguoi_lon <= $${params.length}`;
    }

    if (tu_khoa) {
      params.push(`%${tu_khoa}%`);
      sql += ` AND (t.ten ILIKE $${params.length} OR t.mo_ta ILIKE $${params.length})`;
    }

    sql += ` GROUP BY t.id ORDER BY t.id ASC`;

    const ketQua = await truyVan(sql, params);

    res.json({
      thanhCong: true,
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /tour:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy danh sách tour',
      chiTiet: error.message
    });
  }
});

/**
 * Lịch trình chi tiết theo giờ của một Tour
 * GET /tour/:id/lich-trinh
 */
app.get('/tour/:id/lich-trinh', async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);

    const sqlTour = 'SELECT id, ten, so_ngay FROM tour WHERE id = $1';
    const resTour = await truyVan(sqlTour, [tourId]);
    if (resTour.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

    const sql = `
      SELECT lt.id, lt.tour_id, lt.ngay_thu, lt.thu_tu, lt.gio, lt.hoat_dong, lt.diem_den_id,
             dd.ten AS ten_diem_den, dd.khu_vuc AS khu_vuc_diem_den,
             dd.vi_do, dd.kinh_do, dd.anh_url AS anh_diem_den
      FROM lich_trinh lt
      LEFT JOIN diem_den dd ON lt.diem_den_id = dd.id
      WHERE lt.tour_id = $1
      ORDER BY lt.ngay_thu ASC, lt.thu_tu ASC
    `;
    const ketQua = await truyVan(sql, [tourId]);

    res.json({
      thanhCong: true,
      tour: resTour.rows[0],
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /tour/:id/lich-trinh:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy lịch trình tour',
      chiTiet: error.message
    });
  }
});

/**
 * Danh sách Suất khởi hành của Tour (kèm tính toán `so_cho_con_lai`)
 * GET /tour/:id/suat
 */
app.get('/tour/:id/suat', async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);

    const sql = `
      SELECT
        s.id,
        s.tour_id,
        s.ngay_di,
        s.gio_tap_trung,
        s.diem_tap_trung,
        s.phuong_tien,
        s.so_cho,
        s.hdv_id,
        h.ho_ten AS ten_hdv,
        h.sdt AS sdt_hdv,
        s.trang_thai,
        COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::INT AS so_cho_da_dat,
        (s.so_cho - COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0))::INT AS so_cho_con_lai
      FROM suat_khoi_hanh s
      LEFT JOIN huong_dan_vien h ON s.hdv_id = h.id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id
      WHERE s.tour_id = $1
      GROUP BY s.id, h.ho_ten, h.sdt
      ORDER BY s.ngay_di ASC, s.gio_tap_trung ASC
    `;

    const ketQua = await truyVan(sql, [tourId]);

    res.json({
      thanhCong: true,
      tour_id: tourId,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /tour/:id/suat:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy suất khởi hành',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// 4. API ĐẶT CHỖ (TRANSACTION + SELECT ... FOR UPDATE CHỐNG VƯỢT CHỖ)
// =============================================================================

/**
 * Đặt chỗ tour du lịch
 * POST /dat-cho
 * Yêu cầu:
 * - Transaction ACID
 * - SELECT ... FOR UPDATE khóa hàng suat_khoi_hanh
 * - Tự động tính tổng tiền trên server
 * - Sinh mã vé duy nhất
 * - Trả mã 409 nếu không đủ chỗ
 */
app.post('/dat-cho', async (req, res) => {
  // Trích xuất thông tin khách nếu có token, hoặc nhận khach_id từ body
  let khachId = req.body.khach_id;
  const authHeader = req.headers['authorization'] || req.headers['Authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
      khachId = decoded.id;
    } catch {
      // bỏ qua, sử dụng khach_id từ body
    }
  }

  const { suat_id, so_nguoi_lon = 1, so_tre_em = 0, hanh_khach = [], dich_vu = [] } = req.body;

  if (!suat_id) {
    return res.status(400).json({
      thanhCong: false,
      thongBao: 'Vui lòng cung cấp suat_id'
    });
  }

  const soNguoiLon = parseInt(so_nguoi_lon, 10);
  const soTreEm = parseInt(so_tre_em, 10);
  const tongChoYeuCau = soNguoiLon + soTreEm;

  if (tongChoYeuCau <= 0) {
    return res.status(400).json({
      thanhCong: false,
      thongBao: 'Tổng số hành khách (người lớn + trẻ em) phải lớn hơn 0'
    });
  }

  try {
    const ketQuaDatCho = await trongGiaoDich(async (client) => {
      // 1. Khóa dòng suất khởi hành để kiểm tra và chống tranh chấp đồng thời (Race Condition)
      const suatRes = await client.query(
        'SELECT id, tour_id, so_cho, trang_thai FROM suat_khoi_hanh WHERE id = $1 FOR UPDATE',
        [suat_id]
      );

      if (suatRes.rows.length === 0) {
        const err = new Error('Suất khởi hành không tồn tại');
        err.statusCode = 404;
        throw err;
      }

      const suat = suatRes.rows[0];
      if (suat.trang_thai !== 'MO_BAN') {
        const err = new Error(`Suất khởi hành hiện không mở bán (Trạng thái: ${suat.trang_thai})`);
        err.statusCode = 400;
        throw err;
      }

      // 2. Tính số chỗ đã đặt hiện tại (loại trừ các đơn đã hủy)
      const choDatRes = await client.query(
        `SELECT COALESCE(SUM(so_nguoi_lon + so_tre_em), 0)::INT AS cho_da_dat
         FROM dat_cho
         WHERE suat_id = $1 AND trang_thai != 'DA_HUY'`,
        [suat_id]
      );
      const choDaDat = choDatRes.rows[0].cho_da_dat;
      const soChoConLai = suat.so_cho - choDaDat;

      // 3. Kiểm tra số chỗ còn lại, nếu vượt quá trả về lỗi 409 Conflict
      if (tongChoYeuCau > soChoConLai) {
        const err = new Error(`Suất khởi hành không đủ số chỗ còn lại (Chỉ còn ${soChoConLai} chỗ, yêu cầu ${tongChoYeuCau} chỗ)`);
        err.statusCode = 409;
        throw err;
      }

      // 4. Lấy đơn giá tour để máy chủ tự tính tổng tiền chính xác
      const tourRes = await client.query(
        'SELECT gia_nguoi_lon, gia_tre_em FROM tour WHERE id = $1',
        [suat.tour_id]
      );
      const { gia_nguoi_lon, gia_tre_em } = tourRes.rows[0];
      let tongTien = (soNguoiLon * parseFloat(gia_nguoi_lon)) + (soTreEm * parseFloat(gia_tre_em));

      // 5. Tính thêm tiền các dịch vụ kèm theo (nếu có)
      const danhSachDichVuHopLe = [];
      if (Array.isArray(dich_vu) && dich_vu.length > 0) {
        for (const dv of dich_vu) {
          const dvRes = await client.query(
            'SELECT id, gia, ten FROM dich_vu_kem WHERE id = $1',
            [dv.dich_vu_id]
          );
          if (dvRes.rows.length > 0) {
            const dvInfo = dvRes.rows[0];
            const soLuong = parseInt(dv.so_luong || 1, 10);
            tongTien += parseFloat(dvInfo.gia) * soLuong;
            danhSachDichVuHopLe.push({ dich_vu_id: dvInfo.id, so_luong: soLuong, ten: dvInfo.ten, gia: dvInfo.gia });
          }
        }
      }

      // 6. Tự động sinh mã vé duy nhất: ECO-YYYYMMDD-XXXX
      const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const randomCode = Math.random().toString(36).substring(2, 6).toUpperCase();
      const maVe = `ECO-${todayStr}-${randomCode}`;

      // Nếu không có khachId, mặc định lấy ID của khách đầu tiên trong hệ thống
      const finalKhachId = khachId || 3;

      // 7. Chèn dữ liệu vào bảng dat_cho
      const datChoInsertSql = `
        INSERT INTO dat_cho (suat_id, khach_id, so_nguoi_lon, so_tre_em, tong_tien, tien_hoan, ma_ve, trang_thai, dat_luc)
        VALUES ($1, $2, $3, $4, $5, 0, $6, 'DA_DAT', NOW())
        RETURNING id, suat_id, khach_id, so_nguoi_lon, so_tre_em, tong_tien, ma_ve, trang_thai, dat_luc
      `;
      const datChoRes = await client.query(datChoInsertSql, [
        suat_id,
        finalKhachId,
        soNguoiLon,
        soTreEm,
        tongTien,
        maVe
      ]);
      const donDatChoMoi = datChoRes.rows[0];

      // 8. Chèn danh sách hành khách đi cùng
      if (Array.isArray(hanh_khach) && hanh_khach.length > 0) {
        for (const hk of hanh_khach) {
          await client.query(
            `INSERT INTO hanh_khach (dat_cho_id, ho_ten, nam_sinh, cccd, loai_ve)
             VALUES ($1, $2, $3, $4, $5)`,
            [
              donDatChoMoi.id,
              hk.ho_ten || 'Hành khách chưa đặt tên',
              hk.nam_sinh || null,
              hk.cccd || null,
              hk.loai_ve === 'TRE_EM' ? 'TRE_EM' : 'NGUOI_LON'
            ]
          );
        }
      } else {
        // Tự động tạo 1 hành khách mặc định đại diện
        await client.query(
          `INSERT INTO hanh_khach (dat_cho_id, ho_ten, nam_sinh, cccd, loai_ve)
           VALUES ($1, $2, $3, $4, 'NGUOI_LON')`,
          [donDatChoMoi.id, 'Người đặt vé', 1995, null]
        );
      }

      // 9. Chèn dịch vụ kèm theo vào bảng dat_dich_vu
      for (const dv of danhSachDichVuHopLe) {
        await client.query(
          `INSERT INTO dat_dich_vu (dat_cho_id, dich_vu_id, so_luong)
           VALUES ($1, $2, $3)
           ON CONFLICT (dat_cho_id, dich_vu_id) DO UPDATE SET so_luong = EXCLUDED.so_luong`,
          [donDatChoMoi.id, dv.dich_vu_id, dv.so_luong]
        );
      }

      // Cập nhật trạng thái suất nếu đã kín chỗ
      if (soChoConLai - tongChoYeuCau === 0) {
        await client.query("UPDATE suat_khoi_hanh SET trang_thai = 'HET_CHO' WHERE id = $1", [suat_id]);
      }

      return donDatChoMoi;
    });

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Đặt chỗ thành công! Đã tạo vé điện tử QR Code.',
      duLieu: ketQuaDatCho
    });
  } catch (error) {
    console.error('Lỗi API POST /dat-cho:', error);
    const status = error.statusCode || 500;
    res.status(status).json({
      thanhCong: false,
      thongBao: error.message || 'Lỗi hệ thống khi thực hiện đặt chỗ'
    });
  }
});

// =============================================================================
// 5. BÁO CÁO TỶ LỆ LẤP ĐẦY & DOANH THU (DÀNH CHO QUẢN TRỊ VIÊN)
// =============================================================================

/**
 * Báo cáo tỷ lệ lấp đầy & tổng doanh thu các tour du lịch sinh thái
 * GET /bao-cao/lap-day
 * Yêu cầu: Xác thực JWT & Quyền QUAN_TRI
 */
app.get('/bao-cao/lap-day', xacThuc, choPhep('QUAN_TRI'), async (req, res) => {
  try {
    const sql = `
      SELECT
        t.id AS tour_id,
        t.ten AS ten_tour,
        t.so_ngay,
        t.gia_nguoi_lon,
        COUNT(DISTINCT s.id)::INT AS tong_so_suat,
        COALESCE(SUM(s.so_cho), 0)::INT AS tong_suc_chua,
        COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::INT AS tong_cho_da_dat,
        CASE
          WHEN COALESCE(SUM(s.so_cho), 0) = 0 THEN 0
          ELSE ROUND(
            (COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::NUMERIC /
             NULLIF(SUM(s.so_cho), 0)::NUMERIC) * 100, 2
          )
        END AS ti_le_lap_day_phan_tram,
        COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN dc.tong_tien ELSE 0 END), 0)::NUMERIC AS tong_doanh_thu
      FROM tour t
      LEFT JOIN suat_khoi_hanh s ON t.id = s.tour_id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id
      GROUP BY t.id, t.ten, t.so_ngay, t.gia_nguoi_lon
      ORDER BY tong_doanh_thu DESC, ti_le_lap_day_phan_tram DESC
    `;

    const ketQua = await truyVan(sql);

    // Tính toán tổng quan toàn hệ thống
    const tongQuan = ketQua.rows.reduce(
      (acc, cur) => {
        acc.tongSucChua += cur.tong_suc_chua;
        acc.tongChoDaDat += cur.tong_cho_da_dat;
        acc.tongDoanhThu += parseFloat(cur.tong_doanh_thu);
        return acc;
      },
      { tongSucChua: 0, tongChoDaDat: 0, tongDoanhThu: 0 }
    );

    const tiLeLapDayTrungBinh = tongQuan.tongSucChua > 0
      ? ((tongQuan.tongChoDaDat / tongQuan.tongSucChua) * 100).toFixed(2)
      : 0;

    res.json({
      thanhCong: true,
      ngayXuatBaoCao: new Date().toISOString(),
      tongQuan: {
        tongSucChuaToanHeThong: tongQuan.tongSucChua,
        tongChoDaDatToanHeThong: tongQuan.tongChoDaDat,
        tiLeLapDayTrungBinh: parseFloat(tiLeLapDayTrungBinh),
        tongDoanhThuToanHeThong: tongQuan.tongDoanhThu
      },
      chiTietTungTour: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /bao-cao/lap-day:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi tạo báo cáo tỷ lệ lấp đầy',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// KHỞI ĐỘNG SERVER
// =============================================================================
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`[ECOTOUR-BACKEND] Server đang chạy tại cổng http://localhost:${PORT}`);
    console.log(`[ECOTOUR-BACKEND] Endpoint kiểm tra: http://localhost:${PORT}/health`);
  });
}

module.exports = app;
