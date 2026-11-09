const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }, // Bat buoc cho Supabase khi chay tren Render
  max: 5 // Gioi han ket noi phu hop goi Free cua Supabase
});

// Ham truy van chuan: Luon truyen tham so dang $1, $2 - TUYET DOI KHONG noi chuoi SQL
const truyVan = (sql, params = []) => pool.query(sql, params);

// Ham xu ly giao dich (Transaction) dung cho nghiep vu dat cho va huy tour
async function trongGiaoDich(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const ketQua = await callback(client);
    await client.query('COMMIT');
    return ketQua;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { pool, truyVan, trongGiaoDich };
