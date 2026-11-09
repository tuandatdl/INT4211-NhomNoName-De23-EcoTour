package com.nhomnoname.ecotouradmin.api;

import android.content.Context;
import java.util.concurrent.TimeUnit;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ApiClient {
    public static final String TAG = "NhomNoName_Log"; // Chứa mã nhóm chống sao chép
    private static final String BASE_URL = "https://ecotour-cangio-vungtau.onrender.com/"; // Link Render that (hoac thay bang URL khi deploy)
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
