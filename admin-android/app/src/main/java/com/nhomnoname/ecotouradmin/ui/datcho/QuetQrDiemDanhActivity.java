package com.nhomnoname.ecotouradmin.ui.datcho;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.activity.result.ActivityResultLauncher;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import com.journeyapps.barcodescanner.ScanContract;
import com.journeyapps.barcodescanner.ScanOptions;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import java.util.HashMap;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class QuetQrDiemDanhActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";
    private EditText edtMaVeThuCong;
    private ProgressBar progressQuetQr;
    private TextView tvKetQuaDiemDanh;

    private final ActivityResultLauncher<ScanOptions> barcodeLauncher = registerForActivityResult(
            new ScanContract(),
            result -> {
                if (result.getContents() != null) {
                    String maQr = result.getContents().trim();
                    edtMaVeThuCong.setText(maQr);
                    goiApiDiemDanh(maQr);
                }
            }
    );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_quet_qr);

        edtMaVeThuCong = findViewById(R.id.edtMaVeThuCong);
        progressQuetQr = findViewById(R.id.progressQuetQr);
        tvKetQuaDiemDanh = findViewById(R.id.tvKetQuaDiemDanh);
        Button btnMoCamera = findViewById(R.id.btnMoCameraQuetQr);
        Button btnXacNhan = findViewById(R.id.btnXacNhanDiemDanh);

        // Yeu cau C.1.9: Khong mat du lieu khi xoay man hinh
        if (savedInstanceState != null) {
            edtMaVeThuCong.setText(savedInstanceState.getString("ma_ve_nhap_do", ""));
            tvKetQuaDiemDanh.setText(savedInstanceState.getString("ket_qua_cu", ""));
        }

        btnMoCamera.setOnClickListener(v -> {
            ScanOptions options = new ScanOptions();
            options.setPrompt("Đưa mã QR vé điện tử EcoTour vào khung hình");
            options.setBeepEnabled(true);
            options.setOrientationLocked(false);
            barcodeLauncher.launch(options);
        });

        btnXacNhan.setOnClickListener(v -> {
            String maVe = edtMaVeThuCong.getText().toString().trim();
            if (maVe.isEmpty()) {
                edtMaVeThuCong.setError("Vui lòng quét hoặc nhập mã vé QR");
                return;
            }
            goiApiDiemDanh(maVe);
        });
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString("ma_ve_nhap_do", edtMaVeThuCong.getText().toString());
        outState.putString("ket_qua_cu", tvKetQuaDiemDanh.getText().toString());
    }

    private void goiApiDiemDanh(String maVe) {
        progressQuetQr.setVisibility(View.VISIBLE);
        Map<String, Object> body = new HashMap<>();
        body.put("maVe", maVe);

        ApiClient.get(this).diemDanhTour(body).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> res) {
                progressQuetQr.setVisibility(View.GONE);
                if (res.isSuccessful() && res.body() != null) {
                    String msg = "ĐIỂM DANH THÀNH CÔNG!\nMã vé: " + maVe + "\nChi tiết: " + res.body().toString();
                    tvKetQuaDiemDanh.setText(msg);
                    Log.i(TAG, "Diem danh QR thanh cong cho ma ve: " + maVe);
                    Toast.makeText(QuetQrDiemDanhActivity.this, "Điểm danh đoàn khách thành công!", Toast.LENGTH_SHORT).show();
                } else {
                    tvKetQuaDiemDanh.setText("Vé không hợp lệ, đã bị hủy hoặc đã điểm danh (Mã lỗi: " + res.code() + ")");
                    Toast.makeText(QuetQrDiemDanhActivity.this, "Không thể điểm danh mã vé này", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressQuetQr.setVisibility(View.GONE);
                Log.e(TAG, "Loi mang khi quet QR diem danh", t);
                Toast.makeText(QuetQrDiemDanhActivity.this, "Lỗi kết nối máy chủ khi điểm danh", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
