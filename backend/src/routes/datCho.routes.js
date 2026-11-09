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

// GET /dat-cho - Lay danh sach don dat cho (QUAN_TRI, DIEU_HANH)
router.get('/', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  const { suatId, trangThai } = req.query;
  let sql = `
    SELECT dc.id, dc.suat_id, dc.khach_id, dc.so_nguoi_lon, dc.so_tre_em, dc.tong_tien,
           dc.tien_hoan, dc.ma_ve, dc.trang_thai, dc.dat_luc,
           nd.ho_ten AS ho_ten_khach, nd.sdt AS sdt_khach, nd.email AS email_khach,
           t.ten AS ten_tour, s.ngay_di, s.gio_tap_trung, s.diem_tap_trung
    FROM dat_cho dc
    JOIN nguoi_dung nd ON nd.id = dc.khach_id
    JOIN suat_khoi_hanh s ON s.id = dc.suat_id
    JOIN tour t ON t.id = s.tour_id
    WHERE 1=1
  `;
  const params = [];
  if (suatId) {
    params.push(Number(suatId));
    sql += ` AND dc.suat_id = $${params.length}`;
  }
  if (trangThai) {
    params.push(trangThai);
    sql += ` AND dc.trang_thai = $${params.length}`;
  }
  sql += ` ORDER BY dc.id DESC`;

  try {
    const r = await truyVan(sql, params);
    return res.status(200).json(r.rows);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy danh sách đặt chỗ' });
  }
});

// GET /dat-cho/cua-toi - Lay danh sach don dat cho cua chinh khach hang dang dang nhap
router.get('/cua-toi', xacThuc, async (req, res) => {
  try {
    const sql = `
      SELECT dc.id, dc.suat_id, dc.so_nguoi_lon, dc.so_tre_em, dc.tong_tien,
             dc.tien_hoan, dc.ma_ve, dc.trang_thai, dc.dat_luc,
             t.id AS tour_id, t.ten AS ten_tour, t.anh_url AS anh_tour,
             s.ngay_di, s.gio_tap_trung, s.diem_tap_trung, s.phuong_tien
      FROM dat_cho dc
      JOIN suat_khoi_hanh s ON s.id = dc.suat_id
      JOIN tour t ON t.id = s.tour_id
      WHERE dc.khach_id = $1
      ORDER BY dc.id DESC
    `;
    const r = await truyVan(sql, [req.nguoiDung.id]);
    return res.status(200).json(r.rows);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy danh sách đặt chỗ của bạn' });
  }
});

// GET /dat-cho/:id/ve - Lay thong tin ve dien tu QR kem hanh khach, dich vu va diem danh
router.get('/:id/ve', xacThuc, async (req, res) => {
  const { id } = req.params;

  try {
    const dcRes = await truyVan(
      `SELECT dc.id, dc.suat_id, dc.khach_id, dc.so_nguoi_lon, dc.so_tre_em,
              dc.tong_tien, dc.tien_hoan, dc.ma_ve, dc.trang_thai, dc.dat_luc,
              nd.ho_ten AS ho_ten_khach, nd.sdt AS sdt_khach,
              t.ten AS ten_tour, t.so_ngay,
              s.ngay_di, s.gio_tap_trung, s.diem_tap_trung, s.phuong_tien,
              hdv.ho_ten AS ho_ten_hdv, hdv.sdt AS sdt_hdv
       FROM dat_cho dc
       JOIN nguoi_dung nd ON nd.id = dc.khach_id
       JOIN suat_khoi_hanh s ON s.id = dc.suat_id
       JOIN tour t ON t.id = s.tour_id
       LEFT JOIN huong_dan_vien hdv ON hdv.id = s.hdv_id
       WHERE dc.id = $1`,
      [id]
    );

    if (dcRes.rowCount === 0) {
      return res.status(404).json({ loi: 'Không tìm thấy vé hoặc đơn đặt chỗ' });
    }

    const donDat = dcRes.rows[0];

    // Kiem tra quyen: chu don hoac QUAN_TRI / DIEU_HANH
    const laChuDon = donDat.khach_id === req.nguoiDung.id;
    const laNhanVien = ['QUAN_TRI', 'DIEU_HANH'].includes(req.nguoiDung.vaiTro);
    if (!laChuDon && !laNhanVien) {
      return res.status(403).json({ loi: 'Bạn không có quyền xem vé này' });
    }

    // Lay danh sach hanh khach va trang thai diem danh
    const hkRes = await truyVan(
      `SELECT hk.id, hk.ho_ten, hk.nam_sinh, hk.cccd, hk.loai_ve,
              dd.id AS diem_danh_id, dd.thoi_diem AS thoi_diem_diem_danh
       FROM hanh_khach hk
       LEFT JOIN diem_danh_tour dd ON dd.hanh_khach_id = hk.id AND dd.dat_cho_id = hk.dat_cho_id
       WHERE hk.dat_cho_id = $1
       ORDER BY hk.id ASC`,
      [id]
    );

    // Lay danh sach dich vu kem theo
    const dvRes = await truyVan(
      `SELECT dv.id, dv.ten, dv.gia, dv.don_vi, ddv.so_luong
       FROM dat_dich_vu ddv
       JOIN dich_vu_kem dv ON dv.id = ddv.dich_vu_id
       WHERE ddv.dat_cho_id = $1`,
      [id]
    );

    return res.status(200).json({
      ...donDat,
      hanh_khach: hkRes.rows,
      dich_vu_kem: dvRes.rows,
      da_diem_danh_du: hkRes.rows.length > 0 && hkRes.rows.every((hk) => hk.diem_danh_id !== null)
    });
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy thông tin vé điện tử' });
  }
});

