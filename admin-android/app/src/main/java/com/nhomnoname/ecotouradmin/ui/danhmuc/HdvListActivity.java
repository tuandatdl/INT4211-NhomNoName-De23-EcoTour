package com.nhomnoname.ecotouradmin.ui.danhmuc;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.gson.Gson;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import com.nhomnoname.ecotouradmin.models.HuongDanVien;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class HdvListActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";

    private ProgressBar progressHdvList;
    private LinearLayout layoutErrorHdv;
    private TextView tvErrorHdvMsg;
    private RecyclerView rvHdvList;
    private ImageView btnRefreshHdv;

    private final List<HuongDanVien> danhSachHdv = new ArrayList<>();
    private HdvAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hdv_list);

        Log.d(TAG, "Khoi dong HdvListActivity - NhomNoName");

        progressHdvList = findViewById(R.id.progressHdvList);
        layoutErrorHdv = findViewById(R.id.layoutErrorHdv);
        tvErrorHdvMsg = findViewById(R.id.tvErrorHdvMsg);
        rvHdvList = findViewById(R.id.rvHdvList);
        btnRefreshHdv = findViewById(R.id.btnRefreshHdv);

        rvHdvList.setLayoutManager(new LinearLayoutManager(this));
        adapter = new HdvAdapter(danhSachHdv);
        rvHdvList.setAdapter(adapter);

        findViewById(R.id.btnRetryHdv).setOnClickListener(v -> taiDanhSachHdv());
        btnRefreshHdv.setOnClickListener(v -> taiDanhSachHdv());

        taiDanhSachHdv();
    }

    private void taiDanhSachHdv() {
        progressHdvList.setVisibility(View.VISIBLE);
        layoutErrorHdv.setVisibility(View.GONE);

        ApiClient.get(this).layDanhSachHdv().enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> response) {
                progressHdvList.setVisibility(View.GONE);

                if (response.isSuccessful() && response.body() != null) {
                    Object dataObj = response.body().get("duLieu");
                    if (dataObj != null) {
                        Gson gson = new Gson();
                        String json = gson.toJson(dataObj);
                        HuongDanVien[] hdvArray = gson.fromJson(json, HuongDanVien[].class);

                        danhSachHdv.clear();
                        if (hdvArray != null && hdvArray.length > 0) {
                            for (HuongDanVien h : hdvArray) {
                                danhSachHdv.add(h);
                            }
                            adapter.notifyDataSetChanged();
                            rvHdvList.setVisibility(View.VISIBLE);
                            layoutErrorHdv.setVisibility(View.GONE);
                            Log.d(TAG, "Tai thanh cong " + danhSachHdv.size() + " HDV");
                        } else {
                            rvHdvList.setVisibility(View.GONE);
                            layoutErrorHdv.setVisibility(View.VISIBLE);
                            tvErrorHdvMsg.setText("Chưa có hướng dẫn viên nào trong hệ thống");
                        }
                        return;
                    }
                }

                rvHdvList.setVisibility(View.GONE);
                layoutErrorHdv.setVisibility(View.VISIBLE);
                tvErrorHdvMsg.setText("Không tải được dữ liệu HDV (Mã: " + response.code() + ")");
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressHdvList.setVisibility(View.GONE);
                rvHdvList.setVisibility(View.GONE);
                layoutErrorHdv.setVisibility(View.VISIBLE);
                tvErrorHdvMsg.setText("Lỗi kết nối máy chủ: " + t.getMessage());
                Log.e(TAG, "Loi tai danh sach HDV", t);
            }
        });
    }
}

