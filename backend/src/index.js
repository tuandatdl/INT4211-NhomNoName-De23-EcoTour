const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { truyVan } = require('./db');
const { xacThuc, choPhep } = require('./middleware/auth');
const authRoutes = require('./routes/auth.routes');
const datChoRoutes = require('./routes/datCho.routes');
const { xuLyDiemDanhTour } = require('./routes/datCho.routes');
const baoCaoRoutes = require('./routes/baoCao.routes');
const tourRoutes = require('./routes/tour.routes');
const danhMucRoutes = require('./routes/danhMuc.routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// =============================================================================
// 1. HEALTH CHECK ENDPOINT
// =============================================================================
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    nhom: 'NhomNoName',
    deTai: 23,
    hocPhan: 'INT4211',
    thoiGian: new Date().toISOString()
  });
});

// =============================================================================
// 2. GẮN CÁC MODULE NGHIỆP VỤ CỦA TV1 (ĐỖ LÊ TUẤN ĐẠT - NHÓM TRƯỞNG)
// =============================================================================
app.use('/auth', authRoutes);
app.use('/dat-cho', datChoRoutes);
app.use('/bao-cao', baoCaoRoutes);

// Endpoint POST /diem-danh-tour theo đúng bảng đặc tả API đề bài
app.post('/diem-danh-tour', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), xuLyDiemDanhTour);

// =============================================================================
// 3. GẮN CÁC MODULE QUẢN LÝ CỦA TV2 (NGUYỄN NHẬT DUY)
// Khớp 100% với ApiService.java trên Android Admin
// =============================================================================
// Quản trị Tour & Suất khởi hành
app.use('/quan-ly/tour', tourRoutes);
app.use('/quan-ly/tours', tourRoutes);

// Hỗ trợ alias trực tiếp nếu gọi /quan-ly/suat/:id không kèm prefix /tour
app.use('/quan-ly/suat', (req, res, next) => {
  req.url = '/suat' + req.url;
  tourRoutes(req, res, next);
});

// Danh mục Hướng dẫn viên, Điểm đến, Dịch vụ kèm
app.use('/danh-muc', danhMucRoutes);
app.use('/', danhMucRoutes); // Hỗ trợ gọi tắt trực tiếp: /hdv, /diem-den, /dich-vu-kem

// =============================================================================
// 4. API CÔNG KHAI DÀNH CHO KHÁCH DU LỊCH & CLIENT MOBILE (FLUTTER)
// Duyệt danh sách tour, xem chi tiết, xem lịch trình và suất khởi hành
// =============================================================================

