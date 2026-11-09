package com.nhomnoname.ecotouradmin.ui.auth;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import com.nhomnoname.ecotouradmin.api.TokenStore;
import java.util.HashMap;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    private EditText edtEmail, edtMatKhau;
    private Button btnLogin;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        // Tu dong chuyen vao MainActivity neu da co phien dang nhap
        if (!TokenStore.layToken(this).isEmpty()) {
            startActivity(new Intent(this, MainActivity.class));
            finish();
            return;
        }

        edtEmail = findViewById(R.id.edtEmail);
        edtMatKhau = findViewById(R.id.edtMatKhau);
        btnLogin = findViewById(R.id.btnLogin);
        progressBar = findViewById(R.id.progressBar);

        btnLogin.setOnClickListener(v -> thucHienDangNhap());
    }

    private void thucHienDangNhap() {
        String email = edtEmail.getText().toString().trim();
        String matKhau = edtMatKhau.getText().toString().trim();

        if (email.isEmpty()) {
            edtEmail.setError("Vui lòng nhập email");
            return;
        }
        if (matKhau.isEmpty()) {
            edtMatKhau.setError("Vui lòng nhập mật khẩu");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        btnLogin.setEnabled(false);

        Map<String, String> body = new HashMap<>();
        body.put("email", email);
        body.put("matKhau", matKhau);

        ApiClient.get(this).dangNhap(body).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressBar.setVisibility(View.GONE);
                btnLogin.setEnabled(true);

                if (response.isSuccessful() && response.body() != null) {
                    Map<String, Object> resData = response.body();
                    String token = (String) resData.get("token");
                    Map<String, Object> user = (Map<String, Object>) resData.get("nguoiDung");
                    String vaiTro = user != null ? (String) user.get("vaiTro") : "KHACH";
                    String hoTen = user != null ? (String) user.get("hoTen") : "";

                    if (!"QUAN_TRI".equals(vaiTro) && !"DIEU_HANH".equals(vaiTro)) {
                        Toast.makeText(LoginActivity.this, "Tài khoản không có quyền truy cập Admin", Toast.LENGTH_LONG).show();
                        return;
                    }

                    TokenStore.luuPhien(LoginActivity.this, token, vaiTro, hoTen);
                    Log.i(TAG, "Dang nhap thanh cong: " + email + " - Vai tro: " + vaiTro);

                    startActivity(new Intent(LoginActivity.this, MainActivity.class));
                    finish();
                } else {
                    Toast.makeText(LoginActivity.this, "Sai email hoặc mật khẩu", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressBar.setVisibility(View.GONE);
                btnLogin.setEnabled(true);
                Log.e(TAG, "Loi ket noi dang nhap", t);
                Toast.makeText(LoginActivity.this, "Không kết nối được máy chủ (Render đang thức dậy...)", Toast.LENGTH_LONG).show();
            }
        });
    }
}
