const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { truyVan } = require('../db');
const { xacThuc } = require('../middleware/auth');

const router = express.Router();

// POST /auth/dang-ky
router.post('/dang-ky', async (req, res) => {
  const { email, matKhau, hoTen, sdt } = req.body;
  if (!email || !matKhau || !hoTen) {
    return res.status(400).json({ loi: 'Thiếu email, mật khẩu hoặc họ tên' });
  }
  if (String(matKhau).length < 6) {
    return res.status(400).json({ loi: 'Mật khẩu phải có ít nhất 6 ký tự' });
  }

  try {
    const hash = await bcrypt.hash(matKhau, 10);
    const r = await truyVan(
      `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, vai_tro)
       VALUES ($1, $2, $3, $4, 'KHACH')
       RETURNING id, email, ho_ten, sdt, vai_tro, tao_luc`,
      [email.trim().toLowerCase(), hash, hoTen.trim(), sdt || null]
    );
    return res.status(201).json(r.rows[0]);
  } catch (e) {
    if (e.code === '23505') {
      return res.status(409).json({ loi: 'Email đã tồn tại trong hệ thống' });
    }
    return res.status(500).json({ loi: 'Lỗi máy chủ khi đăng ký tài khoản' });
  }
});

// POST /auth/dang-nhap
router.post('/dang-nhap', async (req, res) => {
  const { email, matKhau } = req.body;
  if (!email || !matKhau) {
    return res.status(400).json({ loi: 'Vui lòng nhập đầy đủ email và mật khẩu' });
  }

  try {
    const r = await truyVan(
      'SELECT id, email, mat_khau_hash, ho_ten, sdt, vai_tro FROM nguoi_dung WHERE email = $1',
      [email.trim().toLowerCase()]
    );
    const u = r.rows[0];

    if (!u || !(await bcrypt.compare(matKhau, u.mat_khau_hash))) {
      return res.status(401).json({ loi: 'Email hoặc mật khẩu không đúng' });
    }

    const token = jwt.sign(
      { id: u.id, vaiTro: u.vai_tro },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      token,
      nguoiDung: {
        id: u.id,
        email: u.email,
        hoTen: u.ho_ten,
        sdt: u.sdt,
        vaiTro: u.vai_tro
      }
    });
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi đăng nhập' });
  }
});

// GET /auth/toi - Lay thong tin tai khoan hien tai (Khong bao gio tra mat_khau_hash)
router.get('/toi', xacThuc, async (req, res) => {
  try {
    const r = await truyVan(
      'SELECT id, email, ho_ten, sdt, vai_tro, tao_luc FROM nguoi_dung WHERE id = $1',
      [req.nguoiDung.id]
    );
    if (r.rowCount === 0) {
      return res.status(404).json({ loi: 'Không tìm thấy người dùng' });
    }
    return res.status(200).json(r.rows[0]);
  } catch (e) {
    return res.status(500).json({ loi: 'Lỗi máy chủ khi lấy thông tin cá nhân' });
  }
});

module.exports = router;
