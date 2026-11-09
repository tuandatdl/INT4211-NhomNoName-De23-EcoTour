package com.nhomnoname.ecotouradmin.api;

import android.content.Context;
import android.content.SharedPreferences;

public class TokenStore {
    public static final String TAG = "NhomNoName_Log";
    private static final String PREF_NAME = "EcoTourAdminPrefs_NhomNoName";

    public static void luuPhien(Context ctx, String token, String vaiTro, String hoTen) {
        SharedPreferences prefs = ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        prefs.edit()
            .putString("token", token)
            .putString("vai_tro", vaiTro)
            .putString("ho_ten", hoTen)
            .apply();
    }

    public static String layToken(Context ctx) {
        return ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE).getString("token", "");
    }

    public static String layVaiTro(Context ctx) {
        return ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE).getString("vai_tro", "");
    }

    public static void xoaPhien(Context ctx) {
        ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE).edit().clear().apply();
    }
}
