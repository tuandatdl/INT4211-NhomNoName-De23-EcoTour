package com.nhomnoname.ecotouradmin.ui.tour;

import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.textfield.TextInputEditText;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import com.nhomnoname.ecotouradmin.models.Tour;
import java.util.HashMap;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class TourFormActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    // Khóa lưu trạng thái chống mất dữ liệu khi xoay màn hình (tiêu chí bắt buộc)
    private static final String KEY_TEN = "STATE_TEN_TOUR";
    private static final String KEY_SO_NGAY = "STATE_SO_NGAY";
    private static final String KEY_GIA_NL = "STATE_GIA_NL";
    private static final String KEY_GIA_TE = "STATE_GIA_TE";
    private static final String KEY_ANH_URL = "STATE_ANH_URL";
    private static final String KEY_MO_TA = "STATE_MO_TA";

    private TextView tvFormTitle;
    private TextInputEditText edtTenTour, edtSoNgay, edtGiaNguoiLon, edtGiaTreEm, edtAnhUrl, edtMoTa;
    private ProgressBar progressSaveTour;
    private Button btnSaveTour;

    private Tour editingTour = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_tour_form);

        tvFormTitle = findViewById(R.id.tvFormTitle);
        edtTenTour = findViewById(R.id.edtTenTour);
        edtSoNgay = findViewById(R.id.edtSoNgay);
        edtGiaNguoiLon = findViewById(R.id.edtGiaNguoiLon);
        edtGiaTreEm = findViewById(R.id.edtGiaTreEm);
        edtAnhUrl = findViewById(R.id.edtAnhUrl);
        edtMoTa = findViewById(R.id.edtMoTa);
        progressSaveTour = findViewById(R.id.progressSaveTour);
        btnSaveTour = findViewById(R.id.btnSaveTour);

        // Kiểm tra xem là chế độ Thêm mới hay Sửa
        if (getIntent().hasExtra("EXTRA_TOUR")) {
            editingTour = (Tour) getIntent().getSerializableExtra("EXTRA_TOUR");
            if (editingTour != null) {
                tvFormTitle.setText("Chỉnh Sửa Tour #" + editingTour.id + " - NhomNoName");
                edtTenTour.setText(editingTour.ten);
                edtSoNgay.setText(String.valueOf(editingTour.soNgay));
                edtGiaNguoiLon.setText(String.valueOf((long) editingTour.giaNguoiLon));
                edtGiaTreEm.setText(String.valueOf((long) editingTour.giaTreEm));
                edtAnhUrl.setText(editingTour.anhUrl);
                edtMoTa.setText(editingTour.moTa);
            }
        }

        // Khôi phục dữ liệu khi xoay màn hình (nếu có)
        if (savedInstanceState != null) {
            Log.d(TAG, "Khoi phuc du lieu da nhap khi xoay man hinh trong TourFormActivity");
            edtTenTour.setText(savedInstanceState.getString(KEY_TEN, ""));
            edtSoNgay.setText(savedInstanceState.getString(KEY_SO_NGAY, ""));
            edtGiaNguoiLon.setText(savedInstanceState.getString(KEY_GIA_NL, ""));
            edtGiaTreEm.setText(savedInstanceState.getString(KEY_GIA_TE, ""));
            edtAnhUrl.setText(savedInstanceState.getString(KEY_ANH_URL, ""));
            edtMoTa.setText(savedInstanceState.getString(KEY_MO_TA, ""));
        }

        btnSaveTour.setOnClickListener(v -> xuLyLuuTour());
    }

    /**
     * Tiêu chuẩn chấm điểm bắt buộc: Giữ dữ liệu khi xoay màn hình điện thoại
     */
    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        Log.d(TAG, "Luu trang thai nhap lieu truoc khi xoay man hinh");
        outState.putString(KEY_TEN, edtTenTour.getText() != null ? edtTenTour.getText().toString() : "");
        outState.putString(KEY_SO_NGAY, edtSoNgay.getText() != null ? edtSoNgay.getText().toString() : "");
        outState.putString(KEY_GIA_NL, edtGiaNguoiLon.getText() != null ? edtGiaNguoiLon.getText().toString() : "");
        outState.putString(KEY_GIA_TE, edtGiaTreEm.getText() != null ? edtGiaTreEm.getText().toString() : "");
        outState.putString(KEY_ANH_URL, edtAnhUrl.getText() != null ? edtAnhUrl.getText().toString() : "");
        outState.putString(KEY_MO_TA, edtMoTa.getText() != null ? edtMoTa.getText().toString() : "");
    }

    private void xuLyLuuTour() {
        String ten = edtTenTour.getText() != null ? edtTenTour.getText().toString().trim() : "";
        String soNgayStr = edtSoNgay.getText() != null ? edtSoNgay.getText().toString().trim() : "";
        String giaNLStr = edtGiaNguoiLon.getText() != null ? edtGiaNguoiLon.getText().toString().trim() : "";
        String giaTEStr = edtGiaTreEm.getText() != null ? edtGiaTreEm.getText().toString().trim() : "";
        String anhUrl = edtAnhUrl.getText() != null ? edtAnhUrl.getText().toString().trim() : "";
        String moTa = edtMoTa.getText() != null ? edtMoTa.getText().toString().trim() : "";

        // Kiểm tra hợp lệ dữ liệu (validation)
        if (TextUtils.isEmpty(ten)) {
            edtTenTour.setError("Vui lòng nhập tên tour du lịch");
            edtTenTour.requestFocus();
            return;
        }

        if (TextUtils.isEmpty(soNgayStr)) {
            edtSoNgay.setError("Vui lòng nhập số ngày diễn ra tour");
            edtSoNgay.requestFocus();
            return;
        }

        int soNgay;
        try {
            soNgay = Integer.parseInt(soNgayStr);
            if (soNgay <= 0) {
                edtSoNgay.setError("Số ngày phải lớn hơn 0");
                return;
            }
        } catch (NumberFormatException e) {
            edtSoNgay.setError("Số ngày không hợp lệ");
            return;
        }

        if (TextUtils.isEmpty(giaNLStr)) {
            edtGiaNguoiLon.setError("Vui lòng nhập giá người lớn");
            edtGiaNguoiLon.requestFocus();
            return;
        }

        double giaNL = Double.parseDouble(giaNLStr);
        double giaTE = TextUtils.isEmpty(giaTEStr) ? 0 : Double.parseDouble(giaTEStr);

        Map<String, Object> body = new HashMap<>();
        body.put("ten", ten);
        body.put("so_ngay", soNgay);
        body.put("gia_nguoi_lon", giaNL);
        body.put("gia_tre_em", giaTE);
        body.put("anh_url", anhUrl);
        body.put("mo_ta", moTa);

        progressSaveTour.setVisibility(View.VISIBLE);
        btnSaveTour.setEnabled(false);

        Callback<Map<String, Object>> callback = new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressSaveTour.setVisibility(View.GONE);
                btnSaveTour.setEnabled(true);

                if (response.isSuccessful()) {
                    Toast.makeText(TourFormActivity.this, "Lưu thông tin tour thành công!", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    Toast.makeText(TourFormActivity.this, "Lưu thất bại. Mã lỗi: " + response.code(), Toast.LENGTH_LONG).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressSaveTour.setVisibility(View.GONE);
                btnSaveTour.setEnabled(true);
                Toast.makeText(TourFormActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_LONG).show();
            }
        };

        if (editingTour == null) {
            ApiClient.get(this).themTour(body).enqueue(callback);
        } else {
            ApiClient.get(this).capNhatTour(editingTour.id, body).enqueue(callback);
        }
    }
}

