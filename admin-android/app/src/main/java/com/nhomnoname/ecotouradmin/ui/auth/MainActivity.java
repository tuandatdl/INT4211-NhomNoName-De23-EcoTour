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
import com.nhomnoname.ecotouradmin.ui.datcho.DatChoListActivity;
import com.nhomnoname.ecotouradmin.ui.datcho.QuetQrDiemDanhActivity;

public class MainActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        String vaiTro = TokenStore.layVaiTro(this);
        TextView tvWelcome = findViewById(R.id.tvWelcome);
        tvWelcome.setText("Xin chào Admin (" + vaiTro + ") - NhomNoName");

        Button btnQuanLyDatCho = findViewById(R.id.btnQuanLyDatCho);
        Button btnQuetQr = findViewById(R.id.btnQuetQr);
        Button btnBaoCao = findViewById(R.id.btnBaoCao);

        btnQuanLyDatCho.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, DatChoListActivity.class)));

        btnQuetQr.setOnClickListener(v ->
                startActivity(new Intent(MainActivity.this, QuetQrDiemDanhActivity.class)));

        // Phan quyen: Chi QUAN_TRI moi thay chuc nang xem bao cao bieu do
        if ("QUAN_TRI".equals(vaiTro)) {
            btnBaoCao.setVisibility(View.VISIBLE);
            btnBaoCao.setOnClickListener(v ->
                    startActivity(new Intent(MainActivity.this, BaoCaoChartActivity.class)));
        } else {
            btnBaoCao.setVisibility(View.GONE);
        }

        findViewById(R.id.btnLogout).setOnClickListener(v -> {
            TokenStore.xoaPhien(this);
            startActivity(new Intent(this, LoginActivity.class));
            finish();
        });
    }
}
