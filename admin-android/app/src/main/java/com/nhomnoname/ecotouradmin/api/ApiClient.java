package com.nhomnoname.ecotouradmin.api;

import android.content.Context;
import java.util.concurrent.TimeUnit;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ApiClient {
    public static final String TAG = "NhomNoName_Log"; // Chứa mã nhóm chống sao chép

    // CẤU HÌNH ĐỊA CHỈ MÁY CHỦ:
    // - Khi test trên Máy ảo Android Studio (Emulator): dùng "http://10.0.2.2:3000/"
    // - Khi test trên Điện thoại thật cắm USB / cùng Wi-Fi: dùng "http://192.168.1.165:3000/"
    // - Khi TV1 đã deploy lên Render: đổi lại thành "https://ecotour-cangio-vungtau.onrender.com/"
    private static final String BASE_URL = "http://10.0.2.2:3000/";
    private static Retrofit retrofit;

    public static ApiService get(Context ctx) {
        if (retrofit == null) {
            OkHttpClient client = new OkHttpClient.Builder()
                .addInterceptor(chain -> {
                    String token = TokenStore.layToken(ctx);
                    Request.Builder builder = chain.request().newBuilder();
                    if (token != null && !token.isEmpty()) {
                        builder.addHeader("Authorization", "Bearer " + token);
                    }
                    return chain.proceed(builder.build());
                })
                .connectTimeout(90, TimeUnit.SECONDS) // Render Free ngu day cham, bat buoc 90s
                .readTimeout(90, TimeUnit.SECONDS)
                .build();

            retrofit = new Retrofit.Builder()
                .baseUrl(BASE_URL)
                .client(client)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        }
        return retrofit.create(ApiService.class);
    }
}
