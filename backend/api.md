# TÀI LIỆU KỸ THUẬT API - ECOTOUR CẦN GIỜ VŨNG TÀU (ĐỀ 23)
**Nhóm:** NhomNoName | **Phụ trách tài liệu:** TV2 (Nguyễn Nhật Duy - CSDL, Tour & Danh mục)

---

## 1. QUY CHUẨN CHUNG
- **Base URL Local:** `http://localhost:3000`
- **Base URL Render:** `https://ecotour-nhomnoname.onrender.com`
- **Định dạng dữ liệu:** `application/json; charset=utf-8`
- **Xác thực:** Bearer Token trong tiêu đề:
  ```http
  Authorization: Bearer <jwt_token>
  ```
- **Quy chuẩn phản hồi:**
  - Thành công: HTTP 200 / 201 kèm `{ "thanhCong": true, "duLieu": ... }`
  - Thất bại: HTTP 400 / 401 / 403 / 404 / 409 / 500 kèm `{ "thanhCong": false, "thongBao": "..." }`

---

## 2. NHÓM API CÔNG KHAI (CLIENT FLUTTER & DÙNG CHUNG)

### 2.1. Kiểm tra sức khỏe hệ thống
- **Endpoint:** `GET /health`
- **Quyền:** Mọi đối tượng
- **Response (200 OK):**
  ```json
  {
    "trangThai": "OK",
    "thoiGian": "2026-11-17T00:00:00.000Z",
    "nhom": "Nhóm NoName",
    "deTai": "Đề 23 - Hệ thống đặt tour du lịch sinh thái Cần Giờ – Vũng Tàu"
  }
  ```

### 2.2. Danh sách Tour du lịch sinh thái
- **Endpoint:** `GET /tour`
- **Query Params:**
  - `khu_vuc` (string): 'Cần Giờ' | 'Vũng Tàu'
  - `so_ngay` (int): 1, 2, 3...
  - `gia_max` (number): Mức giá trần
  - `tu_khoa` (string): Tìm kiếm theo tên hoặc mô tả
- **Response (200 OK):**
  ```json
  {
    "thanhCong": true,
    "tongSo": 15,
    "duLieu": [
      {
        "id": 1,
        "ten": "Tour 1: Khám phá Rừng Sác Cần Giờ - Đảo Khỉ 1 Ngày",
        "mo_ta": "Hành trình về nguồn kết hợp trải nghiệm hệ sinh thái rừng ngập mặn Cần Giờ.",
        "so_ngay": 1,
        "gia_nguoi_lon": "650000.00",
        "gia_tre_em": "450000.00",
        "anh_url": "https://images.unsplash.com/photo-1544551763-46a013bb70d5",
        "trang_thai": "HOAT_DONG",
        "danh_gia_sao": 4.8,
        "so_luot_danh_gia": 12
      }
    ]
  }
  ```

### 2.3. Lịch trình chi tiết theo giờ của một Tour
- **Endpoint:** `GET /tour/:id/lich-trinh`
- **Response (200 OK):**
  ```json
  {
    "thanhCong": true,
    "tour": { "id": 1, "ten": "Tour 1...", "so_ngay": 1 },
    "duLieu": [
      {
        "id": 1,
        "ngay_thu": 1,
        "thu_tu": 1,
        "gio": "07:30",
        "hoat_dong": "Khởi hành từ trung tâm TP.HCM, qua phà Bình Khánh tiến vào khu sinh quyển.",
        "ten_diem_den": "Khu dự trữ sinh quyển Rừng ngập mặn Cần Giờ",
        "khu_vuc_diem_den": "Cần Giờ",
        "vi_do": "10.5083000",
        "kinh_do": "106.8794000"
      }
    ]
  }
  ```

