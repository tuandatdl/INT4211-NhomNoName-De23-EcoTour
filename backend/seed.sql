-- =============================================================================
-- INT4211: Hệ thống đặt tour du lịch sinh thái Cần Giờ – Vũng Tàu (Đề 23)
-- Nhóm NoName - Dữ liệu mẫu khởi tạo chuẩn định lượng Đề 23 (backend/seed.sql)
-- Mật khẩu chung cho tất cả tài khoản: 123456
-- Bcrypt Hash: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- =============================================================================

-- Dọn dẹp dữ liệu cũ trước khi nạp lại
TRUNCATE TABLE danh_gia, diem_danh_tour, dat_dich_vu, dich_vu_kem, hanh_khach, dat_cho, chinh_sach_huy, suat_khoi_hanh, huong_dan_vien, lich_trinh, tour, diem_den, nguoi_dung RESTART IDENTITY CASCADE;

-- =============================================================================
-- 1. NẠP NGƯỜI DÙNG (Bao gồm 4 tài khoản chính của Nhóm NoName + HDV + Khách)
-- =============================================================================
INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, vai_tro, tao_luc) VALUES
-- 4 Tài khoản chính theo phân công Đề 23
('admin@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Đỗ Lê Tuấn Đạt', '0901234567', 'QUAN_TRI', NOW() - INTERVAL '30 days'),
('dieuhanh@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Nguyễn Nhật Duy', '0902345678', 'DIEU_HANH', NOW() - INTERVAL '30 days'),
('khach1@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Phan Thị Anh Thư', '0903456789', 'KHACH', NOW() - INTERVAL '30 days'),
('khach2@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Bùi Quang Duy', '0904567890', 'KHACH', NOW() - INTERVAL '30 days'),

