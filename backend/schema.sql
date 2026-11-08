-- =============================================================================
-- INT4211: Hệ thống đặt tour du lịch sinh thái Cần Giờ – Vũng Tàu (Đề 23)
-- Nhóm NoName - Kịch bản khởi tạo CSDL PostgreSQL (13 Bảng chuẩn)
-- =============================================================================

-- 1. Xóa các bảng cũ theo thứ tự phụ thuộc khóa ngoại nếu tồn tại
DROP TABLE IF EXISTS danh_gia CASCADE;
DROP TABLE IF EXISTS diem_danh_tour CASCADE;
DROP TABLE IF EXISTS dat_dich_vu CASCADE;
DROP TABLE IF EXISTS dich_vu_kem CASCADE;
DROP TABLE IF EXISTS hanh_khach CASCADE;
DROP TABLE IF EXISTS dat_cho CASCADE;
DROP TABLE IF EXISTS chinh_sach_huy CASCADE;
DROP TABLE IF EXISTS suat_khoi_hanh CASCADE;
DROP TABLE IF EXISTS huong_dan_vien CASCADE;
DROP TABLE IF EXISTS lich_trinh CASCADE;
DROP TABLE IF EXISTS tour CASCADE;
DROP TABLE IF EXISTS diem_den CASCADE;
DROP TABLE IF EXISTS nguoi_dung CASCADE;

-- =============================================================================
-- 2. Khởi tạo 13 bảng thực thể nghiệp vụ
-- =============================================================================