// PATCH /dat-cho/:id/huy - Huy dat tour va tu dong tinh tien hoan theo chinh sach
router.patch('/:id/huy', xacThuc, async (req, res) => {
  const { id } = req.params;

  try {
    const ketQua = await trongGiaoDich(async (client) => {
      // 1. Khoa dong don dat cho va lay thong tin khoi hanh
      const donRes = await client.query(
        `SELECT dc.*, s.ngay_di, s.gio_tap_trung
         FROM dat_cho dc
         JOIN suat_khoi_hanh s ON s.id = dc.suat_id
         WHERE dc.id = $1
         FOR UPDATE OF dc`,
        [id]
      );

      if (donRes.rowCount === 0) {
        const err = new Error('Không tìm thấy đơn đặt chỗ');
        err.status = 404;
        throw err;
      }

      const don = donRes.rows[0];

      // 2. Kiem tra quyen: chu don hoac QUAN_TRI
      const laChuDon = don.khach_id === req.nguoiDung.id;
      const laQuanTri = req.nguoiDung.vaiTro === 'QUAN_TRI';
      if (!laChuDon && !laQuanTri) {
        const err = new Error('Bạn không có quyền hủy đơn đặt chỗ này');
        err.status = 403;
        throw err;
      }

      // Kiem tra trang thai don
      if (don.trang_thai === 'DA_HUY') {
        const err = new Error('Đơn đặt chỗ này đã bị hủy trước đó');
        err.status = 409;
        throw err;
      }
      if (['HOAN_TAT', 'DA_HOAN_TAT', 'DA_CHECKIN'].includes(don.trang_thai)) {
        const err = new Error(`Không thể hủy đơn đặt chỗ ở trạng thái ${don.trang_thai}`);
        err.status = 409;
        throw err;
      }

      // 3. Tinh so gio con lai tu hien tai den luc khoi hanh
      const gioBatDau = (don.gio_tap_trung || '07:00').split('-')[0].trim();
      const gioClean = gioBatDau.length === 5 ? `${gioBatDau}:00` : gioBatDau;

      const timeDiffRes = await client.query(
        `SELECT EXTRACT(EPOCH FROM (($1::date + $2::time) - CURRENT_TIMESTAMP)) / 3600 AS so_gio_con_lai`,
        [don.ngay_di, gioClean]
      );
      const soGioConLai = parseFloat(timeDiffRes.rows[0].so_gio_con_lai);

      // 4. Tra cuu chinh sach hoan tien tu CSDL
      let phanTramHoan = 0;
      if (soGioConLai > 0) {
        const csRes = await client.query(
          `SELECT phan_tram_hoan
           FROM chinh_sach_huy
           WHERE so_gio_truoc <= $1
           ORDER BY so_gio_truoc DESC
           LIMIT 1`,
          [Math.floor(soGioConLai)]
        );
        if (csRes.rowCount > 0) {
          phanTramHoan = csRes.rows[0].phan_tram_hoan;
        }
      }

      // 5. Tinh so tien hoan va cap nhat trang thai
      const tienHoan = Math.round((Number(don.tong_tien) * phanTramHoan) / 100);

      const updateRes = await client.query(
        `UPDATE dat_cho
         SET trang_thai = 'DA_HUY', tien_hoan = $1
         WHERE id = $2
         RETURNING *`,
        [tienHoan, id]
      );

      return {
        ...updateRes.rows[0],
        phan_tram_hoan: phanTramHoan,
        so_gio_truoc_khoi_hanh: Math.round(soGioConLai * 10) / 10,
        thong_bao: `Hủy tour thành công. Số giờ trước khởi hành: ${Math.round(soGioConLai * 10) / 10}h. Mức hoàn tiền: ${phanTramHoan}%.`
      };
    });

    return res.status(200).json(ketQua);
  } catch (e) {
    return res.status(e.status || 500).json({ loi: e.message || 'Lỗi máy chủ khi hủy đặt chỗ' });
  }
});

