package com.nhomnoname.ecotouradmin.ui.baocao;

import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.api.ApiClient;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class BaoCaoChartActivity extends AppCompatActivity {
    public static final String TAG = "NhomNoName_Log";
    private BarChart barChart;
    private ProgressBar progressBaoCao;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bao_cao_chart);

        barChart = findViewById(R.id.barChartDoanhThu);
        progressBaoCao = findViewById(R.id.progressBaoCao);

        taiDuLieuBieuDo();
    }

    private void taiDuLieuBieuDo() {
        progressBaoCao.setVisibility(View.VISIBLE);
        ApiClient.get(this).layBaoCaoLapDay().enqueue(new Callback<Map<String, Object>>() {
            @Override
            public void onResponse(Call<Map<String, Object>> call, Response<Map<String, Object>> res) {
                progressBaoCao.setVisibility(View.GONE);
                if (res.isSuccessful() && res.body() != null) {
                    Map<String, Object> body = res.body();
                    List<Map<String, Object>> data = new ArrayList<>();
                    if (body.get("chiTiet") instanceof List) {
                        data = (List<Map<String, Object>>) body.get("chiTiet");
                    }
                    veBieuDo(data);
                } else {
                    Toast.makeText(BaoCaoChartActivity.this, "Không tải được báo cáo: " + res.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Map<String, Object>> call, Throwable t) {
                progressBaoCao.setVisibility(View.GONE);
                Log.e(TAG, "Loi mang khi tai bieu do bao cao", t);
                Toast.makeText(BaoCaoChartActivity.this, "Lỗi kết nối máy chủ khi tải biểu đồ", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void veBieuDo(List<Map<String, Object>> data) {
        List<BarEntry> entries = new ArrayList<>();
        List<String> labels = new ArrayList<>();

        for (int i = 0; i < data.size(); i++) {
            Map<String, Object> row = data.get(i);
            Object dtObj = row.get("doanh_thu");
            float doanhThuTrieu = 0f;
            if (dtObj instanceof Number) {
                doanhThuTrieu = ((Number) dtObj).floatValue() / 1000000f;
            } else if (dtObj instanceof String) {
                try {
                    doanhThuTrieu = Float.parseFloat((String) dtObj) / 1000000f;
                } catch (Exception ignored) {}
            }
            entries.add(new BarEntry(i, doanhThuTrieu));
            String tenTour = row.get("ten_tour") != null ? String.valueOf(row.get("ten_tour")) : ("Tour " + (i + 1));
            labels.add(tenTour.length() > 12 ? tenTour.substring(0, 12) + "..." : tenTour);
        }

        BarDataSet dataSet = new BarDataSet(entries, "Doanh thu (Triệu VNĐ) - NhomNoName");
        dataSet.setColor(Color.parseColor("#0D47A1"));
        dataSet.setValueTextSize(11f);

        BarData barData = new BarData(dataSet);
        barChart.setData(barData);

        XAxis xAxis = barChart.getXAxis();
        xAxis.setValueFormatter(new IndexAxisValueFormatter(labels));
        xAxis.setPosition(XAxis.XAxisPosition.BOTTOM);
        xAxis.setGranularity(1f);

        barChart.getDescription().setEnabled(false);
        barChart.animateY(800);
        barChart.invalidate();
        Log.i(TAG, "Ve bieu do MPAndroidChart thanh cong voi " + entries.size() + " cot");
    }
}