-- BẢNG 1: Người dùng (Quản trị, Điều hành/HDV, Khách du lịch)
CREATE TABLE nguoi_dung (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    mat_khau_hash VARCHAR(255) NOT NULL,
    ho_ten VARCHAR(255) NOT NULL,
    sdt VARCHAR(20),
    vai_tro VARCHAR(20) NOT NULL CHECK (vai_tro IN ('QUAN_TRI', 'DIEU_HANH', 'KHACH')),
    tao_luc TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- BẢNG 2: Điểm đến du lịch sinh thái (Cần Giờ, Vũng Tàu)
CREATE TABLE diem_den (
    id SERIAL PRIMARY KEY,
    ten VARCHAR(255) NOT NULL,
    khu_vuc VARCHAR(100) NOT NULL, -- 'Cần Giờ', 'Vũng Tàu', ...
    mo_ta TEXT,
    vi_do NUMERIC(10, 7),
    kinh_do NUMERIC(10, 7),
    anh_url TEXT
);

-- BẢNG 3: Danh mục Tour du lịch sinh thái
CREATE TABLE tour (
    id SERIAL PRIMARY KEY,
    ten VARCHAR(255) NOT NULL,
    mo_ta TEXT,
    so_ngay INT NOT NULL DEFAULT 1 CHECK (so_ngay > 0),
    gia_nguoi_lon NUMERIC(12, 2) NOT NULL CHECK (gia_nguoi_lon >= 0),
    gia_tre_em NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (gia_tre_em >= 0),
    anh_url TEXT,
    trang_thai VARCHAR(50) NOT NULL DEFAULT 'HOAT_DONG'
);

-- BẢNG 4: Lịch trình chi tiết theo giờ của Tour
CREATE TABLE lich_trinh (
    id SERIAL PRIMARY KEY,
    tour_id INT NOT NULL REFERENCES tour(id) ON DELETE CASCADE,
    ngay_thu INT NOT NULL DEFAULT 1 CHECK (ngay_thu > 0),
    thu_tu INT NOT NULL DEFAULT 1 CHECK (thu_tu > 0),
    gio VARCHAR(20) NOT NULL, -- Ví dụ: '07:30', '09:00 - 11:30'
    hoat_dong TEXT NOT NULL,
    diem_den_id INT REFERENCES diem_den(id) ON DELETE SET NULL
);

-- BẢNG 5: Hướng dẫn viên du lịch
CREATE TABLE huong_dan_vien (
    id SERIAL PRIMARY KEY,
    nguoi_dung_id INT NOT NULL UNIQUE REFERENCES nguoi_dung(id) ON DELETE CASCADE,
    ho_ten VARCHAR(255) NOT NULL,
    ngon_ngu VARCHAR(100) NOT NULL DEFAULT 'Tiếng Việt',
    chung_chi VARCHAR(255),
    sdt VARCHAR(20)
);

-- BẢNG 6: Suất khởi hành cụ thể của Tour
CREATE TABLE suat_khoi_hanh (
    id SERIAL PRIMARY KEY,
    tour_id INT NOT NULL REFERENCES tour(id) ON DELETE CASCADE,
    ngay_di DATE NOT NULL,
    gio_tap_trung VARCHAR(20) NOT NULL,
    diem_tap_trung VARCHAR(255) NOT NULL,
    phuong_tien VARCHAR(100) NOT NULL DEFAULT 'Xe du lịch sinh thái tiện nghi',
    so_cho INT NOT NULL DEFAULT 30 CHECK (so_cho > 0),
    hdv_id INT REFERENCES huong_dan_vien(id) ON DELETE SET NULL,
    trang_thai VARCHAR(50) NOT NULL DEFAULT 'MO_BAN' -- 'MO_BAN', 'HET_CHO', 'KHOI_HANH', 'HOAN_TAT', 'DA_HUY'
);

-- BẢNG 7: Đơn đặt chỗ của khách hàng
CREATE TABLE dat_cho (
    id SERIAL PRIMARY KEY,
    suat_id INT NOT NULL REFERENCES suat_khoi_hanh(id) ON DELETE RESTRICT,
    khach_id INT NOT NULL REFERENCES nguoi_dung(id) ON DELETE RESTRICT,
    so_nguoi_lon INT NOT NULL DEFAULT 1 CHECK (so_nguoi_lon >= 0),
    so_tre_em INT NOT NULL DEFAULT 0 CHECK (so_tre_em >= 0),
    tong_tien NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (tong_tien >= 0),
    tien_hoan NUMERIC(12, 2) DEFAULT 0 CHECK (tien_hoan >= 0),
    ma_ve VARCHAR(50) NOT NULL UNIQUE,
    trang_thai VARCHAR(50) NOT NULL DEFAULT 'DA_DAT', -- 'DA_DAT', 'DA_CHECKIN', 'DA_HUY'
    dat_luc TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_tong_khach CHECK (so_nguoi_lon + so_tre_em > 0)
);

-- BẢNG 8: Danh sách hành khách trong mỗi đơn đặt
CREATE TABLE hanh_khach (
    id SERIAL PRIMARY KEY,
    dat_cho_id INT NOT NULL REFERENCES dat_cho(id) ON DELETE CASCADE,
    ho_ten VARCHAR(255) NOT NULL,
    nam_sinh INT,
    cccd VARCHAR(20),
    loai_ve VARCHAR(20) NOT NULL CHECK (loai_ve IN ('NGUOI_LON', 'TRE_EM'))
);

-- BẢNG 9: Dịch vụ du lịch sinh thái kèm theo
CREATE TABLE dich_vu_kem (
    id SERIAL PRIMARY KEY,
    ten VARCHAR(255) NOT NULL,
    gia NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (gia >= 0),
    don_vi VARCHAR(50) NOT NULL DEFAULT 'người'
);

-- BẢNG 10: Chi tiết dịch vụ kèm theo từng đơn đặt
CREATE TABLE dat_dich_vu (
    id SERIAL PRIMARY KEY,
    dat_cho_id INT NOT NULL REFERENCES dat_cho(id) ON DELETE CASCADE,
    dich_vu_id INT NOT NULL REFERENCES dich_vu_kem(id) ON DELETE RESTRICT,
    so_luong INT NOT NULL DEFAULT 1 CHECK (so_luong > 0),
    CONSTRAINT uq_dat_cho_dich_vu UNIQUE (dat_cho_id, dich_vu_id)
);

-- BẢNG 11: Lịch sử quét mã QR điểm danh hành khách
CREATE TABLE diem_danh_tour (
    id SERIAL PRIMARY KEY,
    dat_cho_id INT NOT NULL REFERENCES dat_cho(id) ON DELETE CASCADE,
    hanh_khach_id INT NOT NULL REFERENCES hanh_khach(id) ON DELETE CASCADE,
    thoi_diem TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nguoi_quet_id INT REFERENCES nguoi_dung(id) ON DELETE SET NULL
);

-- BẢNG 12: Chính sách hoàn tiền khi hủy tour
CREATE TABLE chinh_sach_huy (
    id SERIAL PRIMARY KEY,
    so_gio_truoc INT NOT NULL UNIQUE CHECK (so_gio_truoc >= 0),
    phan_tram_hoan INT NOT NULL CHECK (phan_tram_hoan >= 0 AND phan_tram_hoan <= 100)
);

-- BẢNG 13: Đánh giá chất lượng tour & hướng dẫn viên
CREATE TABLE danh_gia (
    id SERIAL PRIMARY KEY,
    dat_cho_id INT NOT NULL UNIQUE REFERENCES dat_cho(id) ON DELETE CASCADE,
    so_sao_tour INT NOT NULL CHECK (so_sao_tour >= 1 AND so_sao_tour <= 5),
    so_sao_hdv INT NOT NULL CHECK (so_sao_hdv >= 1 AND so_sao_hdv <= 5),
    noi_dung TEXT,
    anh_url TEXT,
    tao_luc TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Tạo chỉ mục (Index) hỗ trợ truy vấn tối ưu
-- =============================================================================
CREATE INDEX idx_tour_trang_thai ON tour(trang_thai);
CREATE INDEX idx_suat_tour_ngay ON suat_khoi_hanh(tour_id, ngay_di);
CREATE INDEX idx_dat_cho_suat ON dat_cho(suat_id);
CREATE INDEX idx_dat_cho_khach ON dat_cho(khach_id);
CREATE INDEX idx_dat_cho_ma_ve ON dat_cho(ma_ve);
CREATE INDEX idx_hanh_khach_dat_cho ON hanh_khach(dat_cho_id);
CREATE INDEX idx_lich_trinh_tour ON lich_trinh(tour_id, ngay_thu, thu_tu);
