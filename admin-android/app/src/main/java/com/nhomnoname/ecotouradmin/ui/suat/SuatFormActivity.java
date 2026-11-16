package com.nhomnoname.ecotouradmin.ui.suat;

import android.app.DatePickerDialog;
import android.app.TimePickerDialog;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.textfield.TextInputEditText;
import com.google.gson.Gson;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import com.nhomnoname.ecotouradmin.models.HuongDanVien;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SuatFormActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    // Khóa lưu trạng thái chống mất dữ liệu khi xoay màn hình (tiêu chuẩn bắt buộc)
    private static final String KEY_NGAY = "STATE_SUAT_NGAY";
    private static final String KEY_GIO = "STATE_SUAT_GIO";
    private static final String KEY_DIEM = "STATE_SUAT_DIEM";
    private static final String KEY_PHUONG_TIEN = "STATE_SUAT_PHUONG_TIEN";
    private static final String KEY_SO_CHO = "STATE_SUAT_SO_CHO";
    private static final String KEY_HDV_INDEX = "STATE_SUAT_HDV_INDEX";

    private TextView tvFormSuatTitle;
    private TextInputEditText edtNgayDi, edtGioTapTrung, edtDiemTapTrung, edtPhuongTien, edtSoCho;
    private Spinner spnHdv;
    private ProgressBar progressSaveSuat;
    private Button btnSaveSuat;

    private int tourId = 1;
    private final List<HuongDanVien> danhSachHdv = new ArrayList<>();
    private final List<String> tenHdvList = new ArrayList<>();
    private ArrayAdapter<String> hdvSpinnerAdapter;
    private int restoredHdvIndex = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_suat_form);

        tourId = getIntent().getIntExtra("EXTRA_TOUR_ID", 1);
        String tenTour = getIntent().getStringExtra("EXTRA_TOUR_TEN");

        tvFormSuatTitle = findViewById(R.id.tvFormSuatTitle);
        if (tenTour != null) {
            tvFormSuatTitle.setText("Thêm Suất Cho: " + tenTour);
        }

        edtNgayDi = findViewById(R.id.edtNgayDi);
        edtGioTapTrung = findViewById(R.id.edtGioTapTrung);
        edtDiemTapTrung = findViewById(R.id.edtDiemTapTrung);
        edtPhuongTien = findViewById(R.id.edtPhuongTien);
        edtSoCho = findViewById(R.id.edtSoCho);
        spnHdv = findViewById(R.id.spnHdv);
        progressSaveSuat = findViewById(R.id.progressSaveSuat);
        btnSaveSuat = findViewById(R.id.btnSaveSuat);

        // Khởi tạo Adapter Spinner HDV
        tenHdvList.add("-- Không chọn HDV --");
        hdvSpinnerAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, tenHdvList);
        spnHdv.setAdapter(hdvSpinnerAdapter);

        // DatePicker dialog
        edtNgayDi.setOnClickListener(v -> hienDatePicker());

        // TimePicker dialog
        edtGioTapTrung.setOnClickListener(v -> hienTimePicker());

        // Khôi phục dữ liệu khi xoay màn hình
        if (savedInstanceState != null) {
            Log.d(TAG, "Khoi phuc du lieu da nhap trong SuatFormActivity khi xoay man hinh");
            edtNgayDi.setText(savedInstanceState.getString(KEY_NGAY, ""));
            edtGioTapTrung.setText(savedInstanceState.getString(KEY_GIO, ""));
            edtDiemTapTrung.setText(savedInstanceState.getString(KEY_DIEM, ""));
            edtPhuongTien.setText(savedInstanceState.getString(KEY_PHUONG_TIEN, ""));
            edtSoCho.setText(savedInstanceState.getString(KEY_SO_CHO, "30"));
            restoredHdvIndex = savedInstanceState.getInt(KEY_HDV_INDEX, 0);
        }

        btnSaveSuat.setOnClickListener(v -> xuLyLuuSuat());

        taiDanhSachHdv();
    }

    /**
     * Tiêu chuẩn bắt buộc: Giữ dữ liệu khi xoay màn hình
     */
    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        Log.d(TAG, "Luu du lieu form suat truoc khi xoay man hinh");
        outState.putString(KEY_NGAY, edtNgayDi.getText() != null ? edtNgayDi.getText().toString() : "");
        outState.putString(KEY_GIO, edtGioTapTrung.getText() != null ? edtGioTapTrung.getText().toString() : "");
        outState.putString(KEY_DIEM, edtDiemTapTrung.getText() != null ? edtDiemTapTrung.getText().toString() : "");
        outState.putString(KEY_PHUONG_TIEN, edtPhuongTien.getText() != null ? edtPhuongTien.getText().toString() : "");
        outState.putString(KEY_SO_CHO, edtSoCho.getText() != null ? edtSoCho.getText().toString() : "");
        outState.putInt(KEY_HDV_INDEX, spnHdv.getSelectedItemPosition());
    }

    private void hienDatePicker() {
        Calendar cal = Calendar.getInstance();
        DatePickerDialog dialog = new DatePickerDialog(this, (view, year, month, dayOfMonth) -> {
            String ngayChon = String.format(Locale.getDefault(), "%04d-%02d-%02d", year, month + 1, dayOfMonth);
            edtNgayDi.setText(ngayChon);
        }, cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), cal.get(Calendar.DAY_OF_MONTH));
        dialog.getDatePicker().setMinDate(System.currentTimeMillis());
        dialog.show();
    }

    private void hienTimePicker() {
        Calendar cal = Calendar.getInstance();
        new TimePickerDialog(this, (view, hourOfDay, minute) -> {
            String gioChon = String.format(Locale.getDefault(), "%02d:%02d", hourOfDay, minute);
            edtGioTapTrung.setText(gioChon);
        }, cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE), true).show();
    }

    private void taiDanhSachHdv() {
        ApiClient.get(this).layDanhSachHdv().enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    Object dataObj = response.body().get("duLieu");
                    if (dataObj != null) {
                        Gson gson = new Gson();
                        String json = gson.toJson(dataObj);
                        HuongDanVien[] hdvs = gson.fromJson(json, HuongDanVien[].class);

                        danhSachHdv.clear();
                        tenHdvList.clear();
                        tenHdvList.add("-- Không chọn HDV --");

                        if (hdvs != null) {
                            for (HuongDanVien h : hdvs) {
                                danhSachHdv.add(h);
                                tenHdvList.add(h.hoTen + " (" + h.ngonNgu + ")");
                            }
                        }
                        hdvSpinnerAdapter.notifyDataSetChanged();

                        if (restoredHdvIndex < tenHdvList.size()) {
                            spnHdv.setSelection(restoredHdvIndex);
                        }
                    }
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                Log.e(TAG, "Loi tai danh sach HDV cho Spinner", t);
            }
        });
    }

    private void xuLyLuuSuat() {
        String ngayDi = edtNgayDi.getText() != null ? edtNgayDi.getText().toString().trim() : "";
        String gioTapTrung = edtGioTapTrung.getText() != null ? edtGioTapTrung.getText().toString().trim() : "";
        String diemTapTrung = edtDiemTapTrung.getText() != null ? edtDiemTapTrung.getText().toString().trim() : "";
        String phuongTien = edtPhuongTien.getText() != null ? edtPhuongTien.getText().toString().trim() : "";
        String soChoStr = edtSoCho.getText() != null ? edtSoCho.getText().toString().trim() : "";

        if (TextUtils.isEmpty(ngayDi)) {
            edtNgayDi.setError("Vui lòng chọn ngày khởi hành");
            edtNgayDi.requestFocus();
            return;
        }

        if (TextUtils.isEmpty(gioTapTrung)) {
            edtGioTapTrung.setError("Vui lòng chọn giờ tập trung");
            edtGioTapTrung.requestFocus();
            return;
        }

        if (TextUtils.isEmpty(diemTapTrung)) {
            edtDiemTapTrung.setError("Vui lòng nhập điểm tập trung");
            edtDiemTapTrung.requestFocus();
            return;
        }

        int soCho;
        try {
            soCho = Integer.parseInt(soChoStr);
            if (soCho <= 0) {
                edtSoCho.setError("Số chỗ phải lớn hơn 0");
                return;
            }
        } catch (NumberFormatException e) {
            edtSoCho.setError("Số chỗ không hợp lệ");
            return;
        }

        Integer hdvId = null;
        int hdvPosition = spnHdv.getSelectedItemPosition();
        if (hdvPosition > 0 && (hdvPosition - 1) < danhSachHdv.size()) {
            hdvId = danhSachHdv.get(hdvPosition - 1).id;
        }

        Map<String, Object> body = new HashMap<>();
        body.put("ngay_di", ngayDi);
        body.put("gio_tap_trung", gioTapTrung);
        body.put("diem_tap_trung", diemTapTrung);
        body.put("phuong_tien", phuongTien);
        body.put("so_cho", soCho);
        if (hdvId != null) {
            body.put("hdv_id", hdvId);
        }

        progressSaveSuat.setVisibility(View.VISIBLE);
        btnSaveSuat.setEnabled(false);

        ApiClient.get(this).themSuatChoTour(tourId, body).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressSaveSuat.setVisibility(View.GONE);
                btnSaveSuat.setEnabled(true);

                if (response.isSuccessful()) {
                    Toast.makeText(SuatFormActivity.this, "Tạo suất khởi hành thành công!", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    String loiMsg = "Lỗi tạo suất. Mã: " + response.code();
                    if (response.code() == 409) {
                        loiMsg = "HDV này đã bị trùng lịch dẫn tour trong ngày đã chọn!";
                    }
                    Toast.makeText(SuatFormActivity.this, loiMsg, Toast.LENGTH_LONG).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressSaveSuat.setVisibility(View.GONE);
                btnSaveSuat.setEnabled(true);
                Toast.makeText(SuatFormActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }
}

