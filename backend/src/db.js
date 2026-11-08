const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'development' && !process.env.DATABASE_URL?.includes('supabase.co')
    ? false
    : { rejectUnauthorized: false },
  max: 5
});

pool.on('error', (err) => {
  console.error('Lỗi kết nối cơ sở dữ liệu ngoài ý muốn:', err);
});

/**
 * Thực thi câu lệnh SQL với tham số $1, $2...
 * @param {string} sql - Chuỗi SQL
 * @param {Array} params - Mảng tham số
 * @returns {Promise<import('pg').QueryResult>}
 */
async function truyVan(sql, params = []) {
  const batDau = Date.now();
  const ketQua = await pool.query(sql, params);
  const thoiGian = Date.now() - batDau;
  if (process.env.DEBUG === 'true') {
    console.log('Thực thi SQL:', { sql, params, thoiGian: `${thoiGian}ms`, soDong: ketQua.rowCount });
  }
  return ketQua;
}

/**
 * Thực thi một hàm nghiệp vụ trong khối Transaction (ACID)
 * Tự động BEGIN, COMMIT hoặc ROLLBACK nếu xảy ra lỗi.
 * @param {Function} callback - Hàm nhận vào client (đã kết nối) và trả về kết quả
 * @returns {Promise<any>}
 */
async function trongGiaoDich(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const ketQua = await callback(client);
    await client.query('COMMIT');
    return ketQua;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  pool,
  truyVan,
  trongGiaoDich
};
