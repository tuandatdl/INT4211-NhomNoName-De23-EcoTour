# Đề 23: Hệ thống đặt tour du lịch sinh thái Cần Giờ – Vũng Tàu (INT4211)

## 1. Danh sách thành viên & Phân công nhiệm vụ (Nhóm NoName)
| Mã nhóm | MSSV | Họ và tên | Phần được phân công |
| :--- | :--- | :--- | :--- |
| Nhóm NoName | 231A290089 | Đỗ Lê Tuấn Đạt (Nhóm trưởng) | Backend: xác thực JWT, API đặt chỗ (transaction chống vượt chỗ), hủy tour, báo cáo; deploy Render; App Admin: quét QR vé, biểu đồ |
| Nhóm NoName | 231A010060 | Nguyễn Nhật Duy | CSDL Supabase (`schema.sql`, `seed.sql`), API tour và danh mục; App Admin: quản lý tour, lịch trình, suất khởi hành, hướng dẫn viên, dịch vụ kèm |
| Nhóm NoName | 221A010146 | Phan Thị Anh Thư | App Client: đăng nhập/đăng ký, duyệt và lọc tour, xem chi tiết lịch trình theo giờ, nhắc giờ tập trung, đánh giá tour và HDV |
| Nhóm NoName | 231A290127 | Bùi Quang Duy | App Client: chọn suất khởi hành, đặt chỗ và nhập hành khách, chọn dịch vụ kèm, vé điện tử QR, lịch sử và hủy đặt chỗ |

## 2. Hồ sơ Mốc Tuần 9 (Chốt phân tích)
- Sơ đồ Use Case, Sơ đồ CSDL (ERD 13 bảng) và Bảng phân công: [docs/PHAN_TICH_TUAN_9.md](docs/PHAN_TICH_TUAN_9.md)
- Kịch bản khởi tạo 13 bảng PostgreSQL: [backend/schema.sql](backend/schema.sql)
- Dữ liệu mẫu chuẩn định lượng Đề 23: [backend/seed.sql](backend/seed.sql)

## 3. Tài khoản thử nghiệm (Mật khẩu chung: `123456`)
- **Quản trị viên (`QUAN_TRI`)**: `admin@ecotour.vn` (Đỗ Lê Tuấn Đạt)
- **Điều hành / HDV (`DIEU_HANH`)**: `dieuhanh@ecotour.vn` (Nguyễn Nhật Duy)
- **Khách du lịch (`KHACH`)**: `khach1@gmail.com` (Phan Thị Anh Thư) / `khach2@gmail.com` (Bùi Quang Duy)