### 2.4. Danh sách Suất khởi hành của Tour (kèm tính số chỗ còn lại)
- **Endpoint:** `GET /tour/:id/suat`
- **Response (200 OK):**
  ```json
  {
    "thanhCong": true,
    "tour_id": 1,
    "duLieu": [
      {
        "id": 1,
        "tour_id": 1,
        "ngay_di": "2026-11-20",
        "gio_tap_trung": "06:30",
        "diem_tap_trung": "Nhà Văn hóa Thanh Niên - Số 4 Phạm Ngọc Thạch, Quận 1, TP.HCM",
        "phuong_tien": "Xe du lịch sinh thái tiện nghi",
        "so_cho": 30,
        "hdv_id": 1,
        "ten_hdv": "Nguyễn Minh Khôi",
        "sdt_hdv": "0918111001",
        "trang_thai": "MO_BAN",
        "so_cho_da_dat": 10,
        "so_cho_con_lai": 20
      }
    ]
  }
  ```

---

## 3. NHÓM API QUẢN LÝ DANH MỤC (`/danh-muc`)

### 3.1. Danh mục Điểm đến sinh thái
| Phương thức | Endpoint | Yêu cầu xác thực | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET` | `/danh-muc/diem-den` | Không | Danh sách điểm đến (lọc `khu_vuc`, `tu_khoa`) |
| `GET` | `/danh-muc/diem-den/:id` | Không | Chi tiết điểm đến theo ID |
| `POST` | `/danh-muc/diem-den` | `QUAN_TRI`, `DIEU_HANH` | Thêm điểm đến mới |
| `PUT` | `/danh-muc/diem-den/:id` | `QUAN_TRI`, `DIEU_HANH` | Cập nhật thông tin điểm đến |
| `DELETE` | `/danh-muc/diem-den/:id` | `QUAN_TRI`, `DIEU_HANH` | Xóa điểm đến (chặn nếu đang trong lịch trình) |

**Body mẫu POST / PUT Điểm đến:**
```json
{
  "ten": "Đảo Thiềng Liềng",
  "khu_vuc": "Cần Giờ",
  "mo_ta": "Du lịch cộng đồng sinh thái làm muối",
  "vi_do": 10.5512,
  "kinh_do": 106.9845,
  "anh_url": "https://images.unsplash.com/photo-..."
}
```

---

### 3.2. Danh mục Hướng dẫn viên
| Phương thức | Endpoint | Yêu cầu xác thực | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET` | `/danh-muc/hdv` | Không | Danh sách HDV (kèm số suất phụ trách, số sao đánh giá) |
| `GET` | `/danh-muc/hdv/:id` | Không | Chi tiết HDV và các suất đang phụ trách |
| `POST` | `/danh-muc/hdv` | `QUAN_TRI`, `DIEU_HANH` | Thêm hồ sơ HDV (gắn với người dùng `DIEU_HANH`) |
| `PUT` | `/danh-muc/hdv/:id` | `QUAN_TRI`, `DIEU_HANH` | Cập nhật hồ sơ HDV |
| `DELETE` | `/danh-muc/hdv/:id` | `QUAN_TRI`, `DIEU_HANH` | Xóa HDV (chặn nếu đang phụ trách suất `MO_BAN`) |

**Body mẫu POST HDV:**
```json
{
  "nguoi_dung_id": 2,
  "ho_ten": "Nguyễn Minh Khôi",
  "ngon_ngu": "Tiếng Việt, Tiếng Anh",
  "chung_chi": "Thẻ HDV Quốc tế số 792011",
  "sdt": "0918111001"
}
```

---