// GET /tour - Danh sách tour hoạt động kèm đánh giá sao trung bình và bộ lọc
app.get('/tour', async (req, res) => {
  try {
    const { khu_vuc, so_ngay, gia_max, tu_khoa } = req.query;
    let sql = `
      SELECT t.id, t.ten, t.mo_ta, t.so_ngay, t.gia_nguoi_lon, t.gia_tre_em, t.anh_url, t.trang_thai,
             COALESCE(ROUND(AVG(dg.so_sao_tour), 1), 5.0) AS danh_gia_sao,
             COUNT(DISTINCT dg.id)::int AS so_luot_danh_gia
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
    const r = await truyVan(sql, params);
    return res.status(200).json(r.rows);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy danh sách tour' });
  }
});

// GET /tour/:id - Chi tiết 1 tour công khai
app.get('/tour/:id', async (req, res) => {
  try {
    const sql = `
      SELECT t.id, t.ten, t.mo_ta, t.so_ngay, t.gia_nguoi_lon, t.gia_tre_em, t.anh_url, t.trang_thai,
             COALESCE(ROUND(AVG(dg.so_sao_tour), 1), 5.0) AS danh_gia_sao,
             COUNT(DISTINCT dg.id)::int AS so_luot_danh_gia
      FROM tour t
      LEFT JOIN suat_khoi_hanh s ON t.id = s.tour_id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id
      LEFT JOIN danh_gia dg ON dc.id = dg.dat_cho_id
      WHERE t.id = $1
      GROUP BY t.id
    `;
    const r = await truyVan(sql, [req.params.id]);
    if (r.rowCount === 0) {
      return res.status(404).json({ loi: 'Không tìm thấy tour du lịch' });
    }
    return res.status(200).json(r.rows[0]);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy chi tiết tour' });
  }
});

// GET /tour/:id/lich-trinh - Lịch trình chi tiết của tour theo thứ tự ngày và giờ
app.get('/tour/:id/lich-trinh', async (req, res) => {
  try {
    const sql = `
      SELECT lt.id, lt.tour_id, lt.ngay_thu, lt.thu_tu, lt.gio, lt.hoat_dong, lt.diem_den_id,
             dd.ten AS ten_diem_den, dd.khu_vuc AS khu_vuc_diem_den,
             dd.vi_do, dd.kinh_do, dd.anh_url AS anh_diem_den
      FROM lich_trinh lt
      LEFT JOIN diem_den dd ON lt.diem_den_id = dd.id
      WHERE lt.tour_id = $1
      ORDER BY lt.ngay_thu ASC, lt.thu_tu ASC
    `;
    const r = await truyVan(sql, [req.params.id]);
    return res.status(200).json(r.rows);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy lịch trình tour' });
  }
});

// GET /tour/:id/suat - Danh sách suất khởi hành kèm tính toán so_cho_con_lai
app.get('/tour/:id/suat', async (req, res) => {
  try {
    const sql = `
      SELECT s.id, s.tour_id, s.ngay_di, s.gio_tap_trung, s.diem_tap_trung,
             s.phuong_tien, s.so_cho, s.hdv_id,
             h.ho_ten AS ten_hdv, h.sdt AS sdt_hdv, s.trang_thai,
             COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::int AS so_cho_da_dat,
             (s.so_cho - COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0))::int AS so_cho_con_lai
      FROM suat_khoi_hanh s
      LEFT JOIN huong_dan_vien h ON s.hdv_id = h.id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id
      WHERE s.tour_id = $1
      GROUP BY s.id, h.ho_ten, h.sdt
      ORDER BY s.ngay_di ASC, s.gio_tap_trung ASC
    `;
    const r = await truyVan(sql, [req.params.id]);
    return res.status(200).json(r.rows);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy danh sách suất khởi hành' });
  }
});

// POST /danh-gia - Gửi đánh giá sao cho tour và hướng dẫn viên
app.post('/danh-gia', xacThuc, async (req, res) => {
  const { datChoId, soSaoTour, soSaoHdv, noiDung, anhUrl } = req.body;
  if (!datChoId || !soSaoTour || !soSaoHdv) {
    return res.status(400).json({ loi: 'Vui lòng cung cấp đầy đủ datChoId, soSaoTour và soSaoHdv' });
  }

  try {
    const r = await truyVan(
      `INSERT INTO danh_gia (dat_cho_id, so_sao_tour, so_sao_hdv, noi_dung, anh_url, tao_luc)
       VALUES ($1, $2, $3, $4, $5, NOW())
       ON CONFLICT (dat_cho_id) DO UPDATE
       SET so_sao_tour = EXCLUDED.so_sao_tour,
           so_sao_hdv = EXCLUDED.so_sao_hdv,
           noi_dung = EXCLUDED.noi_dung,
           anh_url = EXCLUDED.anh_url
       RETURNING *`,
      [datChoId, Number(soSaoTour), Number(soSaoHdv), noiDung || null, anhUrl || null]
    );
    return res.status(201).json(r.rows[0]);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi gửi đánh giá' });
  }
});

// =============================================================================
// 5. KHỞI CHẠY MÁY CHỦ
// =============================================================================
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`[ECOTOUR-BACKEND] Server đang chạy tại cổng http://localhost:${PORT}`);
    console.log(`[ECOTOUR-BACKEND] Endpoint kiểm tra: http://localhost:${PORT}/health`);
  });
}

module.exports = app;
