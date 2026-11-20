# HỒ SƠ KIỂM THỬ HỆ THỐNG (28 TRƯỜNG HỢP KIỂM THỬ THỰC TẾ)
**Học phần:** INT4211 – Lập trình trên các thiết bị di động  
**Đề tài 23:** Hệ thống đặt tour du lịch sinh thái Cần Giờ – Vũng Tàu  
**Nhóm thực hiện:** Nhóm NoName  
**Thành viên phụ trách kiểm thử:** Bùi Quang Duy (MSSV: 231A290127 – Thành viên 4)

---

## 1. Bảng Tổng Hợp 28 Trường Hợp Kiểm Thử (Đạt yêu cầu mục D.2.7: $\ge 25$ Test Cases)

| Mã TC | Phân hệ | Tên trường hợp kiểm thử | Dữ liệu đầu vào / Các bước thực hiện | Kết quả kỳ vọng | Kết quả thực tế | Đánh giá |
| :---: | :---: | :--- | :--- | :--- | :--- | :---: |
| **TC01** | Backend / Cloud | Kiểm tra sức khỏe máy chủ (`GET /health`) | Mở đường dẫn `/health` từ trình duyệt hoặc Postman | Trả về HTTP `200 OK` kèm JSON nhận diện `NhomNoName`, Đề 23 | Trả về `200 OK` đúng định dạng JSON | **Đạt** |
| **TC02** | Auth / Bảo mật | Đăng ký tài khoản khách mới hợp lệ | `POST /auth/dang-ky` với email mới, mật khẩu `123456`, họ tên đầy đủ | HTTP `201 Created`, mật khẩu được băm bằng `bcrypt`, vai trò mặc định `KHACH` | Tạo tài khoản thành công, không trả về `mat_khau_hash` | **Đạt** |
| **TC03** | Auth / Bảo mật | Đăng ký trùng email đã tồn tại | `POST /auth/dang-ky` với `khach1@gmail.com` | HTTP `409 Conflict` kèm thông báo `Email đã tồn tại` | Trả về mã `409` và thông báo tiếng Việt rõ ràng | **Đạt** |
| **TC04** | Auth / Bảo mật | Đăng nhập sai mật khẩu | `POST /auth/dang-nhap` với `khach1@gmail.com` và mật khẩu sai | HTTP `401 Unauthorized`, thông báo `Email hoặc mật khẩu không đúng` | Trả về `401`, chặn đăng nhập | **Đạt** |
| **TC05** | Auth / Bảo mật | Gọi API cần xác thực nhưng không gửi JWT Token | Gọi `GET /dat-cho/cua-toi` không có header `Authorization` | HTTP `401 Unauthorized` kèm thông báo thiếu token | Trả về `401`, App Client bật hộp thoại yêu cầu đăng nhập | **Đạt** |
| **TC06** | Phân quyền | Khách du lịch (`KHACH`) cố gọi API báo cáo của Quản trị (`QUAN_TRI`) | Dùng JWT của `khach2@gmail.com` gọi `GET /bao-cao/lap-day` bằng Postman | HTTP `403 Forbidden` chặn ngay tại middleware phía máy chủ | Trả về `403 Không có quyền thực hiện thao tác này` | **Đạt** |
| **TC07** | Phân quyền Admin | Điều hành (`DIEU_HANH`) đăng nhập vào App Admin Android | Đăng nhập `dieuhanh@ecotour.vn` trên App Admin | Chỉ hiển thị chức năng Suất khởi hành, Đặt chỗ và Quét QR; ẩn Báo cáo doanh thu | Giao diện phân quyền đúng theo vai trò `DIEU_HANH` | **Đạt** |
| **TC08** | Danh mục & Tour | Tải danh sách suất khởi hành kèm số chỗ còn lại | Mở màn hình `SuatPickerScreen` gọi `GET /tour/1/suat` | Hiển thị danh sách suất, cột `so_cho_con_lai` được tính chính xác từ CSDL | Hiển thị đầy đủ ngày đi, giờ tập trung, HDV và badge số chỗ | **Đạt** |
| **TC09** | Chọn Suất (Client) | Chặn chọn suất khởi hành đã hết chỗ hoặc bị khóa | Trên `SuatPickerScreen`, bấm vào suất có `so_cho_con_lai = 0` hoặc `DA_KHOA` | Badge hiển thị màu đỏ `HẾT CHỖ`, nút chọn bị vô hiệu hóa (`disabled`) | Không thể bấm mở Form đặt chỗ đối với suất hết chỗ | **Đạt** |
| **TC10** | Form Đặt chỗ | Kiểm tra Validator khi bỏ trống họ tên hành khách | Tại `BookingFormScreen`, xóa trống ô Họ và tên rồi bấm `Xác nhận đặt chỗ` | Form chặn gửi API, viền ô nhập báo đỏ `Vui lòng nhập họ và tên hành khách` | Chặn gửi thành công, hiện thông báo lỗi ngay dưới ô nhập | **Đạt** |
| **TC11** | Form Đặt chỗ | Kiểm tra Validator năm sinh Người lớn $< 12$ tuổi | Chọn vé Người lớn nhưng nhập năm sinh `2020` rồi bấm gửi | Validator báo lỗi `Người lớn phải >= 12 tuổi`, chặn gửi request | Báo lỗi chính xác tại ô Năm sinh | **Đạt** |
| **TC12** | Form Đặt chỗ | Kiểm tra Validator năm sinh Trẻ em $\ge 12$ tuổi | Thêm 1 vé Trẻ em nhưng nhập năm sinh `2005` | Validator báo lỗi `Trẻ em phải < 12 tuổi`, chặn gửi request | Báo lỗi chính xác, không gọi API | **Đạt** |
| **TC13** | Form Đặt chỗ | Kiểm tra Validator số CCCD của Trưởng đoàn | Nhập CCCD chỉ có 9 chữ số (`079096001`) hoặc chứa chữ cái | Validator báo lỗi `CCCD phải gồm đúng 12 chữ số` | Chặn gửi khi CCCD chưa đủ 12 chữ số | **Đạt** |
| **TC14** | Form Đặt chỗ | Giữ nguyên dữ liệu hành khách khi tăng/giảm số lượng vé | Nhập xong tên Khách #1, sau đó bấm `+` thêm Khách #2 hoặc thêm Trẻ em | Thông tin Khách #1 đã gõ không bị xóa hay nhảy lệch sang ô khác (`ObjectKey`) | Dữ liệu Khách #1 giữ nguyên, chỉ thêm ô trống cho khách mới | **Đạt** |
| **TC15** | Dịch vụ kèm | Chọn dịch vụ sinh thái kèm theo và cập nhật tổng tiền tạm tính | Chọn 2 suất ăn trưa hải sản (`180.000đ`) + 1 combo Kayak (`120.000đ`) | Tổng tiền dịch vụ và tổng tiền tạm tính tự động cộng dồn ngay trên màn hình | Hiển thị đúng tổng tiền vé + tiền dịch vụ kèm theo | **Đạt** |
| **TC16** | Đặt chỗ & Giá | Máy chủ tự tính tổng tiền và cấp mã vé QR (`POST /dat-cho`) | Gửi yêu cầu đặt 2 người lớn, 1 trẻ em kèm dịch vụ hợp lệ | HTTP `201 Created`, tổng tiền do máy chủ tính từ bảng `tour` & `dich_vu_kem`, sinh mã `VE-CGVT-XXXX` | Tạo đơn thành công, hiển thị tổng tiền từ máy chủ trả về | **Đạt** |
| **TC17** | **Điểm nhấn Đề 23** | **Chống đặt vượt số chỗ khi 2 khách đặt cùng lúc vào suất chỉ còn 1 chỗ** | Suất còn 1 chỗ cuối; 2 request `POST /dat-cho` gửi đồng thời (`test-concurrency.js`) | Nhờ Transaction + `SELECT ... FOR UPDATE`, đúng 1 request thành công (`201`), request còn lại nhận `409 Conflict` | 1 đơn thành công, 1 đơn bị từ chối với mã `409`, số chỗ còn lại = `0` (không bị âm) | **Đạt** |
| **TC18** | Đặt chỗ (Client) | Ứng dụng Flutter xử lý mã lỗi `409 Conflict` khi hết chỗ | Khách bấm xác nhận đặt chỗ đúng lúc suất vừa hết chỗ (`409`) | Hiện hộp thoại cảnh báo `Không đủ chỗ` và tự động quay về tải lại danh sách suất | Hiện `AlertDialog` thông báo rõ số chỗ còn lại và làm mới danh sách | **Đạt** |
| **TC19** | Vé điện tử QR | Hiển thị mã QR động và trạng thái điểm danh (`TicketQrScreen`) | Mở màn hình Xem Vé QR từ đơn vừa đặt (`GET /dat-cho/:id/ve`) | `QrImageView` vẽ mã QR đúng theo `ma_ve`, hiển thị danh sách khách và dịch vụ kèm | Mã QR rõ nét, hiển thị trạng thái `Chờ quét` / `Đã lên xe` cho từng khách | **Đạt** |
| **TC20** | Quét QR (Admin) | Hướng dẫn viên quét mã QR vé tại điểm tập trung | Trên App Admin, quét mã `VE-CGVT-0001` (`POST /dat-cho/diem-danh`) | Máy chủ ghi nhận vào bảng `diem_danh_tour`, trả về trạng thái điểm danh thành công | Điểm danh thành công; trên App Client vé cập nhật trạng thái `Đã lên xe` | **Đạt** |
| **TC21** | Quét QR (Admin) | Chặn điểm danh đối với vé đã bị hủy | Quét mã QR của đơn có trạng thái `DA_HUY` | Máy chủ từ chối với mã `409 Conflict`: `Vé này đã bị hủy` | App Admin cảnh báo vé không hợp lệ do đã hủy | **Đạt** |
| **TC22** | Đơn của tôi | Hiển thị danh sách đơn bằng `ListView.builder` và lọc theo trạng thái | Mở tab `Đơn Của Tôi`, bấm các `ChoiceChip`: *Tất cả / Đã xác nhận / Đã hủy / Hoàn tất* | Danh sách cập nhật đúng các đơn theo trạng thái đang chọn | Lọc mượt mà, hiển thị rõ mã vé, ngày đi, tổng tiền và tiền hoàn | **Đạt** |
| **TC23** | Hủy tour & Hoàn tiền | Hủy đặt chỗ trước giờ khởi hành $\ge 72$ giờ | Bấm `Hủy tour` trên đơn có ngày đi cách hiện tại $> 3$ ngày (`PATCH /dat-cho/:id/huy`) | Máy chủ tra bảng `chinh_sach_huy`, tính mức hoàn **100%** tổng tiền và đổi trạng thái `DA_HUY` | Hoàn 100% tiền vé, cập nhật trạng thái `ĐÃ HỦY` ngay trên danh sách | **Đạt** |
| **TC24** | Hủy tour & Hoàn tiền | Hủy đặt chỗ trong khoảng từ $24$ giờ đến dưới $72$ giờ trước khởi hành | Gọi hủy đối với suất khởi hành còn khoảng 36 giờ | Máy chủ tự động áp dụng bậc hoàn **50%** tổng tiền | `tien_hoan = 50% tong_tien`, trả về đúng phần trăm hoàn | **Đạt** |
| **TC25** | Hủy tour & Hoàn tiền | Hủy đặt chỗ sát giờ khởi hành ($< 24$ giờ) | Gọi hủy đối với suất khởi hành còn dưới 24 giờ | Máy chủ áp dụng bậc hoàn **0%** (`tien_hoan = 0`), trạng thái chuyển sang `DA_HUY` | Hoàn `0đ`, thông báo rõ số giờ còn lại và mức hoàn 0% | **Đạt** |
| **TC26** | Giao diện Client | Hộp thoại xác nhận trước khi hủy + `SnackBar` có nút `Hoàn tác` (Mục C.2.6) | Bấm nút `Hủy tour` ở màn hình Đơn Của Tôi | Bật `AlertDialog` cảnh báo chính sách hoàn tiền; sau khi hủy hiện `SnackBar` kèm `SnackBarAction('Hoàn tác')` | Hiện đúng hộp thoại xác nhận và thanh `SnackBar` có nút Hoàn tác màu vàng | **Đạt** |
| **TC27** | Xử lý lỗi mạng | Tắt kết nối mạng / máy chủ chưa phản hồi khi mở ứng dụng (Mục C.2.7) | Ngắt mạng rồi mở màn hình Chọn Suất và Đơn Của Tôi | Ứng dụng không bị văng (crash), hiển thị thông báo lỗi tiếng Việt kèm nút `Thử lại` | Hiển thị đúng 3 trạng thái: Đang tải $\rightarrow$ Lỗi mạng có nút `Thử lại` | **Đạt** |
| **TC28** | Chất lượng mã nguồn | Kiểm tra tĩnh mã nguồn Flutter bằng `flutter analyze` / `dart analyze` (Mục C.2.10) | Chạy lệnh `dart analyze lib` trong thư mục `client-flutter` | `No issues found!` (0 lỗi, 0 cảnh báo), toàn bộ sau `await` đều có `if (!mounted) return;` | Kết quả phân tích đạt **0 issue** | **Đạt** |

---

## 2. Quy Trình Kiểm Thử Điểm Nhấn Kỹ Thuật Đề 23 (Chống Đặt Vượt Số Chỗ)

1. **Cơ chế tại Backend (`backend/src/routes/datCho.routes.js`):**
   * Toàn bộ thao tác kiểm tra số chỗ còn lại và tạo bản ghi `dat_cho` nằm trong một giao dịch `BEGIN ... COMMIT` (`trongGiaoDich`).
   * Dòng suất khởi hành được khóa bi quan bằng câu lệnh:
     ```sql
     SELECT s.id, s.so_cho, ... FROM suat_khoi_hanh s WHERE s.id = $1 FOR UPDATE OF s
     ```
   * Khi 2 khách cùng bấm đặt chỗ vào suất chỉ còn 1 chỗ cuối cùng, giao dịch thứ hai buộc phải chờ giao dịch thứ nhất `COMMIT` xong mới đọc được số chỗ đã đặt mới nhất, từ đó trả về mã lỗi `409 Conflict` thay vì cho cả hai cùng thành công.
2. **Cách chạy kịch bản kiểm thử tự động:**
   ```bash
   cd backend
   node scripts/test-concurrency.js
   ```
