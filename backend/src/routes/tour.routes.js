/**
 * =============================================================================
 * INT4211 - Nhóm NoName - Đề 23 - EcoTour
 * File: routes/tour.routes.js
 * Phụ trách: TV2 (Nguyễn Nhật Duy - 231A010060)
 * Mô tả: API CRUD quản lý Tour, Lịch trình chi tiết, Suất khởi hành
 * =============================================================================
 */

const express = require('express');
const router = express.Router();
const { truyVan, trongGiaoDich } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

// =============================================================================
// 1. QUẢN LÝ TOUR DU LỊCH SINH THÁI
// =============================================================================

/**
 * Lấy danh sách tất cả Tour (bao gồm tour tạm ngưng - dành cho Admin)
 * GET /quan-ly/tour
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.get('/', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const { trang_thai, tu_khoa, so_ngay } = req.query;

    let sql = `
      SELECT t.id, t.ten, t.mo_ta, t.so_ngay, t.gia_nguoi_lon, t.gia_tre_em,
             t.anh_url, t.trang_thai,
             COUNT(DISTINCT s.id)::INT AS tong_so_suat,
             COUNT(DISTINCT lt.id)::INT AS tong_moc_lich_trinh,
             COALESCE(ROUND(AVG(dg.so_sao_tour), 1), 5.0) AS danh_gia_sao
      FROM tour t
      LEFT JOIN suat_khoi_hanh s ON t.id = s.tour_id
      LEFT JOIN lich_trinh lt ON t.id = lt.tour_id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id AND dc.trang_thai != 'DA_HUY'
      LEFT JOIN danh_gia dg ON dc.id = dg.dat_cho_id
      WHERE 1=1
    `;
    const params = [];

    if (trang_thai) {
      params.push(trang_thai);
      sql += ` AND t.trang_thai = $${params.length}`;
    }

    if (tu_khoa) {
      params.push(`%${tu_khoa}%`);
      sql += ` AND (t.ten ILIKE $${params.length} OR t.mo_ta ILIKE $${params.length})`;
    }

    if (so_ngay) {
      params.push(parseInt(so_ngay, 10));
      sql += ` AND t.so_ngay = $${params.length}`;
    }

    sql += ` GROUP BY t.id ORDER BY t.id ASC`;

    const ketQua = await truyVan(sql, params);

    res.json({
      thanhCong: true,
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /quan-ly/tour:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy danh sách tour quản trị',
      chiTiet: error.message
    });
  }
});

/**
 * Lấy chi tiết một Tour theo ID (kèm lịch trình và số suất)
 * GET /quan-ly/tour/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.get('/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);

    const sqlTour = `
      SELECT t.id, t.ten, t.mo_ta, t.so_ngay, t.gia_nguoi_lon, t.gia_tre_em,
             t.anh_url, t.trang_thai
      FROM tour t WHERE t.id = $1
    `;
    const resTour = await truyVan(sqlTour, [tourId]);
    if (resTour.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

    // Lấy lịch trình
    const sqlLT = `
      SELECT lt.id, lt.ngay_thu, lt.thu_tu, lt.gio, lt.hoat_dong, lt.diem_den_id,
             dd.ten AS ten_diem_den, dd.khu_vuc
      FROM lich_trinh lt
      LEFT JOIN diem_den dd ON lt.diem_den_id = dd.id
      WHERE lt.tour_id = $1
      ORDER BY lt.ngay_thu ASC, lt.thu_tu ASC
    `;
    const resLT = await truyVan(sqlLT, [tourId]);

    // Lấy số suất
    const sqlSuat = `
      SELECT COUNT(*)::INT AS tong_suat,
             COUNT(CASE WHEN trang_thai = 'MO_BAN' THEN 1 END)::INT AS suat_mo_ban
      FROM suat_khoi_hanh WHERE tour_id = $1
    `;
    const resSuat = await truyVan(sqlSuat, [tourId]);

    res.json({
      thanhCong: true,
      duLieu: {
        ...resTour.rows[0],
        lich_trinh: resLT.rows,
        thong_ke_suat: resSuat.rows[0]
      }
    });
  } catch (error) {
    console.error('Lỗi API GET /quan-ly/tour/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy chi tiết tour',
      chiTiet: error.message
    });
  }
});

/**
 * Thêm tour mới
 * POST /quan-ly/tour
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.post('/', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const { ten, mo_ta, so_ngay, gia_nguoi_lon, gia_tre_em, anh_url } = req.body;

    // Validation
    if (!ten || !so_ngay || gia_nguoi_lon === undefined || gia_nguoi_lon === null) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: ten, so_ngay, gia_nguoi_lon'
      });
    }

    const soNgay = parseInt(so_ngay, 10);
    const giaNL = parseFloat(gia_nguoi_lon);
    const giaTE = parseFloat(gia_tre_em || 0);

    if (soNgay <= 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Số ngày tour phải lớn hơn 0'
      });
    }

    if (giaNL < 0 || giaTE < 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Giá tour không được âm'
      });
    }

    const sql = `
      INSERT INTO tour (ten, mo_ta, so_ngay, gia_nguoi_lon, gia_tre_em, anh_url, trang_thai)
      VALUES ($1, $2, $3, $4, $5, $6, 'HOAT_DONG')
      RETURNING id, ten, mo_ta, so_ngay, gia_nguoi_lon, gia_tre_em, anh_url, trang_thai
    `;
    const ketQua = await truyVan(sql, [
      ten.trim(),
      mo_ta || null,
      soNgay,
      giaNL,
      giaTE,
      anh_url || null
    ]);

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Thêm tour du lịch mới thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API POST /quan-ly/tour:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi thêm tour mới',
      chiTiet: error.message
    });
  }
});

/**
 * Cập nhật thông tin tour
 * PUT /quan-ly/tour/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.put('/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);
    const { ten, mo_ta, so_ngay, gia_nguoi_lon, gia_tre_em, anh_url, trang_thai } = req.body;

    const kiemTra = await truyVan('SELECT id FROM tour WHERE id = $1', [tourId]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

    // Validation
    if (so_ngay !== undefined && parseInt(so_ngay, 10) <= 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Số ngày tour phải lớn hơn 0'
      });
    }
    if (gia_nguoi_lon !== undefined && parseFloat(gia_nguoi_lon) < 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Giá người lớn không được âm'
      });
    }
    if (gia_tre_em !== undefined && parseFloat(gia_tre_em) < 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Giá trẻ em không được âm'
      });
    }

    // Validate trạng thái hợp lệ
    const trangThaiHopLe = ['HOAT_DONG', 'TAM_NGUNG'];
    if (trang_thai && !trangThaiHopLe.includes(trang_thai)) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: `Trạng thái tour không hợp lệ. Chấp nhận: ${trangThaiHopLe.join(', ')}`
      });
    }

    const sql = `
      UPDATE tour
      SET ten = COALESCE($1, ten),
          mo_ta = COALESCE($2, mo_ta),
          so_ngay = COALESCE($3, so_ngay),
          gia_nguoi_lon = COALESCE($4, gia_nguoi_lon),
          gia_tre_em = COALESCE($5, gia_tre_em),
          anh_url = COALESCE($6, anh_url),
          trang_thai = COALESCE($7, trang_thai)
      WHERE id = $8
      RETURNING id, ten, mo_ta, so_ngay, gia_nguoi_lon, gia_tre_em, anh_url, trang_thai
    `;
    const ketQua = await truyVan(sql, [
      ten || null,
      mo_ta || null,
      so_ngay ? parseInt(so_ngay, 10) : null,
      gia_nguoi_lon !== undefined ? parseFloat(gia_nguoi_lon) : null,
      gia_tre_em !== undefined ? parseFloat(gia_tre_em) : null,
      anh_url || null,
      trang_thai || null,
      tourId
    ]);

    res.json({
      thanhCong: true,
      thongBao: 'Cập nhật tour thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API PUT /quan-ly/tour/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi cập nhật tour',
      chiTiet: error.message
    });
  }
});

/**
 * Xóa tour (hoặc chuyển trạng thái TAM_NGUNG)
 * DELETE /quan-ly/tour/:id
 * Quyền: QUAN_TRI
 * Logic: Nếu tour có suất khởi hành đang MO_BAN → chuyển TAM_NGUNG thay vì xóa cứng
 */
