package com.nhomnoname.ecotouradmin.ui.auth;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.TokenStore;
import com.nhomnoname.ecotouradmin.ui.baocao.BaoCaoChartActivity;
import com.nhomnoname.ecotouradmin.ui.danhmuc.HdvListActivity;
import com.nhomnoname.ecotouradmin.ui.datcho.DatChoListActivity;
import com.nhomnoname.ecotouradmin.ui.datcho.QuetQrDiemDanhActivity;
import com.nhomnoname.ecotouradmin.ui.suat.SuatListActivity;
import com.nhomnoname.ecotouradmin.ui.tour.TourListActivity;

public class MainActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        String vaiTro = TokenStore.layVaiTro(this);
        TextView tvWelcome = findViewById(R.id.tvWelcome);
        tvWelcome.setText("Xin chào Admin (" + (vaiTro != null ? vaiTro : "QUAN_TRI") + ") - NhomNoName");

        Button btnQuanLyTour = findViewById(R.id.btnQuanLyTour);
        Button btnQuanLySuat = findViewById(R.id.btnQuanLySuat);
        Button btnQuanLyHdv = findViewById(R.id.btnQuanLyHdv);
        Button btnQuanLyDatCho = findViewById(R.id.btnQuanLyDatCho);
        Button btnQuetQr = findViewById(R.id.btnQuetQr);
        Button btnBaoCao = findViewById(R.id.btnBaoCao);
        Button btnLogout = findViewById(R.id.btnLogout);

        // Điều hướng các màn hình do TV2 (Nguyễn Nhật Duy) phụ trách
        btnQuanLyTour.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, TourListActivity.class)));

        btnQuanLySuat.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, SuatListActivity.class)));

        btnQuanLyHdv.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, HdvListActivity.class)));

        // Điều hướng các màn hình do TV1 (Đỗ Lê Tuấn Đạt) phụ trách
        btnQuanLyDatCho.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, DatChoListActivity.class)));

        btnQuetQr.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, QuetQrDiemDanhActivity.class)));

        btnBaoCao.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, BaoCaoChartActivity.class)));

        // Phân quyền hiển thị theo vai trò (QUAN_TRI xem toàn bộ; DIEU_HANH xem Suất, Đặt chỗ & Quét QR)
        boolean laQuanTri = vaiTro == null || "QUAN_TRI".equals(vaiTro);
        boolean laDieuHanh = "DIEU_HANH".equals(vaiTro);

        btnQuanLyTour.setVisibility(laQuanTri ? View.VISIBLE : View.GONE);
        btnQuanLySuat.setVisibility((laQuanTri || laDieuHanh) ? View.VISIBLE : View.GONE);
        btnQuanLyHdv.setVisibility(laQuanTri ? View.VISIBLE : View.GONE);
        btnBaoCao.setVisibility(laQuanTri ? View.VISIBLE : View.GONE);

        // Nghiệp vụ điều hành chuyến đi mở cho cả 2 vai trò
        btnQuanLyDatCho.setVisibility(View.VISIBLE);
        btnQuetQr.setVisibility(View.VISIBLE);

        btnLogout.setOnClickListener(v -> {
            TokenStore.xoaPhien(this);
            startActivity(new Intent(this, LoginActivity.class));
            finish();
        });
    }
}
