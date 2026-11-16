/**
 * =============================================================================
 * INT4211 - Nhóm NoName - Đề 23 - EcoTour
 * File: routes/danhMuc.routes.js
 * Phụ trách: TV2 (Nguyễn Nhật Duy - 231A010060)
 * Mô tả: API CRUD quản lý danh mục Điểm đến, Hướng dẫn viên, Dịch vụ kèm theo
 * =============================================================================
 */

const express = require('express');
const router = express.Router();
const { truyVan } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

// =============================================================================
// 1. ĐIỂM ĐẾN DU LỊCH SINH THÁI
// =============================================================================

/**
 * Lấy danh sách tất cả điểm đến
 * GET /danh-muc/diem-den
 * Quyền: Công khai (không cần xác thực)
 */
router.get('/diem-den', async (req, res) => {
  try {
    const { khu_vuc, tu_khoa } = req.query;

    let sql = 'SELECT id, ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url FROM diem_den WHERE 1=1';
    const params = [];

    if (khu_vuc) {
      params.push(khu_vuc);
      sql += ` AND khu_vuc = $${params.length}`;
    }

    if (tu_khoa) {
      params.push(`%${tu_khoa}%`);
      sql += ` AND (ten ILIKE $${params.length} OR mo_ta ILIKE $${params.length})`;
    }

    sql += ' ORDER BY khu_vuc ASC, ten ASC';

    const ketQua = await truyVan(sql, params);

    res.json({
      thanhCong: true,
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /danh-muc/diem-den:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy danh sách điểm đến',
      chiTiet: error.message
    });
  }
});

/**
 * Lấy chi tiết một điểm đến theo ID
 * GET /danh-muc/diem-den/:id
 * Quyền: Công khai
 */
router.get('/diem-den/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const sql = 'SELECT id, ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url FROM diem_den WHERE id = $1';
    const ketQua = await truyVan(sql, [id]);

    if (ketQua.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy điểm đến với ID đã cung cấp'
      });
    }

    res.json({
      thanhCong: true,
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API GET /danh-muc/diem-den/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy chi tiết điểm đến',
      chiTiet: error.message
    });
  }
});

/**
 * Thêm điểm đến mới
 * POST /danh-muc/diem-den
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.post('/diem-den', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const { ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url } = req.body;

    if (!ten || !khu_vuc) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: ten, khu_vuc'
      });
    }

    const sql = `
      INSERT INTO diem_den (ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url
    `;
    const ketQua = await truyVan(sql, [
      ten.trim(),
      khu_vuc.trim(),
      mo_ta || null,
      vi_do || null,
      kinh_do || null,
      anh_url || null
    ]);

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Thêm điểm đến mới thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API POST /danh-muc/diem-den:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi thêm điểm đến',
      chiTiet: error.message
    });
  }
});

/**
 * Cập nhật thông tin điểm đến
 * PUT /danh-muc/diem-den/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.put('/diem-den/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url } = req.body;

    // Kiểm tra điểm đến tồn tại
    const kiemTra = await truyVan('SELECT id FROM diem_den WHERE id = $1', [id]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy điểm đến với ID đã cung cấp'
      });
    }

    const sql = `
      UPDATE diem_den
      SET ten = COALESCE($1, ten),
          khu_vuc = COALESCE($2, khu_vuc),
          mo_ta = COALESCE($3, mo_ta),
          vi_do = COALESCE($4, vi_do),
          kinh_do = COALESCE($5, kinh_do),
          anh_url = COALESCE($6, anh_url)
      WHERE id = $7
      RETURNING id, ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url
    `;
    const ketQua = await truyVan(sql, [
      ten || null,
      khu_vuc || null,
      mo_ta || null,
      vi_do || null,
      kinh_do || null,
      anh_url || null,
      id
    ]);

    res.json({
      thanhCong: true,
      thongBao: 'Cập nhật điểm đến thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API PUT /danh-muc/diem-den/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi cập nhật điểm đến',
      chiTiet: error.message
    });
  }
});

/**
 * Xóa điểm đến
 * DELETE /danh-muc/diem-den/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 * Lưu ý: Kiểm tra ràng buộc với lịch trình trước khi xóa
 */
