package com.nhomnoname.ecotouradmin.api;

import com.nhomnoname.ecotouradmin.models.DatChoItem;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.PATCH;
import retrofit2.http.POST;
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
}
