package com.nhomnoname.ecotouradmin.api;

import com.nhomnoname.ecotouradmin.models.DatChoItem;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.PATCH;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Path;
import retrofit2.http.Query;

public interface ApiService {
    String TAG = "NhomNoName_Log";

    @POST("auth/dang-nhap")
    Call<Map<String, Object>> dangNhap(@Body Map<String, String> body);

    @GET("dat-cho")
    Call<List<DatChoItem>> layDanhSachDatCho(@Query("suatId") Integer suatId, @Query("trangThai") String trangThai);

    @PATCH("dat-cho/{id}/huy")
    Call<Map<String, Object>> huyDatCho(@Path("id") int id);

    @POST("dat-cho/diem-danh")
    Call<Map<String, Object>> diemDanhTour(@Body Map<String, Object> body);

    @GET("bao-cao/lap-day")
    Call<Map<String, Object>> layBaoCaoLapDay();

    // =========================================================================
    // API QUẢN TRỊ TOUR & SUẤT KHỞI HÀNH (TV2 phụ trách)
    // =========================================================================

    @GET("quan-ly/tour")
    Call<Map<String, Object>> layDanhSachTourQuanLy(
            @Query("trang_thai") String trangThai,
            @Query("tu_khoa") String tuKhoa
    );

    @GET("quan-ly/tour/{id}")
    Call<Map<String, Object>> layChiTietTour(@Path("id") int tourId);

    @POST("quan-ly/tour")
    Call<Map<String, Object>> themTour(@Body Map<String, Object> body);

    @PUT("quan-ly/tour/{id}")
    Call<Map<String, Object>> capNhatTour(@Path("id") int tourId, @Body Map<String, Object> body);

    @DELETE("quan-ly/tour/{id}")
    Call<Map<String, Object>> xoaTour(@Path("id") int tourId);

    // Suất khởi hành
    @GET("quan-ly/tour/{id}/suat")
    Call<Map<String, Object>> layDanhSachSuatCuaTour(@Path("id") int tourId);

    @POST("quan-ly/tour/{id}/suat")
    Call<Map<String, Object>> themSuatChoTour(@Path("id") int tourId, @Body Map<String, Object> body);

    @PUT("quan-ly/tour/suat/{id}")
    Call<Map<String, Object>> capNhatSuat(@Path("id") int suatId, @Body Map<String, Object> body);

    @DELETE("quan-ly/tour/suat/{id}")
    Call<Map<String, Object>> xoaSuat(@Path("id") int suatId);

    // Danh mục
    @GET("danh-muc/hdv")
    Call<Map<String, Object>> layDanhSachHdv();

    @GET("danh-muc/diem-den")
    Call<Map<String, Object>> layDanhSachDiemDen();
}
