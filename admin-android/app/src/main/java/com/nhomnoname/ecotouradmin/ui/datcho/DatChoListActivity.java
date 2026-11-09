package com.nhomnoname.ecotouradmin.ui.datcho;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.snackbar.Snackbar;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import com.nhomnoname.ecotouradmin.api.TokenStore;
import com.nhomnoname.ecotouradmin.models.DatChoItem;
import com.nhomnoname.ecotouradmin.ui.auth.LoginActivity;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class DatChoListActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";
    private RecyclerView rvDatCho;
    private ProgressBar progressDatCho;
    private TextView tvTrongDatCho;
    private View rootView;
    private final List<DatChoItem> danhSach = new ArrayList<>();
    private DatChoAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dat_cho_list);

        rootView = findViewById(R.id.rootDatChoList);
        rvDatCho = findViewById(R.id.rvDatCho);
        progressDatCho = findViewById(R.id.progressDatCho);
        tvTrongDatCho = findViewById(R.id.tvTrongDatCho);

        rvDatCho.setLayoutManager(new LinearLayoutManager(this));
        adapter = new DatChoAdapter(danhSach, this::hienHopThoaiXacNhanHuy);
        rvDatCho.setAdapter(adapter);

        taiDanhSachDatCho();
    }

    private void taiDanhSachDatCho() {
        progressDatCho.setVisibility(View.VISIBLE);
        tvTrongDatCho.setVisibility(View.GONE);

        ApiClient.get(this).layDanhSachDatCho(null, null).enqueue(new Callback<List<DatChoItem>>() {
            @Override
            public void onResponse(Call<List<DatChoItem>> call, Response<List<DatChoItem>> res) {
                progressDatCho.setVisibility(View.GONE);
                if (res.isSuccessful() && res.body() != null) {
                    danhSach.clear();
                    danhSach.addAll(res.body());
                    adapter.notifyDataSetChanged();
                    tvTrongDatCho.setVisibility(danhSach.isEmpty() ? View.VISIBLE : View.GONE);
                    Log.d(TAG, "Tai danh sach dat cho thanh cong: " + danhSach.size());
                } else if (res.code() == 401) {
                    TokenStore.xoaPhien(DatChoListActivity.this);
                    startActivity(new Intent(DatChoListActivity.this, LoginActivity.class));
                    finish();
                } else {
                    Toast.makeText(DatChoListActivity.this, "Lỗi máy chủ: " + res.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<List<DatChoItem>> call, Throwable t) {
                progressDatCho.setVisibility(View.GONE);
                Log.e(TAG, "Loi mang khi tai danh sach dat cho", t);
                Toast.makeText(DatChoListActivity.this, "Không kết nối được máy chủ", Toast.LENGTH_SHORT).show();
            }
        });
    }

    // Yeu cau C.1.6: Hop thoai xac nhan truoc moi thao tac xoa/huy; Toast/Snackbar phan hoi ket qua
    private void hienHopThoaiXacNhanHuy(DatChoItem item) {
        new AlertDialog.Builder(this)
                .setTitle("Xác nhận hủy đặt chỗ")
                .setMessage("Bạn có chắc chắn muốn hủy vé " + item.maVe + "? Hệ thống sẽ tự tính tiền hoàn theo chính sách.")
                .setPositiveButton("Xác nhận hủy", (dialog, which) -> goiApiHuyDon(item.id))
                .setNegativeButton("Đóng", null)
                .show();
    }

    private void goiApiHuyDon(int datChoId) {
        progressDatCho.setVisibility(View.VISIBLE);
        ApiClient.get(this).huyDatCho(datChoId).enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> res) {
                progressDatCho.setVisibility(View.GONE);
                if (res.isSuccessful()) {
                    Snackbar.make(rootView, "Đã hủy đơn và cập nhật tiền hoàn thành công!", Snackbar.LENGTH_LONG).show();
                    taiDanhSachDatCho();
                } else {
                    Toast.makeText(DatChoListActivity.this, "Không thể hủy đơn: " + res.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressDatCho.setVisibility(View.GONE);
                Toast.makeText(DatChoListActivity.this, "Lỗi kết nối mạng khi hủy đơn", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
