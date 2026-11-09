package com.nhomnoname.ecotouradmin.models;

import com.google.gson.annotations.SerializedName;

public class DatChoItem {
    public static final String TAG = "NhomNoName_Log";

    public int id;
    @SerializedName("suat_id") public int suatId;
    @SerializedName("khach_id") public int khachId;
    @SerializedName("so_nguoi_lon") public int soNguoiLon;
    @SerializedName("so_tre_em") public int soTreEm;
    @SerializedName("tong_tien") public int tongTien;
    @SerializedName("tien_hoan") public int tienHoan;
    @SerializedName("ma_ve") public String maVe;
    @SerializedName("trang_thai") public String trangThai;
    @SerializedName("dat_luc") public String datLuc;
    @SerializedName("ho_ten_khach") public String hoTenKhach;
    @SerializedName("ten_tour") public String tenTour;
}
