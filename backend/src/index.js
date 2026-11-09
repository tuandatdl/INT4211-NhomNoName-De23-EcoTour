const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const { truyVan } = require('./db');
const { xacThuc, choPhep } = require('./middleware/auth');
const authRoutes = require('./routes/auth.routes');
const datChoRoutes = require('./routes/datCho.routes');
const { xuLyDiemDanhTour } = require('./routes/datCho.routes');
const baoCaoRoutes = require('./routes/baoCao.routes');

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
// 2. GẮN CÁC MODULE ROUTE CHÍNH
// =============================================================================
app.use('/auth', authRoutes);
app.use('/dat-cho', datChoRoutes);
app.use('/bao-cao', baoCaoRoutes);

// Endpoint POST /diem-danh-tour theo dung bang dac ta API de bai
app.post('/diem-danh-tour', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), xuLyDiemDanhTour);

// =============================================================================
// 3. TỰ ĐỘNG TÍCH HỢP ROUTE CỦA THÀNH VIÊN KHÁC (NẾU CÓ)
// =============================================================================
const tourRoutesPath = path.join(__dirname, 'routes', 'tour.routes.js');
const danhMucRoutesPath = path.join(__dirname, 'routes', 'danhMuc.routes.js');

let daGanTourRoutes = false;
let daGanDanhMucRoutes = false;

if (fs.existsSync(tourRoutesPath)) {
  try {
    app.use('/tour', require('./routes/tour.routes'));
    daGanTourRoutes = true;
  } catch (err) {
    console.warn('[ROUTER] Chưa thể nạp tour.routes.js:', err.message);
  }
}

if (fs.existsSync(danhMucRoutesPath)) {
  try {
    app.use('/', require('./routes/danhMuc.routes'));
    daGanDanhMucRoutes = true;
  } catch (err) {
    console.warn('[ROUTER] Chưa thể nạp danhMuc.routes.js:', err.message);
  }
}

// =============================================================================
// 4. ROUTE DỰ PHÒNG (FALLBACK) ĐẢM BẢO BACKEND CHẠY ĐỘC LẬP KHI CHƯA CÓ FILE TV2
// =============================================================================
if (!daGanTourRoutes) {
  // GET /tour - Danh sach tour kem danh gia sao
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

  // GET /tour/:id/lich-trinh - Lich trinh chi tiet cua tour
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

  // GET /tour/:id/suat - Danh sach suat khoi hanh kem tinh toan so_cho_con_lai
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
}

if (!daGanDanhMucRoutes) {
  // GET /dich-vu-kem - Danh muc dich vu sinh thai di kem
  app.get('/dich-vu-kem', async (req, res) => {
    try {
      const r = await truyVan('SELECT id, ten, gia, don_vi FROM dich_vu_kem ORDER BY id ASC');
      return res.status(200).json(r.rows);
    } catch (e) {
      return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy danh mục dịch vụ kèm' });
    }
  });

  // GET /diem-den - Danh muc 10 diem den du lich sinh thai Can Gio - Vung Tau
  app.get('/diem-den', async (req, res) => {
    try {
      const r = await truyVan('SELECT id, ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url FROM diem_den ORDER BY id ASC');
      return res.status(200).json(r.rows);
    } catch (e) {
      return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy danh mục điểm đến' });
    }
  });

  // POST /danh-gia - Gui danh gia sao cho tour va huong dan vien
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
}

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
