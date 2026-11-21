package com.nhomnoname.ecotouradmin.ui.suat;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.snackbar.Snackbar;
import com.google.gson.Gson;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import com.nhomnoname.ecotouradmin.models.SuatKhoiHanh;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SuatListActivity extends AppCompatActivity implements SuatAdapter.OnSuatActionListener {
    public static final String TAG = "NhomNoName_Log";

    private View rootSuatList;
    private TextView tvHeaderSuat;
    private ProgressBar progressSuatList;
    private LinearLayout layoutErrorSuat;
    private TextView tvErrorSuatMsg;
    private RecyclerView rvSuatList;
    private FloatingActionButton fabAddSuat;
    private ImageView btnRefreshSuat;

    private int tourId = 1;
    private String tenTour = "";
    private final List<SuatKhoiHanh> danhSachSuat = new ArrayList<>();
    private SuatAdapter suatAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_suat_list);

        tourId = getIntent().getIntExtra("EXTRA_TOUR_ID", 1);
        tenTour = getIntent().getStringExtra("EXTRA_TOUR_TEN");
        if (tenTour == null) tenTour = "Tour #" + tourId;

        Log.d(TAG, "Khoi dong SuatListActivity cho Tour ID=" + tourId + " - NhomNoName");

        rootSuatList = findViewById(R.id.rootSuatList);
        tvHeaderSuat = findViewById(R.id.tvHeaderSuat);
        progressSuatList = findViewById(R.id.progressSuatList);
        layoutErrorSuat = findViewById(R.id.layoutErrorSuat);
        tvErrorSuatMsg = findViewById(R.id.tvErrorSuatMsg);
        rvSuatList = findViewById(R.id.rvSuatList);
        fabAddSuat = findViewById(R.id.fabAddSuat);
        btnRefreshSuat = findViewById(R.id.btnRefreshSuat);

        tvHeaderSuat.setText("Suất: " + tenTour);

        rvSuatList.setLayoutManager(new LinearLayoutManager(this));
        suatAdapter = new SuatAdapter(danhSachSuat, this);
        rvSuatList.setAdapter(suatAdapter);

        findViewById(R.id.btnRetrySuat).setOnClickListener(v -> taiDanhSachSuat());
        btnRefreshSuat.setOnClickListener(v -> taiDanhSachSuat());

        fabAddSuat.setOnClickListener(v -> {
            Intent intent = new Intent(SuatListActivity.this, SuatFormActivity.class);
            intent.putExtra("EXTRA_TOUR_ID", tourId);
            intent.putExtra("EXTRA_TOUR_TEN", tenTour);
            startActivity(intent);
        });

        taiDanhSachSuat();
    }

    @Override
    protected void onResume() {
        super.onResume();
        taiDanhSachSuat();
    }

    /**
     * Xử lý 3 trạng thái:
     * 1. Đang tải (ProgressBar)
     * 2. Thành công (RecyclerView 2)
     * 3. Lỗi / Danh sách rỗng
     */
    private void taiDanhSachSuat() {
        progressSuatList.setVisibility(View.VISIBLE);
        layoutErrorSuat.setVisibility(View.GONE);

        ApiClient.get(this).layDanhSachSuatCuaTour(tourId).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressSuatList.setVisibility(View.GONE);

                if (response.isSuccessful() && response.body() != null) {
                    Object dataObj = response.body().get("duLieu");
                    if (dataObj != null) {
                        Gson gson = new Gson();
                        String json = gson.toJson(dataObj);
                        SuatKhoiHanh[] suatArray = gson.fromJson(json, SuatKhoiHanh[].class);

                        danhSachSuat.clear();
                        if (suatArray != null && suatArray.length > 0) {
                            for (SuatKhoiHanh s : suatArray) {
                                danhSachSuat.add(s);
                            }
                            suatAdapter.notifyDataSetChanged();
                            rvSuatList.setVisibility(View.VISIBLE);
                            layoutErrorSuat.setVisibility(View.GONE);
                            Log.d(TAG, "Tai thanh cong " + danhSachSuat.size() + " suat khoi hanh");
                        } else {
                            rvSuatList.setVisibility(View.GONE);
                            layoutErrorSuat.setVisibility(View.VISIBLE);
                            tvErrorSuatMsg.setText("Chưa có suất khởi hành nào cho tour này");
                        }
                        return;
                    }
                }

                rvSuatList.setVisibility(View.GONE);
                layoutErrorSuat.setVisibility(View.VISIBLE);
                tvErrorSuatMsg.setText("Không tải được danh sách suất (Mã: " + response.code() + ")");
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressSuatList.setVisibility(View.GONE);
                rvSuatList.setVisibility(View.GONE);
                layoutErrorSuat.setVisibility(View.VISIBLE);
                tvErrorSuatMsg.setText("Lỗi kết nối máy chủ: " + t.getMessage());
                Log.e(TAG, "Loi tai suat khoi hanh", t);
            }
        });
    }

    /**
     * Tiêu chuẩn chấm điểm bắt buộc: Thao tác xóa phải bật AlertDialog xác nhận
     */
    @Override
    public void onDeleteSuat(SuatKhoiHanh suat) {
        new AlertDialog.Builder(this)
            .setTitle("Xác nhận hủy / xóa Suất")
            .setMessage("Bạn có chắc chắn muốn hủy hoặc xóa suất ngày " + suat.ngayDi + " lúc " + suat.gioTapTrung + "?\n(Nếu suất đã có đơn đặt chỗ, hệ thống sẽ chuyển sang trạng thái ĐÃ HỦY)")
            .setIcon(android.R.drawable.ic_dialog_alert)
            .setPositiveButton("Xác Nhận", (dialog, which) -> thucHienXoaSuat(suat))
            .setNegativeButton("Quay Lại", null)
            .show();
    }

    private void thucHienXoaSuat(SuatKhoiHanh suat) {
        progressSuatList.setVisibility(View.VISIBLE);

        ApiClient.get(this).xoaSuat(suat.id).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressSuatList.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    String thongBao = "Đã cập nhật trạng thái suất thành công";
                    if (response.body() != null && response.body().get("thongBao") != null) {
                        thongBao = response.body().get("thongBao").toString();
                    }
                    Snackbar.make(rootSuatList, thongBao, Snackbar.LENGTH_LONG).show();
                    taiDanhSachSuat();
                } else {
                    Toast.makeText(SuatListActivity.this, "Không thể xóa suất. Mã: " + response.code(), Toast.LENGTH_LONG).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressSuatList.setVisibility(View.GONE);
                Toast.makeText(SuatListActivity.this, "Lỗi kết nối khi xóa: " + t.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }
}

