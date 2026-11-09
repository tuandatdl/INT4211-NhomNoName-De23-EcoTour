const express = require('express');
const { truyVan } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

const router = express.Router();

// GET /bao-cao/lap-day - Thong ke ty le lap day va doanh thu theo tung tour va suat khoi hanh
router.get('/lap-day', xacThuc, choPhep('QUAN_TRI'), async (req, res) => {
  const { tour, tu, den } = req.query;

  let sql = `
    SELECT
      t.id AS tour_id,
      t.ten AS ten_tour,
      s.id AS suat_id,
      s.ngay_di,
      s.gio_tap_trung,
      s.so_cho AS tong_so_cho,
      COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::int AS so_khach_da_dat,
      ROUND(
        (COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::numeric /
        NULLIF(s.so_cho, 0)::numeric) * 100, 2
      ) AS ty_le_lap_day_phan_tram,
      COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN dc.tong_tien ELSE 0 END), 0)::numeric AS doanh_thu,
      COALESCE(SUM(CASE WHEN dc.trang_thai = 'DA_HUY' THEN dc.tien_hoan ELSE 0 END), 0)::numeric AS tong_tien_hoan
    FROM suat_khoi_hanh s
    JOIN tour t ON t.id = s.tour_id
    LEFT JOIN dat_cho dc ON dc.suat_id = s.id
    WHERE 1=1
  `;
  const params = [];

  if (tour) {
    params.push(Number(tour));
    sql += ` AND t.id = $${params.length}`;
  }
  if (tu) {
    params.push(tu);
    sql += ` AND s.ngay_di >= $${params.length}`;
  }
  if (den) {
    params.push(den);
    sql += ` AND s.ngay_di <= $${params.length}`;
  }

  sql += `
    GROUP BY t.id, t.ten, s.id, s.ngay_di, s.gio_tap_trung, s.so_cho
    ORDER BY s.ngay_di ASC, t.id ASC
  `;

  try {
    const r = await truyVan(sql, params);

    // Tinh tong quan toan bo ket qua loc
    const tongQuan = r.rows.reduce(
      (acc, row) => {
        acc.tongSoSuat += 1;
        acc.tongSoCho += row.tong_so_cho;
        acc.tongKhachDaDat += row.so_khach_da_dat;
        acc.tongDoanhThu += Number(row.doanh_thu);
        acc.tongTienHoan += Number(row.tong_tien_hoan);
        return acc;
      },
      { tongSoSuat: 0, tongSoCho: 0, tongKhachDaDat: 0, tongDoanhThu: 0, tongTienHoan: 0 }
    );

    const tyLeLapDayTrungBinh = tongQuan.tongSoCho > 0
      ? Number(((tongQuan.tongKhachDaDat / tongQuan.tongSoCho) * 100).toFixed(2))
      : 0;

    return res.status(200).json({
      tongQuan: {
        ...tongQuan,
        tyLeLapDayTrungBinh
      },
      chiTiet: r.rows
    });
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi tạo báo cáo tỷ lệ lấp đầy' });
  }
});

// GET /bao-cao/mua-cao-diem - Thong ke theo thang de ve bieu do mua cao diem
router.get('/mua-cao-diem', xacThuc, choPhep('QUAN_TRI'), async (req, res) => {
  try {
    const sql = `
      SELECT
        TO_CHAR(s.ngay_di, 'YYYY-MM') AS thang,
        COUNT(DISTINCT s.id)::int AS so_suat_mo,
        COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::int AS tong_so_khach,
        COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN dc.tong_tien ELSE 0 END), 0)::numeric AS tong_doanh_thu
      FROM suat_khoi_hanh s
      LEFT JOIN dat_cho dc ON dc.suat_id = s.id
      GROUP BY TO_CHAR(s.ngay_di, 'YYYY-MM')
      ORDER BY thang ASC
    `;

    const r = await truyVan(sql);
    return res.status(200).json(r.rows);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi thống kê dữ liệu mùa cao điểm' });
  }
});

module.exports = router;
