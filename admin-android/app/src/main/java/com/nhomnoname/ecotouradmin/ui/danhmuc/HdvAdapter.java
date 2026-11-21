package com.nhomnoname.ecotouradmin.ui.danhmuc;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.nhomnoname.ecotouradmin.R;
import com.nhomnoname.ecotouradmin.models.HuongDanVien;
import java.util.List;
import java.util.Locale;

public class HdvAdapter extends RecyclerView.Adapter<HdvAdapter.HdvViewHolder> {
    public static final String TAG = "NhomNoName_Log";

    private final List<HuongDanVien> danhSachHdv;

    public HdvAdapter(List<HuongDanVien> danhSachHdv) {
        this.danhSachHdv = danhSachHdv;
    }

    @NonNull
    @Override
    public HdvViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_hdv, parent, false);
        return new HdvViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull HdvViewHolder holder, int position) {
        HuongDanVien hdv = danhSachHdv.get(position);

        holder.tvHdvName.setText(hdv.hoTen);
        holder.tvHdvRating.setText(String.format(Locale.getDefault(), "★ %.1f", hdv.danhGiaSao > 0 ? hdv.danhGiaSao : 5.0));
        holder.tvHdvLanguages.setText("Ngôn ngữ: " + (hdv.ngonNgu != null ? hdv.ngonNgu : "Tiếng Việt"));
        holder.tvHdvCert.setText("Chứng chỉ: " + (hdv.chungChi != null ? hdv.chungChi : "Thẻ HDV chính thức"));
        holder.tvHdvPhone.setText("SĐT: " + (hdv.sdt != null ? hdv.sdt : "Chưa cập nhật"));
        holder.tvHdvSuatCount.setText("Phụ trách: " + hdv.soSuatPhuTrach + " suất");
    }

    @Override
    public int getItemCount() {
        return danhSachHdv.size();
    }

    public static class HdvViewHolder extends RecyclerView.ViewHolder {
        TextView tvHdvName, tvHdvRating, tvHdvLanguages, tvHdvCert, tvHdvPhone, tvHdvSuatCount;

        public HdvViewHolder(@NonNull View itemView) {
            super(itemView);
            tvHdvName = itemView.findViewById(R.id.tvHdvName);
            tvHdvRating = itemView.findViewById(R.id.tvHdvRating);
            tvHdvLanguages = itemView.findViewById(R.id.tvHdvLanguages);
            tvHdvCert = itemView.findViewById(R.id.tvHdvCert);
            tvHdvPhone = itemView.findViewById(R.id.tvHdvPhone);
            tvHdvSuatCount = itemView.findViewById(R.id.tvHdvSuatCount);
        }
    }
}

