package com.nhomnoname.ecotouradmin.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Tour implements Serializable {
    public static final String TAG = "NhomNoName_Log";

    public int id;
    public String ten;
    @SerializedName("mo_ta") public String moTa;
    @SerializedName("so_ngay") public int soNgay;
    @SerializedName("gia_nguoi_lon") public double giaNguoiLon;
    @SerializedName("gia_tre_em") public double giaTreEm;
    @SerializedName("anh_url") public String anhUrl;
    @SerializedName("trang_thai") public String trangThai;
    @SerializedName("tong_so_suat") public int tongSoSuat;
    @SerializedName("tong_moc_lich_trinh") public int tongMocLichTrinh;
    @SerializedName("danh_gia_sao") public double danhGiaSao;
}

