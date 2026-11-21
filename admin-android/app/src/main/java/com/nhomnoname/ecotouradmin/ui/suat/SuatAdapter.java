package com.nhomnoname.ecotouradmin.ui.suat;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.models.SuatKhoiHanh;
import java.util.List;

public class SuatAdapter extends RecyclerView.Adapter<SuatAdapter.SuatViewHolder> {
    public static final String TAG = "NhomNoName_Log";

    public interface OnSuatActionListener {
        void onDeleteSuat(SuatKhoiHanh suat);
    }

    private final List<SuatKhoiHanh> danhSachSuat;
    private final OnSuatActionListener listener;

    public SuatAdapter(List<SuatKhoiHanh> danhSachSuat, OnSuatActionListener listener) {
        this.danhSachSuat = danhSachSuat;
        this.listener = listener;
    }

    @NonNull
    @Override
    public SuatViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_suat, parent, false);
        return new SuatViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull SuatViewHolder holder, int position) {
        SuatKhoiHanh suat = danhSachSuat.get(position);

        holder.tvSuatNgayDi.setText("Ngày: " + suat.ngayDi + " - " + suat.gioTapTrung);

        // Trạng thái suất
        if ("MO_BAN".equalsIgnoreCase(suat.trangThai) || "NHAN_KHACH".equalsIgnoreCase(suat.trangThai)) {
            holder.tvSuatTrangThai.setText("MỞ BÁN");
            holder.tvSuatTrangThai.setTextColor(Color.parseColor("#15803D"));
            holder.tvSuatTrangThai.setBackgroundColor(Color.parseColor("#DCFCE7"));
        } else if ("HET_CHO".equalsIgnoreCase(suat.trangThai)) {
            holder.tvSuatTrangThai.setText("HẾT CHỖ");
            holder.tvSuatTrangThai.setTextColor(Color.parseColor("#D97706"));
            holder.tvSuatTrangThai.setBackgroundColor(Color.parseColor("#FEF3C7"));
        } else {
            holder.tvSuatTrangThai.setText("ĐÃ HỦY");
            holder.tvSuatTrangThai.setTextColor(Color.parseColor("#B91C1C"));
            holder.tvSuatTrangThai.setBackgroundColor(Color.parseColor("#FEE2E2"));
        }

        holder.tvSuatDiemTapTrung.setText("Điểm đón: " + suat.diemTapTrung);
        holder.tvSuatPhuongTien.setText("Phương tiện: " + suat.phuongTien);

        if (suat.tenHdv != null && !suat.tenHdv.isEmpty()) {
            String sdt = suat.sdtHdv != null ? " (" + suat.sdtHdv + ")" : "";
            holder.tvSuatHdv.setText("HDV: " + suat.tenHdv + sdt);
        } else {
            holder.tvSuatHdv.setText("HDV: Chưa chỉ định");
        }

        // Chỗ còn lại / Tổng số chỗ
        if (suat.soChoConLai > 0) {
            holder.tvSuatChoTrong.setText("Còn trống: " + suat.soChoConLai + " / " + suat.soCho + " chỗ");
            holder.tvSuatChoTrong.setTextColor(Color.parseColor("#059669"));
        } else {
            holder.tvSuatChoTrong.setText("Hết chỗ: " + suat.soChoDaDat + " / " + suat.soCho + " khách");
            holder.tvSuatChoTrong.setTextColor(Color.parseColor("#DC2626"));
        }

        holder.btnDeleteSuat.setOnClickListener(v -> {
            if (listener != null) listener.onDeleteSuat(suat);
        });
    }

    @Override
    public int getItemCount() {
        return danhSachSuat.size();
    }

    public static class SuatViewHolder extends RecyclerView.ViewHolder {
        TextView tvSuatNgayDi, tvSuatTrangThai, tvSuatDiemTapTrung, tvSuatPhuongTien, tvSuatHdv, tvSuatChoTrong;
        Button btnDeleteSuat;

        public SuatViewHolder(@NonNull View itemView) {
            super(itemView);
            tvSuatNgayDi = itemView.findViewById(R.id.tvSuatNgayDi);
            tvSuatTrangThai = itemView.findViewById(R.id.tvSuatTrangThai);
            tvSuatDiemTapTrung = itemView.findViewById(R.id.tvSuatDiemTapTrung);
            tvSuatPhuongTien = itemView.findViewById(R.id.tvSuatPhuongTien);
            tvSuatHdv = itemView.findViewById(R.id.tvSuatHdv);
            tvSuatChoTrong = itemView.findViewById(R.id.tvSuatChoTrong);
            btnDeleteSuat = itemView.findViewById(R.id.btnDeleteSuat);
        }
    }
}

