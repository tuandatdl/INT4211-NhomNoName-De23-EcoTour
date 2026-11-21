const jwt = require('jsonwebtoken');

function xacThuc(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ loi: 'Thiếu token xác thực' });
  }

  try {
    req.nguoiDung = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (e) {
    return res.status(401).json({ loi: 'Token không hợp lệ hoặc đã hết hạn' });
  }
}

function choPhep(...vaiTroChoPhep) {
  return (req, res, next) => {
    const vaiTro = req.nguoiDung && (req.nguoiDung.vaiTro || req.nguoiDung.vai_tro);
    if (!req.nguoiDung || !vaiTroChoPhep.includes(vaiTro)) {
      return res.status(403).json({ loi: 'Không có quyền thực hiện chức năng này' });
    }
    next();
  };
}

module.exports = { xacThuc, choPhep };
