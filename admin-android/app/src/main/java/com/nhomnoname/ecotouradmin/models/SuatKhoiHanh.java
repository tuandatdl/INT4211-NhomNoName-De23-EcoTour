package com.nhomnoname.ecotouradmin.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class SuatKhoiHanh implements Serializable {
    public static final String TAG = "NhomNoName_Log";

    public int id;
    @SerializedName("tour_id") public int tourId;
    @SerializedName("ngay_di") public String ngayDi;
    @SerializedName("gio_tap_trung") public String gioTapTrung;
    @SerializedName("diem_tap_trung") public String diemTapTrung;
    @SerializedName("phuong_tien") public String phuongTien;
    @SerializedName("so_cho") public int soCho;
    @SerializedName("hdv_id") public Integer hdvId;
    @SerializedName("ten_hdv") public String tenHdv;
    @SerializedName("sdt_hdv") public String sdtHdv;
    @SerializedName("ngon_ngu_hdv") public String ngonNguHdv;
    @SerializedName("trang_thai") public String trangThai;
    @SerializedName("so_cho_da_dat") public int soChoDaDat;
    @SerializedName("so_cho_con_lai") public int soChoConLai;
}

