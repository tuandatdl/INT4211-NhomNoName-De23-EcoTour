const jwt = require('jsonwebtoken');

/**
 * Middleware xác thực Bearer JWT Token
 */
function xacThuc(req, res, next) {
  const authHeader = req.headers['authorization'] || req.headers['Authorization'];
  if (!authHeader) {
    return res.status(401).json({
      thanhCong: false,
      thongBao: 'Yêu cầu token xác thực Bearer trong tiêu đề Authorization'
    });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({
      thanhCong: false,
      thongBao: 'Định dạng token không hợp lệ (cần "Bearer <token>")'
    });
  }

  const token = parts[1];
  const secretKey = process.env.JWT_SECRET || 'chuoi_bi_mat_ngau_nhien_it_nhat_32_ky_tu_nhom_noname';

  try {
    const payload = jwt.verify(token, secretKey);
    req.nguoiDung = payload;
    next();
  } catch (error) {
    return res.status(401).json({
      thanhCong: false,
      thongBao: 'Token không hợp lệ hoặc đã hết hạn',
      chiTiet: error.message
    });
  }
}

/**
 * Middleware phân quyền theo vai trò người dùng ('QUAN_TRI', 'DIEU_HANH', 'KHACH')
 * @param  {...string} vaiTroChoPhep - Các vai trò được phép truy cập
 */
function choPhep(...vaiTroChoPhep) {
  return (req, res, next) => {
    if (!req.nguoiDung) {
      return res.status(401).json({
        thanhCong: false,
        thongBao: 'Chưa xác thực người dùng'
      });
    }

    if (!vaiTroChoPhep.includes(req.nguoiDung.vai_tro)) {
      return res.status(403).json({
        thanhCong: false,
        thongBao: `Bạn không có quyền truy cập chức năng này (yêu cầu vai trò: ${vaiTroChoPhep.join(', ')})`
      });
    }

    next();
  };
}

module.exports = {
  xacThuc,
  choPhep
};