// POST /dat-cho/diem-danh - Quet ma QR diem danh khach len xe/tau
async function xuLyDiemDanhTour(req, res) {
  const { maVe, datChoId, hanhKhachId } = req.body;
  const nguoiQuetId = req.nguoiDung.id;

  if (!maVe && !datChoId) {
    return res.status(400).json({ loi: 'Vui lòng cung cấp mã vé QR (maVe) hoặc mã đơn đặt chỗ (datChoId)' });
  }

  try {
    let sql = `
      SELECT dc.id, dc.suat_id, dc.khach_id, dc.ma_ve, dc.trang_thai,
             nd.ho_ten AS ho_ten_khach, nd.sdt AS sdt_khach,
             t.ten AS ten_tour, s.ngay_di, s.gio_tap_trung, s.diem_tap_trung
      FROM dat_cho dc
      JOIN nguoi_dung nd ON nd.id = dc.khach_id
      JOIN suat_khoi_hanh s ON s.id = dc.suat_id
      JOIN tour t ON t.id = s.tour_id
      WHERE 1=1
    `;
    const params = [];
    if (maVe) {
      params.push(maVe.trim());
      sql += ` AND dc.ma_ve = $${params.length}`;
    } else {
      params.push(Number(datChoId));
      sql += ` AND dc.id = $${params.length}`;
    }

    const dcRes = await truyVan(sql, params);
    if (dcRes.rowCount === 0) {
      return res.status(404).json({ loi: 'Vé hoặc đơn đặt chỗ không tồn tại trong hệ thống' });
    }

    const donDat = dcRes.rows[0];
    if (donDat.trang_thai === 'DA_HUY') {
      return res.status(409).json({ loi: 'Vé này đã bị hủy, không thể lên xe/tau' });
    }

    // Lay danh sach hanh khach cua don
    const hkRes = await truyVan(
      `SELECT hk.id, hk.ho_ten, hk.loai_ve, hk.cccd,
              dd.id AS diem_danh_id, dd.thoi_diem AS thoi_diem_diem_danh
       FROM hanh_khach hk
       LEFT JOIN diem_danh_tour dd ON dd.hanh_khach_id = hk.id AND dd.dat_cho_id = hk.dat_cho_id
       WHERE hk.dat_cho_id = $1
       ORDER BY hk.id ASC`,
      [donDat.id]
    );

    if (hkRes.rowCount === 0) {
      return res.status(400).json({ loi: 'Đơn đặt chỗ không có dữ liệu hành khách' });
    }

    const danhSachHanhKhach = hkRes.rows;
    let hanhKhachCanDiemDanh = [];

    if (hanhKhachId) {
      const timHk = danhSachHanhKhach.find((h) => h.id === Number(hanhKhachId));
      if (!timHk) {
        return res.status(404).json({ loi: `Không tìm thấy hành khách ID ${hanhKhachId} trong đoàn này` });
      }
      if (timHk.diem_danh_id) {
        return res.status(200).json({
          thongBao: 'Hành khách này đã được điểm danh trước đó',
          donDat,
          hanhKhach: danhSachHanhKhach
        });
      }
      hanhKhachCanDiemDanh.push(timHk);
    } else {
      // Quet theo maVe doan: diem danh cho tat ca hanh khach chua duoc diem danh
      hanhKhachCanDiemDanh = danhSachHanhKhach.filter((h) => !h.diem_danh_id);
    }

    // Ghi nhan diem danh vao bang diem_danh_tour
    for (const hk of hanhKhachCanDiemDanh) {
      await truyVan(
        `INSERT INTO diem_danh_tour (dat_cho_id, hanh_khach_id, thoi_diem, nguoi_quet_id)
         VALUES ($1, $2, NOW(), $3)`,
        [donDat.id, hk.id, nguoiQuetId]
      );
    }

    // Cap nhat trang thai don dat cho thanh DA_CHECKIN neu chua cap nhat
    if (donDat.trang_thai !== 'DA_CHECKIN') {
      await truyVan("UPDATE dat_cho SET trang_thai = 'DA_CHECKIN' WHERE id = $1", [donDat.id]);
    }

    // Lay lai danh sach hanh khach cap nhat
    const hkCapNhatRes = await truyVan(
      `SELECT hk.id, hk.ho_ten, hk.loai_ve, hk.cccd,
              dd.id AS diem_danh_id, dd.thoi_diem AS thoi_diem_diem_danh
       FROM hanh_khach hk
       LEFT JOIN diem_danh_tour dd ON dd.hanh_khach_id = hk.id AND dd.dat_cho_id = hk.dat_cho_id
       WHERE hk.dat_cho_id = $1
       ORDER BY hk.id ASC`,
      [donDat.id]
    );

    return res.status(201).json({
      thongBao: `Điểm danh thành công cho ${hanhKhachCanDiemDanh.length} hành khách`,
      soKhachVuaDiemDanh: hanhKhachCanDiemDanh.length,
      tongKhachTrongDoan: danhSachHanhKhach.length,
      donDat: {
        ...donDat,
        trang_thai: 'DA_CHECKIN'
      },
      danhSachHanhKhach: hkCapNhatRes.rows
    });
  } catch (e) {
    return res.status(500).json({ loi: e.message || 'Lỗi máy chủ khi quét QR điểm danh' });
  }
}

router.post('/diem-danh', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), xuLyDiemDanhTour);

module.exports = router;
module.exports.xuLyDiemDanhTour = xuLyDiemDanhTour;