-- 7 Hướng dẫn viên khác (đủ 8 HDV theo yêu cầu Đề 23)
('hdv2@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Trần Hoàng Nam', '0911223344', 'DIEU_HANH', NOW() - INTERVAL '25 days'),
('hdv3@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Lê Thị Mai Hương', '0912334455', 'DIEU_HANH', NOW() - INTERVAL '25 days'),
('hdv4@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Phạm Quốc Bảo', '0913445566', 'DIEU_HANH', NOW() - INTERVAL '25 days'),
('hdv5@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Vũ Minh Tuấn', '0914556677', 'DIEU_HANH', NOW() - INTERVAL '25 days'),
('hdv6@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Hoàng Thị Yến', '0915667788', 'DIEU_HANH', NOW() - INTERVAL '25 days'),
('hdv7@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Đặng Văn Khoa', '0916778899', 'DIEU_HANH', NOW() - INTERVAL '25 days'),
('hdv8@ecotour.vn', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Nguyễn Quỳnh Nga', '0917889900', 'DIEU_HANH', NOW() - INTERVAL '25 days'),

-- Danh sách khách hàng mẫu bổ sung để phát sinh 200 lượt đặt chỗ
('khach3@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Lê Văn An', '0931000003', 'KHACH', NOW() - INTERVAL '20 days'),
('khach4@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Trần Thị Bình', '0931000004', 'KHACH', NOW() - INTERVAL '20 days'),
('khach5@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Nguyễn Văn Cường', '0931000005', 'KHACH', NOW() - INTERVAL '20 days'),
('khach6@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Phạm Thị Dung', '0931000006', 'KHACH', NOW() - INTERVAL '20 days'),
('khach7@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Võ Hoàng Em', '0931000007', 'KHACH', NOW() - INTERVAL '20 days'),
('khach8@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Đặng Thúy Giang', '0931000008', 'KHACH', NOW() - INTERVAL '20 days'),
('khach9@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Dương Văn Hải', '0931000009', 'KHACH', NOW() - INTERVAL '20 days'),
('khach10@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Đinh Thị Kiều', '0931000010', 'KHACH', NOW() - INTERVAL '20 days');

-- =============================================================================
-- 2. NẠP 8 HƯỚNG DẪN VIÊN DU LỊCH
-- =============================================================================
INSERT INTO huong_dan_vien (nguoi_dung_id, ho_ten, ngon_ngu, chung_chi, sdt) VALUES
(2, 'Nguyễn Nhật Duy', 'Tiếng Việt, Tiếng Anh', 'Thẻ HDV Quốc tế số INT-79-001', '0902345678'),
(5, 'Trần Hoàng Nam', 'Tiếng Việt, Tiếng Anh', 'Thẻ HDV Nội địa số DOM-79-002', '0911223344'),
(6, 'Lê Thị Mai Hương', 'Tiếng Việt, Tiếng Pháp', 'Thẻ HDV Quốc tế số INT-79-003', '0912334455'),
(7, 'Phạm Quốc Bảo', 'Tiếng Việt, Tiếng Anh', 'Thẻ HDV Nội địa số DOM-79-004', '0913445566'),
(8, 'Vũ Minh Tuấn', 'Tiếng Việt, Tiếng Nhật', 'Thẻ HDV Quốc tế số INT-79-005', '0914556677'),
(9, 'Hoàng Thị Yến', 'Tiếng Việt, Tiếng Anh', 'Thẻ HDV Nội địa số DOM-79-006', '0915667788'),
(10, 'Đặng Văn Khoa', 'Tiếng Việt, Tiếng Trung', 'Thẻ HDV Quốc tế số INT-79-007', '0916778899'),
(11, 'Nguyễn Quỳnh Nga', 'Tiếng Việt, Tiếng Anh', 'Thẻ HDV Nội địa số DOM-79-008', '0917889900');

-- =============================================================================
-- 3. NẠP 10 ĐIỂM ĐẾN TẠI CẦN GIỜ – VŨNG TÀU
-- =============================================================================
INSERT INTO diem_den (id, ten, khu_vuc, mo_ta, vi_do, kinh_do, anh_url) VALUES
(1, 'Khu dự trữ sinh quyển Rừng ngập mặn Cần Giờ', 'Cần Giờ', 'Lá phổi xanh của TP.HCM với hệ động thực vật ngập mặn phong phú và kênh rạch nguyên sơ.', 10.4284000, 106.8856000, 'https://images.unsplash.com/photo-1511497584788-87676104235f'),
(2, 'Khu du lịch Đảo Khỉ Cần Giờ (Lâm viên Cần Giờ)', 'Cần Giờ', 'Nơi sinh sống tự nhiên của hơn 2.000 cá thể khỉ hoang dã thân thiện và đàn cá sấu hoa cà.', 10.4350000, 106.8790000, 'https://images.unsplash.com/photo-1540573133985-87b6da6d54a9'),
(3, 'Khu di tích lịch sử Chiến khu Rừng Sác', 'Cần Giờ', 'Di tích lịch sử oai hùng của Trung đoàn 10 Đặc công Rừng Sác với mô hình tái hiện sống động.', 10.4215000, 106.8920000, 'https://images.unsplash.com/photo-1506744038136-46273834b3fb'),
(4, 'Bãi biển 30/4 & Rừng phi lao Cần Giờ', 'Cần Giờ', 'Bãi biển phù sa tự nhiên dài phẳng lặng, thích hợp dạo bộ, cắm trại và ngắm hoàng hôn.', 10.4050000, 106.9200000, 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e'),
(5, 'Lăng Ông Thủy Tướng Cần Thạnh', 'Cần Giờ', 'Địa điểm văn hóa tín ngưỡng miền biển, nơi lưu giữ bộ xương cá voi khổng lồ dài 12m.', 10.4080000, 106.9580000, 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957'),
(6, 'Mũi Nghinh Phong & Cổng Trời Vũng Tàu', 'Vũng Tàu', 'Mũi đất vươn mình đón gió bốn mùa, cảnh quan biển trời bao la ngoạn mục.', 10.3245000, 107.0845000, 'https://images.unsplash.com/photo-1506929562872-bb421503ef21'),
(7, 'Tượng Chúa Kitô Vua & Đỉnh Núi Nhỏ', 'Vũng Tàu', 'Biểu tượng của thành phố biển Vũng Tàu trên đỉnh Tao Phùng cao 170m so với mực nước biển.', 10.3262000, 107.0850000, 'https://images.unsplash.com/photo-1519046904884-53103b34b206'),
(8, 'Ngọn Hải Đăng Vũng Tàu', 'Vũng Tàu', 'Ngọn hải đăng cổ nhất Việt Nam được người Pháp xây dựng, tầm nhìn toàn cảnh vịnh biển.', 10.3340000, 107.0750000, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23'),
(9, 'Bạch Dinh (Villa Blanche)', 'Vũng Tàu', 'Biệt thự kiến trúc Pháp cổ kính bên sườn Núi Lớn, bao quanh bởi rừng cây hoa sứ cổ thụ.', 10.3540000, 107.0690000, 'https://images.unsplash.com/photo-1513694203232-719a280e022f'),
(10, 'Khu du lịch sinh thái Hồ Mây Núi Lớn', 'Vũng Tàu', 'Khu nghỉ dưỡng sinh thái trên đỉnh Núi Lớn với hệ thống cáp treo biển và rừng nguyên sinh mát mẻ.', 10.3630000, 107.0730000, 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05');

SELECT setval('diem_den_id_seq', 10);

-- =============================================================================
-- 4. NẠP 15 TOUR DU LỊCH SINH THÁI
-- =============================================================================
INSERT INTO tour (id, ten, mo_ta, so_ngay, gia_nguoi_lon, gia_tre_em, anh_url, trang_thai) VALUES
(1, 'Khám phá Rừng Ngập Mặn Cần Giờ – Đảo Khỉ', 'Hành trình sinh thái 1 ngày hòa mình vào thiên nhiên hoang dã, tìm hiểu hệ sinh thái ngập mặn Cần Giờ.', 1, 550000, 350000, 'https://images.unsplash.com/photo-1511497584788-87676104235f', 'HOAT_DONG'),
(2, 'Về Nguồn Chiến Khu Rừng Sác – Chèo SUP Rừng Đước', 'Khám phá di tích lịch sử chiến sĩ đặc công Rừng Sác và trải nghiệm chèo thuyền SUP thể thao dưới tán rừng xanh mát.', 1, 650000, 420000, 'https://images.unsplash.com/photo-1506744038136-46273834b3fb', 'HOAT_DONG'),
(3, 'Trải nghiệm Sinh Thái Biển Cần Giờ & Thưởng Thức Hải Sản', 'Tận hưởng gió biển tại Bãi biển 30/4, tham quan làng nghề làm muối và thưởng thức hải sản Cần Giờ tươi ngon.', 1, 590000, 390000, 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e', 'HOAT_DONG'),
(4, 'Văn Hóa Làng Chài Cần Thạnh & Lăng Ông Thủy Tướng', 'Tìm hiểu phong tục tập quán ngư dân vùng duyên hải Cần Giờ, chiêm bái di cốt Cá Voi linh thiêng tại Lăng Ông.', 1, 490000, 320000, 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957', 'HOAT_DONG'),
(5, 'Du Lịch Sinh Thái Cần Giờ 2N1Đ - Cắm Trại Đêm Bãi Biển', 'Hành trình 2 ngày 1 đêm trọn vẹn khám phá Rừng Sác, đốt lửa trại bãi biển ngắm bình minh trên biển Cần Giờ.', 2, 1350000, 890000, 'https://images.unsplash.com/photo-1510312305653-8ed496efae75', 'HOAT_DONG'),
(6, 'Tour Xanh Cần Giờ – Trồng Rừng Đước Bảo Vệ Môi Trường', 'Tour du lịch tình nguyện trồng cây xanh phục hồi rừng ngập mặn kết hợp giáo dục sinh thái bảo tồn đa dạng sinh học.', 1, 450000, 280000, 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09', 'HOAT_DONG'),
(7, 'Hành Trình Sinh Thái Biển Vũng Tàu – Hải Đăng & Bạch Dinh', 'Tham quan ngọn hải đăng cổ, khám phá kiến trúc Bạch Dinh giữa rừng hoa sứ thơm ngát và thưởng ngoạn biển Bãi Trước.', 1, 680000, 450000, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23', 'HOAT_DONG'),
(8, 'Chinh Phục Đỉnh Núi Lớn – Khu Sinh Thái Cáp Treo Hồ Mây', 'Trải nghiệm cáp treo ngắm toàn cảnh thành phố biển Vũng Tàu, hòa mình vào không gian sinh thái Hồ Mây xanh mát.', 1, 850000, 550000, 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05', 'HOAT_DONG'),
(9, 'Khám Phá Mũi Nghinh Phong – Bình Minh Trên Biển Vũng Tàu', 'Đón luồng gió mát lành tại Mũi Nghinh Phong, check-in Cổng Trời huyền ảo và dạo bộ trên những triền đá biển kỳ thú.', 1, 580000, 380000, 'https://images.unsplash.com/photo-1506929562872-bb421503ef21', 'HOAT_DONG'),
(10, 'Vũng Tàu Xanh 2N1Đ – Núi Nhỏ, Tượng Chúa Kitô & Lặn Ngắm Biển', 'Kỳ nghỉ sinh thái 2 ngày 1 đêm leo núi rèn luyện sức khỏe, chiêm bái Tượng Chúa dang tay và tận hưởng biển Bãi Sau.', 2, 1450000, 950000, 'https://images.unsplash.com/photo-1519046904884-53103b34b206', 'HOAT_DONG'),
(11, 'Trekking Sinh Thái Núi Dinh – Khám Phá Rừng & Suối Tiên', 'Hành trình leo núi hòa mình vào thiên nhiên hoang sơ, tắm suối mát lạnh và rèn luyện thể lực cuối tuần.', 1, 520000, 350000, 'https://images.unsplash.com/photo-1448375240586-882707db888b', 'HOAT_DONG'),
(12, 'Liên Tuyến Cần Giờ – Vũng Tàu Đi Phà Biển Sinh Thái 2N1Đ', 'Chuyến du ngoạn độc đáo kết hợp hai vùng sinh thái ngập mặn Cần Giờ và thành phố biển Vũng Tàu qua chuyến phà vượt biển.', 2, 1690000, 1150000, 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e', 'HOAT_DONG'),
(13, 'Tour Xe Đạp Sinh Thái Vòng Quanh Bờ Biển Vũng Tàu', 'Khám phá cung đường ven biển Trần Phú uốn lượn dưới tán bàng cổ thụ, hít thở không khí biển trong lành buổi sớm.', 1, 480000, 310000, 'https://images.unsplash.com/photo-1485965120184-e220f721d03e', 'HOAT_DONG'),
(14, 'Hoàng Hôn Cần Giờ – Đi Thuyền Gỗ Xem Đom Đóm Đêm Rừng Đước', 'Trải nghiệm ngắm hoàng hôn buông trên sông Lòng Tàu và ngắm đàn đom đóm thắp sáng rừng ngập mặn khi đêm về.', 1, 720000, 480000, 'https://images.unsplash.com/photo-1518837695005-2083093ee35b', 'HOAT_DONG'),
(15, 'Vũng Tàu Nghỉ Dưỡng Sinh Thái & Trải Nghiệm Nông Trại Xanh', 'Chuyến đi nghỉ dưỡng phục hồi năng lượng, trải nghiệm thu hoạch trái cây sạch và tắm suối khoáng tự nhiên.', 2, 1550000, 990000, 'https://images.unsplash.com/photo-1500382017468-9049fed747ef', 'HOAT_DONG');

SELECT setval('tour_id_seq', 15);

-- =============================================================================
-- 5. NẠP ĐÚNG 45 DÒNG LỊCH TRÌNH CHO 15 TOUR (Mỗi Tour 3 mốc hoạt động)
-- =============================================================================
INSERT INTO lich_trinh (tour_id, ngay_thu, thu_tu, gio, hoat_dong, diem_den_id) VALUES
-- Tour 1
(1, 1, 1, '07:30', 'Xe đón khách tại điểm hẹn trung tâm, khởi hành đi phà Bình Khánh qua Cần Giờ.', NULL),
(1, 1, 2, '09:00 - 11:30', 'Tham quan Khu bảo tồn Đảo Khỉ, ngắm đàn khỉ hoang dã và hệ sinh thái rừng ngập mặn nguyên sinh.', 2),
(1, 1, 3, '14:00 - 16:30', 'Đi xuồng máy xuyên lõi rừng đước tại Khu dự trữ sinh quyển Cần Giờ, ngắm chim rừng và tìm hiểu công tác bảo tồn.', 1),

-- Tour 2
(2, 1, 1, '07:00', 'Tập trung tại bến xe, khởi hành đi chiến khu lịch sử Cần Giờ.', NULL),
(2, 1, 2, '09:00 - 11:30', 'Dâng hương tưởng niệm và tham quan sa bàn tái hiện đời sống đặc công tại Căn cứ Chiến khu Rừng Sác.', 3),
(2, 1, 3, '13:30 - 16:00', 'Hướng dẫn kỹ thuật chèo thuyền SUP xuyên các con rạch nhỏ trong rừng ngập mặn Cần Giờ.', 1),

-- Tour 3
(3, 1, 1, '08:00', 'Khởi hành hướng về bãi biển Duyên hải Cần Giờ.', NULL),
(3, 1, 2, '10:00 - 12:00', 'Dạo chơi bãi cát biển 30/4, ngắm rừng phi lao chắn gió và tận hưởng không khí biển mát lành.', 4),
(3, 1, 3, '13:30 - 15:30', 'Thăm chợ hải sản Hàng Dương, tự tay chọn hải sản tươi sống và thưởng thức đặc sản địa phương.', 4),

-- Tour 4
(4, 1, 1, '07:30', 'Khởi hành đi thị trấn biển Cần Thạnh phía nam Cần Giờ.', NULL),
(4, 1, 2, '09:30 - 11:30', 'Thăm quan di tích Lăng Ông Thủy Tướng Cần Thạnh, chiêm ngưỡng bộ xương cá Ông khổng lồ.', 5),
(4, 1, 3, '14:00 - 16:00', 'Ghé thăm làng nghề muối và khu rừng ngập mặn Cần Thạnh.', 1),

-- Tour 5
(5, 1, 1, '08:00', 'Khởi hành đi Cần Giờ, đi cano vào khu dã ngoại ven rừng.', 1),
(5, 1, 2, '15:00 - 18:00', 'Dựng lều cắm trại trên bãi biển 30/4, ngắm hoàng hôn trên biển và chuẩn bị tiệc BBQ sinh thái.', 4),
(5, 2, 3, '06:00 - 10:00', 'Đón bình minh ven biển Cần Giờ, dạo bộ ngắm rừng phi lao và kết thúc tour.', 4),

-- Tour 6
(6, 1, 1, '07:30', 'Xuất phát từ TP.HCM, nghe phổ biến kiến thức về vai trò phòng hộ của rừng ngập mặn.', NULL),
(6, 1, 2, '09:30 - 11:30', 'Tham gia hoạt động trực tiếp ươm và trồng 50 cây đước non tại bãi bồi ven rừng.', 1),
(6, 1, 3, '13:30 - 15:30', 'Khám phá đường mòn sinh thái trong Rừng ngập mặn Cần Giờ và giao lưu bảo tồn đa dạng sinh học.', 1),

-- Tour 7
(7, 1, 1, '06:30', 'Xe du lịch đón đoàn xuất phát đi Thành phố biển Vũng Tàu theo đường cao tốc.', NULL),
(7, 1, 2, '09:30 - 11:30', 'Leo núi dạo bộ lên đỉnh Hải Đăng Vũng Tàu, ngắm toàn cảnh thành phố biển và vịnh Gành Rái.', 8),
(7, 1, 3, '14:00 - 16:30', 'Tham quan Bạch Dinh (Villa Blanche), dạo vườn hoa sứ cổ kính bên triền Núi Lớn.', 9),

-- Tour 8
(8, 1, 1, '07:00', 'Đón đoàn di chuyển tới Vũng Tàu, tập trung tại ga cáp treo Núi Lớn.', NULL),
(8, 1, 2, '09:30 - 12:00', 'Đi cáp treo vượt biển lên đỉnh Núi Lớn tham quan Khu du lịch sinh thái Hồ Mây mát mẻ.', 10),
(8, 1, 3, '13:30 - 16:00', 'Khám phá vườn thú sinh thái Hồ Mây, ngắm rừng thông nhân tạo và hồ nước trên mây.', 10),

-- Tour 9
(9, 1, 1, '06:00', 'Khởi hành sớm đến Mũi Nghinh Phong đón gió mát lành.', NULL),
(9, 1, 2, '08:30 - 11:00', 'Check-in Cổng Trời Mũi Nghinh Phong, dạo bước trên doi đất vươn ra biển Đông hùng vĩ.', 6),
(9, 1, 3, '13:30 - 15:30', 'Tắm biển Bãi Vọng Nguyệt và tham quan các thềm đá biển tự nhiên.', 6),

-- Tour 10
(10, 1, 1, '07:00', 'Khởi hành đến Vũng Tàu, nhận phòng khách sạn sinh thái ven biển.', NULL),
(10, 1, 2, '14:30 - 17:30', 'Chinh phục gần 1.000 bậc đá lên Tượng Chúa Kitô Vua trên đỉnh Núi Nhỏ, ngắm biển bao la.', 7),
(10, 2, 3, '08:30 - 11:00', 'Dạo quanh Mũi Nghinh Phong, ngắm cảnh bình minh và thưởng thức cà phê ven biển.', 6),

-- Tour 11
(11, 1, 1, '06:30', 'Xe đón đoàn đi khu bảo tồn thiên nhiên ven Bà Rịa - Vũng Tàu.', NULL),
(11, 1, 2, '08:30 - 12:00', 'Trekking 6km đường mòn rừng nguyên sinh, ngắm thảm thực vật phong phú và nghe chim hót.', 10),
(11, 1, 3, '13:30 - 15:30', 'Nghỉ ngơi và tắm dòng suối tự nhiên trong vắt giữa rừng già trước khi lên xe về.', 10),

-- Tour 12
(12, 1, 1, '07:00', 'Đoàn đến bến Cần Giờ, đi ca nô khám phá lõi Rừng Sác Cần Giờ.', 1),
(12, 1, 2, '14:00 - 15:30', 'Lên phà biển Cần Giờ – Vũng Tàu vượt vịnh Gành Rái 30 phút đầy thú vị.', 4),
(12, 2, 3, '09:00 - 11:30', 'Tham quan Bạch Dinh và ngắm toàn cảnh biển từ Ngọn Hải Đăng Vũng Tàu.', 8),

-- Tour 13
(13, 1, 1, '06:00', 'Đoàn đến Vũng Tàu nhận xe đạp thể thao tại Bãi Trước.', NULL),
(13, 1, 2, '07:30 - 10:30', 'Đạp xe cung đường ven biển Hạ Long - Trần Phú dưới bóng cây cổ thụ ngắm Mũi Nghinh Phong.', 6),
(13, 1, 3, '14:00 - 16:00', 'Ghé thăm khu vườn Bạch Dinh và thưởng thức nước dừa tươi Vũng Tàu.', 9),

-- Tour 14
(14, 1, 1, '13:30', 'Xe đón khách tại TP.HCM đi xuôi về hướng biển Cần Giờ.', NULL),
(14, 1, 2, '15:30 - 17:30', 'Đi thuyền gỗ tham quan các luồng lạch trong Khu dự trữ sinh quyển Rừng ngập mặn Cần Giờ.', 1),
(14, 1, 3, '18:00 - 20:00', 'Thưởng thức bữa tối nhẹ trên thuyền gỗ và ngắm đom đóm rực sáng ven sông đêm.', 1),

-- Tour 15
(15, 1, 1, '07:00', 'Khởi hành từ trung tâm đi về vùng sinh thái nông trại Vũng Tàu.', NULL),
(15, 1, 2, '09:30 - 12:00', 'Tham quan vườn bưởi, thu hoạch nông sản hữu cơ và thưởng thức nước ép trái cây sạch.', 10),
(15, 2, 3, '08:30 - 11:30', 'Đi cáp treo tham quan rừng hoa và ngắm hồ nước trên núi tại Hồ Mây.', 10);

-- =============================================================================
-- 6. NẠP DỊCH VỤ DU LỊCH KÈM THEO
-- =============================================================================
INSERT INTO dich_vu_kem (id, ten, gia, don_vi) VALUES
(1, 'Chèo thuyền SUP thể thao xuyên rừng ngập mặn', 150000, 'người'),
(2, 'Tiệc nướng BBQ hải sản Cần Giờ tươi sống', 250000, 'suất'),
(3, 'Thuê lều cắm trại sinh thái cao cấp kèm đệm', 200000, 'lều'),
(4, 'Bảo hiểm du lịch mạo hiểm & sinh thái toàn diện', 50000, 'người'),
(5, 'Xe đạp thể thao khám phá bờ biển & làng chài', 80000, 'xe');

SELECT setval('dich_vu_kem_id_seq', 5);

-- =============================================================================
-- 7. NẠP CHÍNH SÁCH HỦY ĐẶT CHỖ
-- =============================================================================
INSERT INTO chinh_sach_huy (id, so_gio_truoc, phan_tram_hoan) VALUES
(1, 72, 100), -- Hủy trước 72 giờ: Hoàn 100%
(2, 48, 70),  -- Hủy trước 48 giờ: Hoàn 70%
(3, 24, 50),  -- Hủy trước 24 giờ: Hoàn 50%
(4, 0, 0);    -- Hủy dưới 24 giờ: Hoàn 0%

SELECT setval('chinh_sach_huy_id_seq', 4);

-- =============================================================================
-- 8. NẠP ĐỦ 60 SUẤT KHỞI HÀNH (Mỗi tour 4 suất trải đều các tuần)
-- =============================================================================
INSERT INTO suat_khoi_hanh (id, tour_id, ngay_di, gio_tap_trung, diem_tap_trung, phuong_tien, so_cho, hdv_id, trang_thai)
SELECT
    s_id,
    ((s_id - 1) % 15) + 1 AS tour_id,
    (CURRENT_DATE + ((s_id - 1) * 2)::INT) AS ngay_di,
    CASE (s_id % 3)
        WHEN 0 THEN '06:00'
        WHEN 1 THEN '07:00'
        ELSE '07:30'
    END AS gio_tap_trung,
    CASE ((s_id - 1) % 15) + 1
        WHEN 1 THEN 'Bến xe Miền Tây - Cổng số 2'
        WHEN 7 THEN 'Nhà Văn hóa Thanh Niên - 04 Phạm Ngọc Thạch'
        WHEN 12 THEN 'Bến phà Cần Giờ - Tắc Xuất'
        ELSE 'Bến xe Miền Đông mới - Quận 9'
    END AS diem_tap_trung,
    CASE (s_id % 2)
        WHEN 0 THEN 'Xe du lịch Hyundai Universe 45 chỗ đời mới'
        ELSE 'Xe Ford Transit du lịch sinh thái 16 chỗ'
    END AS phuong_tien,
    30 AS so_cho,
    ((s_id - 1) % 8) + 1 AS hdv_id,
    'MO_BAN' AS trang_thai
FROM generate_series(1, 60) AS s_id;

SELECT setval('suat_khoi_hanh_id_seq', 60);

-- =============================================================================
-- 9. NẠP ĐỦ 200 ĐƠN ĐẶT CHỖ KÈM HÀNH KHÁCH, DỊCH VỤ KÈM, ĐÁNH GIÁ, ĐIỂM DANH
-- =============================================================================
DO $$
DECLARE
    i INT;
    v_suat_id INT;
    v_khach_id INT;
    v_tour_id INT;
    v_gia_nl NUMERIC(12,2);
    v_gia_te NUMERIC(12,2);
    v_so_nl INT;
    v_so_te INT;
    v_tong_tien NUMERIC(12,2);
    v_dat_cho_id INT;
    v_ma_ve VARCHAR(50);
    v_trang_thai VARCHAR(50);
    v_hdv_uid INT;
    v_hk_id INT;
BEGIN
    FOR i IN 1..200 LOOP
        -- Phân bổ suất khởi hành từ 1 đến 60
        v_suat_id := ((i - 1) % 60) + 1;
        -- Phân bổ khách hàng (khach1, khach2, khach3..khach10)
        v_khach_id := ((i - 1) % 10) + 3; -- ID người dùng 3 đến 12
        IF i = 1 THEN v_khach_id := 3; END IF; -- khach1@gmail.com
        IF i = 2 THEN v_khach_id := 4; END IF; -- khach2@gmail.com

        -- Lấy giá tour tương ứng
        SELECT t.id, t.gia_nguoi_lon, t.gia_tre_em
        INTO v_tour_id, v_gia_nl, v_gia_te
        FROM suat_khoi_hanh s
        JOIN tour t ON s.tour_id = t.id
        WHERE s.id = v_suat_id;

        -- Số lượng khách đi kèm
        v_so_nl := (i % 2) + 1; -- 1 hoặc 2 người lớn
        v_so_te := CASE WHEN i % 3 = 0 THEN 1 ELSE 0 END; -- thỉnh thoảng có 1 trẻ em

        v_tong_tien := (v_so_nl * v_gia_nl) + (v_so_te * v_gia_te);

        -- Mã vé định dạng chuẩn
        v_ma_ve := 'ECO-202611-' || LPAD(i::TEXT, 4, '0');

        -- Trạng thái đơn đặt
        IF i % 15 = 0 THEN
            v_trang_thai := 'DA_HUY';
        ELSIF i % 3 = 0 THEN
            v_trang_thai := 'DA_CHECKIN';
        ELSE
            v_trang_thai := 'DA_DAT';
        END IF;

        -- Chèn đơn đặt chỗ
        INSERT INTO dat_cho (id, suat_id, khach_id, so_nguoi_lon, so_tre_em, tong_tien, tien_hoan, ma_ve, trang_thai, dat_luc)
        VALUES (
            i,
            v_suat_id,
            v_khach_id,
            v_so_nl,
            v_so_te,
            v_tong_tien,
            CASE WHEN v_trang_thai = 'DA_HUY' THEN v_tong_tien * 0.7 ELSE 0 END,
            v_ma_ve,
            v_trang_thai,
            NOW() - ((200 - i) || ' hours')::INTERVAL
        ) RETURNING id INTO v_dat_cho_id;

        -- Chèn danh sách hành khách cho đơn đặt
        INSERT INTO hanh_khach (dat_cho_id, ho_ten, nam_sinh, cccd, loai_ve)
        VALUES (v_dat_cho_id, 'Hành Khách ' || i || 'A', 1990 + (i % 15), '079' || LPAD((100000000 + i)::TEXT, 9, '0'), 'NGUOI_LON')
        RETURNING id INTO v_hk_id;

        IF v_so_nl > 1 THEN
            INSERT INTO hanh_khach (dat_cho_id, ho_ten, nam_sinh, cccd, loai_ve)
            VALUES (v_dat_cho_id, 'Hành Khách ' || i || 'B', 1992 + (i % 12), '079' || LPAD((200000000 + i)::TEXT, 9, '0'), 'NGUOI_LON');
        END IF;

        IF v_so_te > 0 THEN
            INSERT INTO hanh_khach (dat_cho_id, ho_ten, nam_sinh, cccd, loai_ve)
            VALUES (v_dat_cho_id, 'Trẻ Em ' || i || 'C', 2018 + (i % 5), NULL, 'TRE_EM');
        END IF;

        -- Chèn dịch vụ đi kèm nếu có (khoảng 50% đơn đặt kèm dịch vụ sinh thái)
        IF i % 2 = 0 THEN
            INSERT INTO dat_dich_vu (dat_cho_id, dich_vu_id, so_luong)
            VALUES (v_dat_cho_id, ((i % 5) + 1), v_so_nl)
            ON CONFLICT DO NOTHING;
        END IF;

        -- Nếu đơn đặt đã check-in, lưu thông tin điểm danh và đánh giá
        IF v_trang_thai = 'DA_CHECKIN' THEN
            -- Điểm danh bởi điều hành viên
            INSERT INTO diem_danh_tour (dat_cho_id, hanh_khach_id, thoi_diem, nguoi_quet_id)
            VALUES (v_dat_cho_id, v_hk_id, NOW() - ((200 - i) || ' hours')::INTERVAL, 2);

            -- Thêm đánh giá chất lượng (4 sao hoặc 5 sao)
            INSERT INTO danh_gia (dat_cho_id, so_sao_tour, so_sao_hdv, noi_dung, anh_url, tao_luc)
            VALUES (
                v_dat_cho_id,
                4 + (i % 2),
                5,
                'Tour sinh thái rất tuyệt vời, HDV nhiệt tình và các hoạt động bảo vệ thiên nhiên rất ý nghĩa!',
                'https://images.unsplash.com/photo-1511497584788-87676104235f',
                NOW() - ((100 - (i / 2)) || ' hours')::INTERVAL
            )
            ON CONFLICT (dat_cho_id) DO NOTHING;
        END IF;

    END LOOP;
END $$;

SELECT setval('dat_cho_id_seq', 200);
SELECT setval('hanh_khach_id_seq', (SELECT MAX(id) FROM hanh_khach));
SELECT setval('dat_dich_vu_id_seq', (SELECT MAX(id) FROM dat_dich_vu));
SELECT setval('diem_danh_tour_id_seq', (SELECT COALESCE(MAX(id), 1) FROM diem_danh_tour));
SELECT setval('danh_gia_id_seq', (SELECT COALESCE(MAX(id), 1) FROM danh_gia));
