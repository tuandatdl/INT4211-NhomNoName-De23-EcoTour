package com.nhomnoname.ecotouradmin.ui.datcho;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.models.DatChoItem;
import java.util.List;

public class DatChoAdapter extends RecyclerView.Adapter<DatChoAdapter.DatChoViewHolder> {
    public static final String TAG = "NhomNoName_Log";

    public interface OnHuyClickListener {
        void onHuyClick(DatChoItem item);
    }

    private final List<DatChoItem> danhSach;
    private final OnHuyClickListener listener;

    public DatChoAdapter(List<DatChoItem> danhSach, OnHuyClickListener listener) {
        this.danhSach = danhSach;
        this.listener = listener;
    }

    @NonNull
    @Override
    public DatChoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_dat_cho, parent, false);
        return new DatChoViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull DatChoViewHolder holder, int position) {
        DatChoItem item = danhSach.get(position);
        String tenTour = item.tenTour != null ? item.tenTour : ("Suất #" + item.suatId);
        holder.tvMaVeVaTour.setText(item.maVe + " - " + tenTour);
        holder.tvThongTinKhach.setText("Khách: " + (item.hoTenKhach != null ? item.hoTenKhach : ("ID " + item.khachId))
                + " | NL: " + item.soNguoiLon + ", TE: " + item.soTreEm);
        holder.tvTongTienTrangThai.setText("Tổng: " + item.tongTien + "đ | Hoàn: " + item.tienHoan + "đ | " + item.trangThai);

        if ("DA_XAC_NHAN".equals(item.trangThai)) {
            holder.btnHuyDon.setVisibility(View.VISIBLE);
            holder.btnHuyDon.setOnClickListener(v -> listener.onHuyClick(item));
        } else {
            holder.btnHuyDon.setVisibility(View.GONE);
        }
    }

    @Override
    public int getItemCount() {
        return danhSach.size();
    }

    static class DatChoViewHolder extends RecyclerView.ViewHolder {
        TextView tvMaVeVaTour, tvThongTinKhach, tvTongTienTrangThai;
        Button btnHuyDon;

        public DatChoViewHolder(@NonNull View itemView) {
            super(itemView);
            tvMaVeVaTour = itemView.findViewById(R.id.tvMaVeVaTour);
            tvThongTinKhach = itemView.findViewById(R.id.tvThongTinKhach);
            tvTongTienTrangThai = itemView.findViewById(R.id.tvTongTienTrangThai);
            btnHuyDon = itemView.findViewById(R.id.btnHuyDon);
        }
    }
}
