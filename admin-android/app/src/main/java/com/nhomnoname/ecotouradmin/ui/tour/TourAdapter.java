package com.nhomnoname.ecotouradmin.ui.tour;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.models.Tour;
import java.text.DecimalFormat;
import java.util.List;

public class TourAdapter extends RecyclerView.Adapter<TourAdapter.TourViewHolder> {
    public static final String TAG = "NhomNoName_Log";

    public interface OnTourActionListener {
        void onViewSuat(Tour tour);
        void onEditTour(Tour tour);
        void onDeleteTour(Tour tour);
    }

    private final List<Tour> danhSachTour;
    private final OnTourActionListener listener;
    private final DecimalFormat formatter = new DecimalFormat("#,###");

    public TourAdapter(List<Tour> danhSachTour, OnTourActionListener listener) {
        this.danhSachTour = danhSachTour;
        this.listener = listener;
    }

    @NonNull
    @Override
    public TourViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_tour, parent, false);
        return new TourViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull TourViewHolder holder, int position) {
        Tour tour = danhSachTour.get(position);

        holder.tvTourName.setText(tour.ten);

        // Hiển thị trạng thái tour
        if ("HOAT_DONG".equalsIgnoreCase(tour.trangThai) || "DANG_MO".equalsIgnoreCase(tour.trangThai)) {
            holder.tvTourStatus.setText("HOẠT ĐỘNG");
            holder.tvTourStatus.setTextColor(Color.parseColor("#15803D"));
            holder.tvTourStatus.setBackgroundColor(Color.parseColor("#DCFCE7"));
        } else {
            holder.tvTourStatus.setText("TẠM NGƯNG");
            holder.tvTourStatus.setTextColor(Color.parseColor("#B91C1C"));
            holder.tvTourStatus.setBackgroundColor(Color.parseColor("#FEE2E2"));
        }

        // Thời lượng & số sao
        holder.tvTourDuration.setText(String.format("Thời lượng: %d ngày | Đánh giá: ★ %.1f", tour.soNgay, tour.danhGiaSao > 0 ? tour.danhGiaSao : 5.0));

        // Giá vé
        String giaNL = formatter.format(tour.giaNguoiLon) + " đ";
        String giaTE = formatter.format(tour.giaTreEm) + " đ";
        holder.tvTourPrice.setText("Người lớn: " + giaNL + " | Trẻ em: " + giaTE);

        // Số suất
        holder.tvTourSuatCount.setText("Tổng số suất khởi hành: " + tour.tongSoSuat + " suất");

        // Bắt sự kiện các nút
        holder.btnViewSuat.setOnClickListener(v -> {
            if (listener != null) listener.onViewSuat(tour);
        });

        holder.btnEditTour.setOnClickListener(v -> {
            if (listener != null) listener.onEditTour(tour);
        });

        holder.btnDeleteTour.setOnClickListener(v -> {
            if (listener != null) listener.onDeleteTour(tour);
        });
    }

    @Override
    public int getItemCount() {
        return danhSachTour.size();
    }

    public static class TourViewHolder extends RecyclerView.ViewHolder {
        TextView tvTourName, tvTourStatus, tvTourDuration, tvTourPrice, tvTourSuatCount;
        Button btnViewSuat, btnEditTour, btnDeleteTour;

        public TourViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTourName = itemView.findViewById(R.id.tvTourName);
            tvTourStatus = itemView.findViewById(R.id.tvTourStatus);
            tvTourDuration = itemView.findViewById(R.id.tvTourDuration);
            tvTourPrice = itemView.findViewById(R.id.tvTourPrice);
            tvTourSuatCount = itemView.findViewById(R.id.tvTourSuatCount);
            btnViewSuat = itemView.findViewById(R.id.btnViewSuat);
            btnEditTour = itemView.findViewById(R.id.btnEditTour);
            btnDeleteTour = itemView.findViewById(R.id.btnDeleteTour);
        }
    }
}

