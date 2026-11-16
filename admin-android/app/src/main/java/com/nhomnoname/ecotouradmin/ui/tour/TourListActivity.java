package com.nhomnoname.ecotouradmin.ui.tour;

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
import com.nhomnoname.ecotouradmin.models.Tour;
import com.nhomnoname.ecotouradmin.ui.suat.SuatListActivity;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class TourListActivity extends AppCompatActivity implements TourAdapter.OnTourActionListener {
    public static final String TAG = "NhomNoName_Log";

    private View rootTourList;
    private ProgressBar progressTourList;
    private LinearLayout layoutErrorTour;
    private TextView tvErrorTourMsg;
    private RecyclerView rvTourList;
    private FloatingActionButton fabAddTour;
    private ImageView btnRefreshTour;

    private final List<Tour> danhSachTour = new ArrayList<>();
    private TourAdapter tourAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_tour_list);

        Log.d(TAG, "Khoi dong TourListActivity - NhomNoName");

        rootTourList = findViewById(R.id.rootTourList);
        progressTourList = findViewById(R.id.progressTourList);
        layoutErrorTour = findViewById(R.id.layoutErrorTour);
        tvErrorTourMsg = findViewById(R.id.tvErrorTourMsg);
        rvTourList = findViewById(R.id.rvTourList);
        fabAddTour = findViewById(R.id.fabAddTour);
        btnRefreshTour = findViewById(R.id.btnRefreshTour);

        rvTourList.setLayoutManager(new LinearLayoutManager(this));
        tourAdapter = new TourAdapter(danhSachTour, this);
        rvTourList.setAdapter(tourAdapter);

        findViewById(R.id.btnRetryTour).setOnClickListener(v -> taiDanhSachTour());
        btnRefreshTour.setOnClickListener(v -> taiDanhSachTour());

        fabAddTour.setOnClickListener(v -> {
            Intent intent = new Intent(TourListActivity.this, TourFormActivity.class);
            startActivity(intent);
        });

        taiDanhSachTour();
    }

    @Override
    protected void onResume() {
        super.onResume();
        taiDanhSachTour();
    }

    /**
     * Xử lý 3 trạng thái:
     * 1. Đang tải (ProgressBar VISIBLE)
     * 2. Thành công (RecyclerView VISIBLE)
     * 3. Lỗi / Rỗng (layoutErrorTour VISIBLE kèm nút Thử lại)
     */
    private void taiDanhSachTour() {
        progressTourList.setVisibility(View.VISIBLE);
        layoutErrorTour.setVisibility(View.GONE);

        ApiClient.get(this).layDanhSachTourQuanLy(null, null).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressTourList.setVisibility(View.GONE);

                if (response.isSuccessful() && response.body() != null) {
                    Map<String, Object> body = response.body();
                    Object dataObj = body.get("duLieu");
                    if (dataObj != null) {
                        Gson gson = new Gson();
                        String jsonString = gson.toJson(dataObj);
                        Tour[] tourArray = gson.fromJson(jsonString, Tour[].class);

                        danhSachTour.clear();
                        if (tourArray != null && tourArray.length > 0) {
                            for (Tour t : tourArray) {
                                danhSachTour.add(t);
                            }
                            tourAdapter.notifyDataSetChanged();
                            rvTourList.setVisibility(View.VISIBLE);
                            layoutErrorTour.setVisibility(View.GONE);
                            Log.d(TAG, "Tai thanh cong " + danhSachTour.size() + " tour");
                        } else {
                            rvTourList.setVisibility(View.GONE);
                            layoutErrorTour.setVisibility(View.VISIBLE);
                            tvErrorTourMsg.setText("Chưa có tour nào trong hệ thống");
                        }
                        return;
                    }
                }

                rvTourList.setVisibility(View.GONE);
                layoutErrorTour.setVisibility(View.VISIBLE);
                tvErrorTourMsg.setText("Máy chủ phản hồi mã lỗi: " + response.code());
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressTourList.setVisibility(View.GONE);
                rvTourList.setVisibility(View.GONE);
                layoutErrorTour.setVisibility(View.VISIBLE);
                tvErrorTourMsg.setText("Lỗi kết nối máy chủ: " + t.getMessage());
                Log.e(TAG, "Loi tai danh sach tour", t);
            }
        });
    }

    @Override
    public void onViewSuat(Tour tour) {
        Intent intent = new Intent(this, SuatListActivity.class);
        intent.putExtra("EXTRA_TOUR_ID", tour.id);
        intent.putExtra("EXTRA_TOUR_TEN", tour.ten);
        startActivity(intent);
    }

    @Override
    public void onEditTour(Tour tour) {
        Intent intent = new Intent(this, TourFormActivity.class);
        intent.putExtra("EXTRA_TOUR", tour);
        startActivity(intent);
    }

    /**
     * Tiêu chuẩn chấm điểm bắt buộc: Thao tác xóa phải bật AlertDialog xác nhận
     */
    @Override
    public void onDeleteTour(Tour tour) {
        new AlertDialog.Builder(this)
            .setTitle("Xác nhận xóa Tour")
            .setMessage("Bạn có chắc chắn muốn xóa tour \"" + tour.ten + "\"?\n(Nếu tour có suất đang mở bán, hệ thống sẽ chuyển trạng thái sang TẠM NGƯNG)")
            .setIcon(android.R.drawable.ic_dialog_alert)
            .setPositiveButton("Xóa / Tạm Ngưng", (dialog, which) -> thucHienXoaTour(tour))
            .setNegativeButton("Hủy", null)
            .show();
    }

    private void thucHienXoaTour(Tour tour) {
        progressTourList.setVisibility(View.VISIBLE);

        ApiClient.get(this).xoaTour(tour.id).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressTourList.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    String thongBao = "Đã cập nhật trạng thái xóa tour thành công";
                    if (response.body() != null && response.body().get("thongBao") != null) {
                        thongBao = response.body().get("thongBao").toString();
                    }
                    Snackbar.make(rootTourList, thongBao, Snackbar.LENGTH_LONG).show();
                    taiDanhSachTour();
                } else {
                    Toast.makeText(TourListActivity.this, "Không thể xóa tour. Mã lỗi: " + response.code(), Toast.LENGTH_LONG).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressTourList.setVisibility(View.GONE);
                Toast.makeText(TourListActivity.this, "Lỗi kết nối khi xóa: " + t.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }
}

