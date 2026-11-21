package com.nhomnoname.ecotouradmin.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class HuongDanVien implements Serializable {
    public static final String TAG = "NhomNoName_Log";

    public int id;
    @SerializedName("nguoi_dung_id") public int nguoiDungId;
    @SerializedName("ho_ten") public String hoTen;
    @SerializedName("ngon_ngu") public String ngonNgu;
    @SerializedName("chung_chi") public String chungChi;
    public String sdt;
    public String email;
    @SerializedName("so_suat_phu_trach") public int soSuatPhuTrach;
    @SerializedName("danh_gia_sao") public double danhGiaSao;
}