### 3.3. Danh mục Dịch vụ kèm theo
| Phương thức | Endpoint | Yêu cầu xác thực | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET` | `/danh-muc/dich-vu-kem` | Không | Lấy danh sách dịch vụ (thuê xe đạp, ăn trưa, cano...) |
| `POST` | `/danh-muc/dich-vu-kem` | `QUAN_TRI`, `DIEU_HANH` | Thêm dịch vụ kèm theo |
| `PUT` | `/danh-muc/dich-vu-kem/:id`| `QUAN_TRI`, `DIEU_HANH` | Cập nhật giá / tên dịch vụ |
| `DELETE` | `/danh-muc/dich-vu-kem/:id`| `QUAN_TRI`, `DIEU_HANH` | Xóa dịch vụ (chặn nếu đã có đơn đặt) |

---

## 4. NHÓM API QUẢN TRỊ TOUR & SUẤT KHỞI HÀNH (`/quan-ly/tour`)

### 4.1. Quản lý Tour Du lịch
| Phương thức | Endpoint | Yêu cầu xác thực | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET` | `/quan-ly/tour` | `QUAN_TRI`, `DIEU_HANH` | Danh sách tour quản trị (kèm số suất, số mốc lịch trình) |
| `GET` | `/quan-ly/tour/:id` | `QUAN_TRI`, `DIEU_HANH` | Chi tiết tour kèm toàn bộ lịch trình |
| `POST` | `/quan-ly/tour` | `QUAN_TRI`, `DIEU_HANH` | Tạo tour du lịch mới |
| `PUT` | `/quan-ly/tour/:id` | `QUAN_TRI`, `DIEU_HANH` | Cập nhật thông tin tour |
| `DELETE` | `/quan-ly/tour/:id` | `QUAN_TRI` | Xóa tour (chuyển `TAM_NGUNG` nếu có suất đang mở) |

**Body mẫu POST Tour:**
```json
{
  "ten": "Tour Cần Giờ Trải Nghiệm Đạp Xe Rừng Đước 1 Ngày",
  "mo_ta": "Tour thể thao sinh thái kết hợp ẩm thực địa phương",
  "so_ngay": 1,
  "gia_nguoi_lon": 680000,
  "gia_tre_em": 450000,
  "anh_url": "https://..."
}
```

---

### 4.2. Quản lý Lịch trình Tour
| Phương thức | Endpoint | Yêu cầu xác thực | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET` | `/quan-ly/tour/:id/lich-trinh` | `QUAN_TRI`, `DIEU_HANH` | Xem lịch trình tour |
| `POST` | `/quan-ly/tour/:id/lich-trinh` | `QUAN_TRI`, `DIEU_HANH` | Thêm mốc hoạt động mới |
| `PUT` | `/quan-ly/tour/lich-trinh/:id` | `QUAN_TRI`, `DIEU_HANH` | Cập nhật mốc hoạt động |
| `DELETE` | `/quan-ly/tour/lich-trinh/:id` | `QUAN_TRI`, `DIEU_HANH` | Xóa mốc hoạt động |

**Body mẫu POST Lịch trình:**
```json
{
  "ngay_thu": 1,
  "thu_tu": 2,
  "gio": "09:30 - 11:30",
  "hoat_dong": "Chèo xuồng máy tham quan Đầm Dơi và câu cá giải trí sinh thái",
  "diem_den_id": 2
}
```

---

### 4.3. Quản lý Suất khởi hành
| Phương thức | Endpoint | Yêu cầu xác thực | Mô tả |
| :--- | :--- | :--- | :--- |
| `GET` | `/quan-ly/tour/:id/suat` | `QUAN_TRI`, `DIEU_HANH` | Danh sách suất của tour kèm số chỗ còn lại |
| `POST` | `/quan-ly/tour/:id/suat` | `QUAN_TRI`, `DIEU_HANH` | Thêm suất khởi hành mới (kiểm tra trùng lịch HDV) |
| `PUT` | `/quan-ly/tour/suat/:id` | `QUAN_TRI`, `DIEU_HANH` | Cập nhật suất (đổi giờ, HDV, số chỗ, trạng thái) |
| `DELETE` | `/quan-ly/tour/suat/:id` | `QUAN_TRI`, `DIEU_HANH` | Hủy / Xóa suất (chuyển `DA_HUY` nếu đã có khách) |

**Body mẫu POST Suất khởi hành:**
```json
{
  "ngay_di": "2026-11-25",
  "gio_tap_trung": "06:30",
  "diem_tap_trung": "Nhà Văn Hóa Thanh Niên, Q1, TP.HCM",
  "phuong_tien": "Xe du lịch sinh thái tiện nghi",
  "so_cho": 30,
  "hdv_id": 1
}
```