router.delete('/:id', xacThuc, choPhep('QUAN_TRI'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);

    const kiemTra = await truyVan('SELECT id, ten, trang_thai FROM tour WHERE id = $1', [tourId]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

    // Kiểm tra có suất đang mở bán hoặc có đơn đặt chỗ chưa hoàn tất
    const coSuatMoBan = await truyVan(
      `SELECT COUNT(*)::INT AS so_suat FROM suat_khoi_hanh
       WHERE tour_id = $1 AND trang_thai IN ('MO_BAN', 'HET_CHO')`,
      [tourId]
    );

    if (coSuatMoBan.rows[0].so_suat > 0) {
      // Có suất đang hoạt động → chuyển TAM_NGUNG thay vì xóa
      await truyVan(
        "UPDATE tour SET trang_thai = 'TAM_NGUNG' WHERE id = $1",
        [tourId]
      );

      // Đồng thời đóng bán các suất còn mở
      await truyVan(
        "UPDATE suat_khoi_hanh SET trang_thai = 'DA_HUY' WHERE tour_id = $1 AND trang_thai = 'MO_BAN'",
        [tourId]
      );

      return res.json({
        thanhCong: true,
        thongBao: `Tour "${kiemTra.rows[0].ten}" đã được chuyển sang trạng thái TẠM NGƯNG (có ${coSuatMoBan.rows[0].so_suat} suất đang hoạt động). Các suất mở bán đã bị đóng.`,
        hanhDong: 'TAM_NGUNG'
      });
    }

    // Không có suất hoạt động → xóa cứng (CASCADE sẽ xóa lịch trình kèm theo)
    await truyVan('DELETE FROM tour WHERE id = $1', [tourId]);

    res.json({
      thanhCong: true,
      thongBao: `Đã xóa vĩnh viễn tour "${kiemTra.rows[0].ten}" và toàn bộ lịch trình liên quan`,
      hanhDong: 'XOA_CUNG'
    });
  } catch (error) {
    console.error('Lỗi API DELETE /quan-ly/tour/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi xóa tour',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// 2. QUẢN LÝ LỊCH TRÌNH CHI TIẾT CỦA TOUR
// =============================================================================

/**
 * Lấy lịch trình của tour (cho Admin)
 * GET /quan-ly/tour/:id/lich-trinh
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.get('/:id/lich-trinh', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);

    const resTour = await truyVan('SELECT id, ten, so_ngay FROM tour WHERE id = $1', [tourId]);
    if (resTour.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

    const sql = `
      SELECT lt.id, lt.tour_id, lt.ngay_thu, lt.thu_tu, lt.gio, lt.hoat_dong, lt.diem_den_id,
             dd.ten AS ten_diem_den, dd.khu_vuc
      FROM lich_trinh lt
      LEFT JOIN diem_den dd ON lt.diem_den_id = dd.id
      WHERE lt.tour_id = $1
      ORDER BY lt.ngay_thu ASC, lt.thu_tu ASC
    `;
    const ketQua = await truyVan(sql, [tourId]);

    res.json({
      thanhCong: true,
      tour: resTour.rows[0],
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /quan-ly/tour/:id/lich-trinh:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy lịch trình tour',
      chiTiet: error.message
    });
  }
});

/**
 * Thêm mốc lịch trình mới cho tour
 * POST /quan-ly/tour/:id/lich-trinh
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.post('/:id/lich-trinh', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);
    const { ngay_thu, thu_tu, gio, hoat_dong, diem_den_id } = req.body;

    // Kiểm tra tour tồn tại
    const resTour = await truyVan('SELECT id, so_ngay FROM tour WHERE id = $1', [tourId]);
    if (resTour.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

    if (!gio || !hoat_dong) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: gio, hoat_dong'
      });
    }

    const ngayThu = parseInt(ngay_thu || 1, 10);
    if (ngayThu < 1 || ngayThu > resTour.rows[0].so_ngay) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: `Ngày thứ phải từ 1 đến ${resTour.rows[0].so_ngay} (số ngày của tour)`
      });
    }

    // Tự động gán thứ tự nếu không truyền
    let thuTu = parseInt(thu_tu || 0, 10);
    if (thuTu <= 0) {
      const resMax = await truyVan(
        'SELECT COALESCE(MAX(thu_tu), 0)::INT AS max_thu_tu FROM lich_trinh WHERE tour_id = $1 AND ngay_thu = $2',
        [tourId, ngayThu]
      );
      thuTu = resMax.rows[0].max_thu_tu + 1;
    }

    // Kiểm tra điểm đến tồn tại (nếu có)
    if (diem_den_id) {
      const resDD = await truyVan('SELECT id FROM diem_den WHERE id = $1', [diem_den_id]);
      if (resDD.rows.length === 0) {
        return res.status(404).json({
          thanhCong: false,
          thongBao: 'Không tìm thấy điểm đến với diem_den_id đã cung cấp'
        });
      }
    }

    const sql = `
      INSERT INTO lich_trinh (tour_id, ngay_thu, thu_tu, gio, hoat_dong, diem_den_id)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, tour_id, ngay_thu, thu_tu, gio, hoat_dong, diem_den_id
    `;
    const ketQua = await truyVan(sql, [
      tourId,
      ngayThu,
      thuTu,
      gio.trim(),
      hoat_dong.trim(),
      diem_den_id || null
    ]);

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Thêm mốc lịch trình thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API POST /quan-ly/tour/:id/lich-trinh:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi thêm mốc lịch trình',
      chiTiet: error.message
    });
  }
});

/**
 * Cập nhật mốc lịch trình
 * PUT /quan-ly/lich-trinh/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.put('/lich-trinh/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const ltId = parseInt(req.params.id, 10);
    const { ngay_thu, thu_tu, gio, hoat_dong, diem_den_id } = req.body;

    const kiemTra = await truyVan('SELECT id, tour_id FROM lich_trinh WHERE id = $1', [ltId]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy mốc lịch trình với ID đã cung cấp'
      });
    }

    // Kiểm tra điểm đến (nếu đổi)
    if (diem_den_id) {
      const resDD = await truyVan('SELECT id FROM diem_den WHERE id = $1', [diem_den_id]);
      if (resDD.rows.length === 0) {
        return res.status(404).json({
          thanhCong: false,
          thongBao: 'Không tìm thấy điểm đến với diem_den_id đã cung cấp'
        });
      }
    }

    const sql = `
      UPDATE lich_trinh
      SET ngay_thu = COALESCE($1, ngay_thu),
          thu_tu = COALESCE($2, thu_tu),
          gio = COALESCE($3, gio),
          hoat_dong = COALESCE($4, hoat_dong),
          diem_den_id = COALESCE($5, diem_den_id)
      WHERE id = $6
      RETURNING id, tour_id, ngay_thu, thu_tu, gio, hoat_dong, diem_den_id
    `;
    const ketQua = await truyVan(sql, [
      ngay_thu ? parseInt(ngay_thu, 10) : null,
      thu_tu ? parseInt(thu_tu, 10) : null,
      gio || null,
      hoat_dong || null,
      diem_den_id || null,
      ltId
    ]);

    res.json({
      thanhCong: true,
      thongBao: 'Cập nhật mốc lịch trình thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API PUT /quan-ly/lich-trinh/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi cập nhật mốc lịch trình',
      chiTiet: error.message
    });
  }
});

/**
 * Xóa mốc lịch trình
 * DELETE /quan-ly/lich-trinh/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.delete('/lich-trinh/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const ltId = parseInt(req.params.id, 10);

    const kiemTra = await truyVan(
      'SELECT lt.id, lt.gio, lt.hoat_dong, t.ten AS ten_tour FROM lich_trinh lt JOIN tour t ON lt.tour_id = t.id WHERE lt.id = $1',
      [ltId]
    );
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy mốc lịch trình với ID đã cung cấp'
      });
    }

    await truyVan('DELETE FROM lich_trinh WHERE id = $1', [ltId]);

    res.json({
      thanhCong: true,
      thongBao: `Đã xóa mốc lịch trình "${kiemTra.rows[0].gio} - ${kiemTra.rows[0].hoat_dong}" của tour "${kiemTra.rows[0].ten_tour}"`
    });
  } catch (error) {
    console.error('Lỗi API DELETE /quan-ly/lich-trinh/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi xóa mốc lịch trình',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// 3. QUẢN LÝ SUẤT KHỞI HÀNH
// =============================================================================

/**
 * Lấy danh sách suất khởi hành của tour (cho Admin, kèm tính số chỗ còn lại)
 * GET /quan-ly/tour/:id/suat
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.get('/:id/suat', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);

    // Kiểm tra tour tồn tại
    const resTour = await truyVan('SELECT id, ten FROM tour WHERE id = $1', [tourId]);
    if (resTour.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }

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
        h.ngon_ngu AS ngon_ngu_hdv,
        s.trang_thai,
        COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0)::INT AS so_cho_da_dat,
        (s.so_cho - COALESCE(SUM(CASE WHEN dc.trang_thai != 'DA_HUY' THEN (dc.so_nguoi_lon + dc.so_tre_em) ELSE 0 END), 0))::INT AS so_cho_con_lai
      FROM suat_khoi_hanh s
      LEFT JOIN huong_dan_vien h ON s.hdv_id = h.id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id
      WHERE s.tour_id = $1
      GROUP BY s.id, h.ho_ten, h.sdt, h.ngon_ngu
      ORDER BY s.ngay_di ASC, s.gio_tap_trung ASC
    `;
    const ketQua = await truyVan(sql, [tourId]);

    res.json({
      thanhCong: true,
      tour: resTour.rows[0],
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /quan-ly/tour/:id/suat:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy danh sách suất khởi hành',
      chiTiet: error.message
    });
  }
});

/**
 * Thêm suất khởi hành mới cho tour
 * POST /quan-ly/tour/:id/suat
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.post('/:id/suat', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const tourId = parseInt(req.params.id, 10);
    const { ngay_di, gio_tap_trung, diem_tap_trung, phuong_tien, so_cho, hdv_id } = req.body;

    // Kiểm tra tour tồn tại và đang hoạt động
    const resTour = await truyVan('SELECT id, ten, trang_thai FROM tour WHERE id = $1', [tourId]);
    if (resTour.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy tour với ID đã cung cấp'
      });
    }
    if (resTour.rows[0].trang_thai !== 'HOAT_DONG') {
      return res.status(400).json({
        thanhCong: false,
        thongBao: `Tour "${resTour.rows[0].ten}" đang ở trạng thái ${resTour.rows[0].trang_thai}, không thể thêm suất mới`
      });
    }

    // Validation
    if (!ngay_di || !gio_tap_trung || !diem_tap_trung) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: ngay_di, gio_tap_trung, diem_tap_trung'
      });
    }

    const soCho = parseInt(so_cho || 30, 10);
    if (soCho <= 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Số chỗ phải lớn hơn 0'
      });
    }

    // Kiểm tra ngày đi phải >= hôm nay
    const ngayDiDate = new Date(ngay_di);
    const homNay = new Date();
    homNay.setHours(0, 0, 0, 0);
    if (ngayDiDate < homNay) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Ngày khởi hành không được nằm trong quá khứ'
      });
    }

    // Kiểm tra HDV tồn tại (nếu có)
    if (hdv_id) {
      const resHDV = await truyVan('SELECT id, ho_ten FROM huong_dan_vien WHERE id = $1', [hdv_id]);
      if (resHDV.rows.length === 0) {
        return res.status(404).json({
          thanhCong: false,
          thongBao: 'Không tìm thấy hướng dẫn viên với hdv_id đã cung cấp'
        });
      }

      // Kiểm tra HDV có bị trùng lịch không (cùng ngày khởi hành)
      const trungLich = await truyVan(
        `SELECT s.id, t.ten AS ten_tour FROM suat_khoi_hanh s
         JOIN tour t ON s.tour_id = t.id
         WHERE s.hdv_id = $1 AND s.ngay_di = $2 AND s.trang_thai != 'DA_HUY'`,
        [hdv_id, ngay_di]
      );
      if (trungLich.rows.length > 0) {
        return res.status(409).json({
          thanhCong: false,
          thongBao: `HDV "${resHDV.rows[0].ho_ten}" đã có lịch dẫn tour "${trungLich.rows[0].ten_tour}" vào ngày ${ngay_di}`
        });
      }
    }

    const sql = `
      INSERT INTO suat_khoi_hanh (tour_id, ngay_di, gio_tap_trung, diem_tap_trung, phuong_tien, so_cho, hdv_id, trang_thai)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'MO_BAN')
      RETURNING id, tour_id, ngay_di, gio_tap_trung, diem_tap_trung, phuong_tien, so_cho, hdv_id, trang_thai
    `;
    const ketQua = await truyVan(sql, [
      tourId,
      ngay_di,
      gio_tap_trung.trim(),
      diem_tap_trung.trim(),
      phuong_tien || 'Xe du lịch sinh thái tiện nghi',
      soCho,
      hdv_id || null
    ]);

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Thêm suất khởi hành mới thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API POST /quan-ly/tour/:id/suat:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi thêm suất khởi hành',
      chiTiet: error.message
    });
  }
});

/**
 * Cập nhật suất khởi hành (đổi HDV, giờ, trạng thái, ...)
 * PUT /quan-ly/suat/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.put('/suat/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const suatId = parseInt(req.params.id, 10);
    const { ngay_di, gio_tap_trung, diem_tap_trung, phuong_tien, so_cho, hdv_id, trang_thai } = req.body;

    const kiemTra = await truyVan('SELECT id, tour_id, trang_thai FROM suat_khoi_hanh WHERE id = $1', [suatId]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy suất khởi hành với ID đã cung cấp'
      });
    }

    // Validate trạng thái hợp lệ
    const trangThaiHopLe = ['MO_BAN', 'HET_CHO', 'KHOI_HANH', 'HOAN_TAT', 'DA_HUY'];
    if (trang_thai && !trangThaiHopLe.includes(trang_thai)) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: `Trạng thái suất không hợp lệ. Chấp nhận: ${trangThaiHopLe.join(', ')}`
      });
    }

    // Kiểm tra số chỗ mới không nhỏ hơn số đã đặt
    if (so_cho !== undefined) {
      const choRes = await truyVan(
        `SELECT COALESCE(SUM(CASE WHEN trang_thai != 'DA_HUY' THEN so_nguoi_lon + so_tre_em ELSE 0 END), 0)::INT AS da_dat
         FROM dat_cho WHERE suat_id = $1`,
        [suatId]
      );
      if (parseInt(so_cho, 10) < choRes.rows[0].da_dat) {
        return res.status(409).json({
          thanhCong: false,
          thongBao: `Không thể giảm số chỗ xuống ${so_cho} vì đã có ${choRes.rows[0].da_dat} chỗ được đặt`
        });
      }
    }

    // Kiểm tra HDV mới (nếu đổi)
    if (hdv_id) {
      const resHDV = await truyVan('SELECT id FROM huong_dan_vien WHERE id = $1', [hdv_id]);
      if (resHDV.rows.length === 0) {
        return res.status(404).json({
          thanhCong: false,
          thongBao: 'Không tìm thấy hướng dẫn viên với hdv_id đã cung cấp'
        });
      }
    }

    const sql = `
      UPDATE suat_khoi_hanh
      SET ngay_di = COALESCE($1, ngay_di),
          gio_tap_trung = COALESCE($2, gio_tap_trung),
          diem_tap_trung = COALESCE($3, diem_tap_trung),
          phuong_tien = COALESCE($4, phuong_tien),
          so_cho = COALESCE($5, so_cho),
          hdv_id = COALESCE($6, hdv_id),
          trang_thai = COALESCE($7, trang_thai)
      WHERE id = $8
      RETURNING id, tour_id, ngay_di, gio_tap_trung, diem_tap_trung, phuong_tien, so_cho, hdv_id, trang_thai
    `;
    const ketQua = await truyVan(sql, [
      ngay_di || null,
      gio_tap_trung || null,
      diem_tap_trung || null,
      phuong_tien || null,
      so_cho ? parseInt(so_cho, 10) : null,
      hdv_id || null,
      trang_thai || null,
      suatId
    ]);

    res.json({
      thanhCong: true,
      thongBao: 'Cập nhật suất khởi hành thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API PUT /quan-ly/suat/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi cập nhật suất khởi hành',
      chiTiet: error.message
    });
  }
});

/**
 * Hủy / Xóa suất khởi hành
 * DELETE /quan-ly/suat/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 * Logic: Nếu có đơn đặt chỗ chưa hủy → chuyển DA_HUY, nếu không → xóa cứng
 */
router.delete('/suat/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const suatId = parseInt(req.params.id, 10);

    const kiemTra = await truyVan(
      `SELECT s.id, s.ngay_di, s.trang_thai, t.ten AS ten_tour
       FROM suat_khoi_hanh s JOIN tour t ON s.tour_id = t.id
       WHERE s.id = $1`,
      [suatId]
    );
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy suất khởi hành với ID đã cung cấp'
      });
    }

    // Kiểm tra có đơn đặt chỗ chưa hủy
    const coDonDat = await truyVan(
      `SELECT COUNT(*)::INT AS so_don FROM dat_cho WHERE suat_id = $1 AND trang_thai != 'DA_HUY'`,
      [suatId]
    );

    if (coDonDat.rows[0].so_don > 0) {
      // Có đơn đặt chỗ → chuyển trạng thái DA_HUY thay vì xóa cứng
      await truyVan(
        "UPDATE suat_khoi_hanh SET trang_thai = 'DA_HUY' WHERE id = $1",
        [suatId]
      );

      return res.json({
        thanhCong: true,
        thongBao: `Suất ngày ${kiemTra.rows[0].ngay_di} tour "${kiemTra.rows[0].ten_tour}" đã chuyển sang ĐÃ HỦY (có ${coDonDat.rows[0].so_don} đơn đặt chỗ liên quan)`,
        hanhDong: 'CHUYEN_TRANG_THAI'
      });
    }

    // Không có đơn → xóa cứng
    await truyVan('DELETE FROM suat_khoi_hanh WHERE id = $1', [suatId]);

    res.json({
      thanhCong: true,
      thongBao: `Đã xóa vĩnh viễn suất ngày ${kiemTra.rows[0].ngay_di} của tour "${kiemTra.rows[0].ten_tour}"`,
      hanhDong: 'XOA_CUNG'
    });
  } catch (error) {
    console.error('Lỗi API DELETE /quan-ly/suat/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi xóa suất khởi hành',
      chiTiet: error.message
    });
  }
});

module.exports = router;

