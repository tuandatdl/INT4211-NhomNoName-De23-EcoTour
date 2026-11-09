const express = require('express');
const crypto = require('crypto');
const { truyVan, trongGiaoDich } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

const router = express.Router();

// POST /dat-cho - Diem nhan ky thuat De 23: Giao dich kiem tra va tru cho co khoa dong FOR UPDATE
router.post('/', xacThuc, async (req, res) => {
  const { suatId, dsHanhKhach = [], dsDichVu = [] } = req.body;
  const khachId = req.nguoiDung.id;

  if (!suatId || !Array.isArray(dsHanhKhach) || dsHanhKhach.length === 0) {
    return res.status(400).json({ loi: 'Thiếu mã suất khởi hành hoặc danh sách hành khách' });
  }

  for (const hk of dsHanhKhach) {
    if (!hk.hoTen || !hk.namSinh || !['NGUOI_LON', 'TRE_EM'].includes(hk.loaiVe)) {
      return res.status(400).json({ loi: 'Thông tin hành khách không hợp lệ (cần họ tên, năm sinh, loại vé)' });
    }
  }

  try {
    const ketQua = await trongGiaoDich(async (client) => {
      // 1. Khoa dong suat_khoi_hanh bang FOR UPDATE de chan 2 nguoi dat cung luc vuot so cho
      const suatRes = await client.query(
        `SELECT s.id, s.tour_id, s.ngay_di, s.so_cho, s.trang_thai,
                t.ten AS ten_tour, t.gia_nguoi_lon, t.gia_tre_em
         FROM suat_khoi_hanh s
         JOIN tour t ON t.id = s.tour_id
         WHERE s.id = $1
         FOR UPDATE OF s`,
        [suatId]
      );

      if (suatRes.rowCount === 0) {
        const err = new Error('Không tìm thấy suất khởi hành');
        err.status = 404;
        throw err;
      }

      const suat = suatRes.rows[0];
      if (suat.trang_thai !== 'NHAN_KHACH' && suat.trang_thai !== 'MO_BAN') {
        const err = new Error('Suất khởi hành này đã khóa hoặc ngừng nhận khách');
        err.status = 409;
        throw err;
      }

      // 2. Tinh so cho da dat trong cung giao dich sau khi da khoa dong
      const daDatRes = await client.query(
        `SELECT COALESCE(SUM(so_nguoi_lon + so_tre_em), 0)::int AS da_dat
         FROM dat_cho
         WHERE suat_id = $1 AND trang_thai != 'DA_HUY'`,
        [suatId]
      );

      const soChoConLai = suat.so_cho - daDatRes.rows[0].da_dat;
      const soNguoiLon = dsHanhKhach.filter((hk) => hk.loaiVe === 'NGUOI_LON').length;
      const soTreEm = dsHanhKhach.filter((hk) => hk.loaiVe === 'TRE_EM').length;
      const tongKhachDoan = soNguoiLon + soTreEm;

      if (tongKhachDoan > soChoConLai) {
        const err = new Error(`Chỉ còn ${soChoConLai} chỗ trống, không đủ cho đoàn ${tongKhachDoan} khách`);
        err.status = 409;
        throw err;
      }

      // 3. May chu tu tinh tien dich vu kem theo tu CSDL
      let tienDichVu = 0;
      for (const dv of dsDichVu) {
        if (!dv.dichVuId || !dv.soLuong || dv.soLuong <= 0) continue;
        const dvRes = await client.query(
          'SELECT id, gia FROM dich_vu_kem WHERE id = $1',
          [dv.dichVuId]
        );
        if (dvRes.rowCount === 0) {
          const err = new Error(`Dịch vụ kèm ID ${dv.dichVuId} không tồn tại`);
          err.status = 400;
          throw err;
        }
        tienDichVu += dvRes.rows[0].gia * Number(dv.soLuong);
      }

      // 4. May chu tu tinh tong tien don dat cho va sinh ma ve QR duy nhat
      const tongTien = (soNguoiLon * suat.gia_nguoi_lon) + (soTreEm * suat.gia_tre_em) + tienDichVu;
      const maVe = 'VE-CGVT-' + crypto.randomBytes(4).toString('hex').toUpperCase();

      const datChoRes = await client.query(
        `INSERT INTO dat_cho (suat_id, khach_id, so_nguoi_lon, so_tre_em, tong_tien, tien_hoan, ma_ve, trang_thai)
         VALUES ($1, $2, $3, $4, $5, 0, $6, 'DA_XAC_NHAN')
         RETURNING *`,
        [suatId, khachId, soNguoiLon, soTreEm, tongTien, maVe]
      );
      const donDat = datChoRes.rows[0];

      // 5. Luu danh sach hanh khach trong doan
      const hanhKhachDaLuu = [];
      for (const hk of dsHanhKhach) {
        const hkRes = await client.query(
          `INSERT INTO hanh_khach (dat_cho_id, ho_ten, nam_sinh, cccd, loai_ve)
           VALUES ($1, $2, $3, $4, $5)
           RETURNING *`,
          [donDat.id, hk.hoTen.trim(), Number(hk.namSinh), hk.cccd || null, hk.loaiVe]
        );
        hanhKhachDaLuu.push(hkRes.rows[0]);
      }

      // 6. Luu chi tiet dich vu kem theo
      for (const dv of dsDichVu) {
        if (!dv.dichVuId || !dv.soLuong || dv.soLuong <= 0) continue;
        await client.query(
          `INSERT INTO dat_dich_vu (dat_cho_id, dich_vu_id, so_luong)
           VALUES ($1, $2, $3)
           ON CONFLICT (dat_cho_id, dich_vu_id)
           DO UPDATE SET so_luong = EXCLUDED.so_luong`,
          [donDat.id, dv.dichVuId, Number(dv.soLuong)]
        );
      }

      return {
        ...donDat,
        ten_tour: suat.ten_tour,
        ngay_di: suat.ngay_di,
        so_cho_con_lai_sau_khi_dat: soChoConLai - tongKhachDoan,
        hanh_khach: hanhKhachDaLuu
      };
    });

    return res.status(201).json(ketQua);
  } catch (e) {
    return res.status(e.status || 500).json({ loi: e.message || 'Lỗi máy chủ khi đặt chỗ' });
  }
});

module.exports = router;
