package com.nhomnoname.ecotouradmin.ui.auth;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.TokenStore;
// Import cac man hinh se duoc xay dung o Dot 4
// import com.nhomnoname.ecotouradmin.ui.datcho.DatChoListActivity;
// import com.nhomnoname.ecotouradmin.ui.datcho.QuetQrDiemDanhActivity;
// import com.nhomnoname.ecotouradmin.ui.baocao.BaoCaoChartActivity;

public class MainActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        String vaiTro = TokenStore.layVaiTro(this);
        TextView tvWelcome = findViewById(R.id.tvWelcome);
        tvWelcome.setText("Xin chào Admin (" + vaiTro + ") - NhomNoName");

        Button btnBaoCao = findViewById(R.id.btnBaoCao);
        // Phan quyen: Chi QUAN_TRI moi thay chuc nang xem bao cao bieu do
        if ("QUAN_TRI".equals(vaiTro)) {
            btnBaoCao.setVisibility(View.VISIBLE);
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