router.delete('/diem-den/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);

    // Kiểm tra điểm đến tồn tại
    const kiemTra = await truyVan('SELECT id, ten FROM diem_den WHERE id = $1', [id]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy điểm đến với ID đã cung cấp'
      });
    }

    // Kiểm tra điểm đến có đang được sử dụng trong lịch trình nào không
    const dangDung = await truyVan(
      'SELECT COUNT(*)::INT AS so_lich_trinh FROM lich_trinh WHERE diem_den_id = $1',
      [id]
    );
    if (dangDung.rows[0].so_lich_trinh > 0) {
      return res.status(409).json({
        thanhCong: false,
        thongBao: `Không thể xóa điểm đến "${kiemTra.rows[0].ten}" vì đang được sử dụng trong ${dangDung.rows[0].so_lich_trinh} mốc lịch trình`
      });
    }

    await truyVan('DELETE FROM diem_den WHERE id = $1', [id]);

    res.json({
      thanhCong: true,
      thongBao: `Đã xóa điểm đến "${kiemTra.rows[0].ten}" thành công`
    });
  } catch (error) {
    console.error('Lỗi API DELETE /danh-muc/diem-den/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi xóa điểm đến',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// 2. HƯỚNG DẪN VIÊN DU LỊCH
// =============================================================================

/**
 * Lấy danh sách tất cả hướng dẫn viên
 * GET /danh-muc/hdv
 * Quyền: Công khai
 */
router.get('/hdv', async (req, res) => {
  try {
    const sql = `
      SELECT h.id, h.nguoi_dung_id, h.ho_ten, h.ngon_ngu, h.chung_chi, h.sdt,
             nd.email,
             COUNT(DISTINCT s.id)::INT AS so_suat_phu_trach,
             COALESCE(ROUND(AVG(dg.so_sao_hdv), 1), 5.0) AS danh_gia_sao
      FROM huong_dan_vien h
      LEFT JOIN nguoi_dung nd ON h.nguoi_dung_id = nd.id
      LEFT JOIN suat_khoi_hanh s ON h.id = s.hdv_id
      LEFT JOIN dat_cho dc ON s.id = dc.suat_id AND dc.trang_thai != 'DA_HUY'
      LEFT JOIN danh_gia dg ON dc.id = dg.dat_cho_id
      GROUP BY h.id, h.nguoi_dung_id, h.ho_ten, h.ngon_ngu, h.chung_chi, h.sdt, nd.email
      ORDER BY h.ho_ten ASC
    `;
    const ketQua = await truyVan(sql);

    res.json({
      thanhCong: true,
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /danh-muc/hdv:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy danh sách hướng dẫn viên',
      chiTiet: error.message
    });
  }
});

/**
 * Lấy chi tiết hướng dẫn viên theo ID
 * GET /danh-muc/hdv/:id
 * Quyền: Công khai
 */
router.get('/hdv/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const sql = `
      SELECT h.id, h.nguoi_dung_id, h.ho_ten, h.ngon_ngu, h.chung_chi, h.sdt,
             nd.email
      FROM huong_dan_vien h
      LEFT JOIN nguoi_dung nd ON h.nguoi_dung_id = nd.id
      WHERE h.id = $1
    `;
    const ketQua = await truyVan(sql, [id]);

    if (ketQua.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy hướng dẫn viên với ID đã cung cấp'
      });
    }

    // Lấy danh sách suất mà HDV này phụ trách
    const sqlSuat = `
      SELECT s.id, s.tour_id, t.ten AS ten_tour, s.ngay_di, s.gio_tap_trung,
             s.diem_tap_trung, s.trang_thai
      FROM suat_khoi_hanh s
      JOIN tour t ON s.tour_id = t.id
      WHERE s.hdv_id = $1
      ORDER BY s.ngay_di DESC
    `;
    const dsSuat = await truyVan(sqlSuat, [id]);

    res.json({
      thanhCong: true,
      duLieu: {
        ...ketQua.rows[0],
        suat_phu_trach: dsSuat.rows
      }
    });
  } catch (error) {
    console.error('Lỗi API GET /danh-muc/hdv/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy chi tiết hướng dẫn viên',
      chiTiet: error.message
    });
  }
});

/**
 * Thêm hướng dẫn viên mới
 * POST /danh-muc/hdv
 * Quyền: QUAN_TRI, DIEU_HANH
 * Lưu ý: Cần có nguoi_dung_id hợp lệ (vai trò DIEU_HANH)
 */
router.post('/hdv', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const { nguoi_dung_id, ho_ten, ngon_ngu, chung_chi, sdt } = req.body;

    if (!nguoi_dung_id || !ho_ten) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: nguoi_dung_id, ho_ten'
      });
    }

    // Kiểm tra người dùng tồn tại và có vai trò DIEU_HANH
    const kiemTraND = await truyVan(
      'SELECT id, vai_tro FROM nguoi_dung WHERE id = $1',
      [nguoi_dung_id]
    );
    if (kiemTraND.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy người dùng với ID đã cung cấp'
      });
    }

    // Kiểm tra đã có bản ghi HDV cho người dùng này chưa
    const kiemTraHDV = await truyVan(
      'SELECT id FROM huong_dan_vien WHERE nguoi_dung_id = $1',
      [nguoi_dung_id]
    );
    if (kiemTraHDV.rows.length > 0) {
      return res.status(409).json({
        thanhCong: false,
        thongBao: 'Người dùng này đã có hồ sơ hướng dẫn viên'
      });
    }

    const sql = `
      INSERT INTO huong_dan_vien (nguoi_dung_id, ho_ten, ngon_ngu, chung_chi, sdt)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, nguoi_dung_id, ho_ten, ngon_ngu, chung_chi, sdt
    `;
    const ketQua = await truyVan(sql, [
      nguoi_dung_id,
      ho_ten.trim(),
      ngon_ngu || 'Tiếng Việt',
      chung_chi || null,
      sdt || null
    ]);

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Thêm hướng dẫn viên mới thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API POST /danh-muc/hdv:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi thêm hướng dẫn viên',
      chiTiet: error.message
    });
  }
});

/**
 * Cập nhật thông tin hướng dẫn viên
 * PUT /danh-muc/hdv/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.put('/hdv/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { ho_ten, ngon_ngu, chung_chi, sdt } = req.body;

    const kiemTra = await truyVan('SELECT id FROM huong_dan_vien WHERE id = $1', [id]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy hướng dẫn viên với ID đã cung cấp'
      });
    }

    const sql = `
      UPDATE huong_dan_vien
      SET ho_ten = COALESCE($1, ho_ten),
          ngon_ngu = COALESCE($2, ngon_ngu),
          chung_chi = COALESCE($3, chung_chi),
          sdt = COALESCE($4, sdt)
      WHERE id = $5
      RETURNING id, nguoi_dung_id, ho_ten, ngon_ngu, chung_chi, sdt
    `;
    const ketQua = await truyVan(sql, [
      ho_ten || null,
      ngon_ngu || null,
      chung_chi || null,
      sdt || null,
      id
    ]);

    res.json({
      thanhCong: true,
      thongBao: 'Cập nhật hướng dẫn viên thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API PUT /danh-muc/hdv/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi cập nhật hướng dẫn viên',
      chiTiet: error.message
    });
  }
});

/**
 * Xóa hướng dẫn viên
 * DELETE /danh-muc/hdv/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 * Lưu ý: Không xóa được nếu đang phụ trách suất khởi hành MO_BAN
 */
router.delete('/hdv/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);

    const kiemTra = await truyVan('SELECT id, ho_ten FROM huong_dan_vien WHERE id = $1', [id]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy hướng dẫn viên với ID đã cung cấp'
      });
    }

    // Kiểm tra HDV có đang phụ trách suất nào đang mở bán không
    const dangPhuTrach = await truyVan(
      `SELECT COUNT(*)::INT AS so_suat FROM suat_khoi_hanh
       WHERE hdv_id = $1 AND trang_thai = 'MO_BAN'`,
      [id]
    );
    if (dangPhuTrach.rows[0].so_suat > 0) {
      return res.status(409).json({
        thanhCong: false,
        thongBao: `Không thể xóa HDV "${kiemTra.rows[0].ho_ten}" vì đang phụ trách ${dangPhuTrach.rows[0].so_suat} suất đang mở bán. Hãy chuyển HDV khác cho các suất này trước.`
      });
    }

    await truyVan('DELETE FROM huong_dan_vien WHERE id = $1', [id]);

    res.json({
      thanhCong: true,
      thongBao: `Đã xóa hướng dẫn viên "${kiemTra.rows[0].ho_ten}" thành công`
    });
  } catch (error) {
    console.error('Lỗi API DELETE /danh-muc/hdv/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi xóa hướng dẫn viên',
      chiTiet: error.message
    });
  }
});

// =============================================================================
// 3. DỊCH VỤ KÈM THEO (Cho thuê ống nhòm, áo phao, lều trại, ...)
// =============================================================================

/**
 * Lấy danh sách tất cả dịch vụ kèm theo
 * GET /danh-muc/dich-vu-kem
 * Quyền: Công khai
 */
router.get('/dich-vu-kem', async (req, res) => {
  try {
    const sql = 'SELECT id, ten, gia, don_vi FROM dich_vu_kem ORDER BY ten ASC';
    const ketQua = await truyVan(sql);

    res.json({
      thanhCong: true,
      tongSo: ketQua.rows.length,
      duLieu: ketQua.rows
    });
  } catch (error) {
    console.error('Lỗi API GET /danh-muc/dich-vu-kem:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi lấy danh sách dịch vụ kèm theo',
      chiTiet: error.message
    });
  }
});

/**
 * Thêm dịch vụ kèm theo mới
 * POST /danh-muc/dich-vu-kem
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.post('/dich-vu-kem', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const { ten, gia, don_vi } = req.body;

    if (!ten || gia === undefined || gia === null) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Vui lòng cung cấp đầy đủ: ten, gia'
      });
    }

    if (parseFloat(gia) < 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Giá dịch vụ không được âm'
      });
    }

    const sql = `
      INSERT INTO dich_vu_kem (ten, gia, don_vi)
      VALUES ($1, $2, $3)
      RETURNING id, ten, gia, don_vi
    `;
    const ketQua = await truyVan(sql, [
      ten.trim(),
      parseFloat(gia),
      don_vi || 'người'
    ]);

    res.status(201).json({
      thanhCong: true,
      thongBao: 'Thêm dịch vụ kèm theo mới thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API POST /danh-muc/dich-vu-kem:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi thêm dịch vụ kèm theo',
      chiTiet: error.message
    });
  }
});

/**
 * Cập nhật dịch vụ kèm theo
 * PUT /danh-muc/dich-vu-kem/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.put('/dich-vu-kem/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { ten, gia, don_vi } = req.body;

    const kiemTra = await truyVan('SELECT id FROM dich_vu_kem WHERE id = $1', [id]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy dịch vụ kèm theo với ID đã cung cấp'
      });
    }

    if (gia !== undefined && parseFloat(gia) < 0) {
      return res.status(400).json({
        thanhCong: false,
        thongBao: 'Giá dịch vụ không được âm'
      });
    }

    const sql = `
      UPDATE dich_vu_kem
      SET ten = COALESCE($1, ten),
          gia = COALESCE($2, gia),
          don_vi = COALESCE($3, don_vi)
      WHERE id = $4
      RETURNING id, ten, gia, don_vi
    `;
    const ketQua = await truyVan(sql, [
      ten || null,
      gia !== undefined ? parseFloat(gia) : null,
      don_vi || null,
      id
    ]);

    res.json({
      thanhCong: true,
      thongBao: 'Cập nhật dịch vụ kèm theo thành công',
      duLieu: ketQua.rows[0]
    });
  } catch (error) {
    console.error('Lỗi API PUT /danh-muc/dich-vu-kem/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi cập nhật dịch vụ kèm theo',
      chiTiet: error.message
    });
  }
});

/**
 * Xóa dịch vụ kèm theo
 * DELETE /danh-muc/dich-vu-kem/:id
 * Quyền: QUAN_TRI, DIEU_HANH
 */
router.delete('/dich-vu-kem/:id', xacThuc, choPhep('QUAN_TRI', 'DIEU_HANH'), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);

    const kiemTra = await truyVan('SELECT id, ten FROM dich_vu_kem WHERE id = $1', [id]);
    if (kiemTra.rows.length === 0) {
      return res.status(404).json({
        thanhCong: false,
        thongBao: 'Không tìm thấy dịch vụ kèm theo với ID đã cung cấp'
      });
    }

    // Kiểm tra dịch vụ có đang được đặt kèm theo đơn nào không
    const dangDung = await truyVan(
      'SELECT COUNT(*)::INT AS so_don FROM dat_dich_vu WHERE dich_vu_id = $1',
      [id]
    );
    if (dangDung.rows[0].so_don > 0) {
      return res.status(409).json({
        thanhCong: false,
        thongBao: `Không thể xóa dịch vụ "${kiemTra.rows[0].ten}" vì đang được sử dụng trong ${dangDung.rows[0].so_don} đơn đặt chỗ`
      });
    }

    await truyVan('DELETE FROM dich_vu_kem WHERE id = $1', [id]);

    res.json({
      thanhCong: true,
      thongBao: `Đã xóa dịch vụ "${kiemTra.rows[0].ten}" thành công`
    });
  } catch (error) {
    console.error('Lỗi API DELETE /danh-muc/dich-vu-kem/:id:', error);
    res.status(500).json({
      thanhCong: false,
      thongBao: 'Lỗi máy chủ khi xóa dịch vụ kèm theo',
      chiTiet: error.message
    });
  }
});

module.exports = router;

