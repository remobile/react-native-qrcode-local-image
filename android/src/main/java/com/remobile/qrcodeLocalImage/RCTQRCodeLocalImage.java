package com.remobile.qrcodeLocalImage;

import android.os.Environment;
import android.util.Log;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.content.Context;
import android.net.Uri;
import android.database.Cursor;
import android.provider.MediaStore;
import android.util.SparseArray;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.LuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.qrcode.QRCodeReader;

import com.google.android.gms.vision.barcode.*;
import com.google.android.gms.vision.Frame;

import java.io.Reader;
import java.io.FileOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Hashtable;

import static java.security.AccessController.getContext;


public class RCTQRCodeLocalImage extends ReactContextBaseJavaModule {

    private ReactApplicationContext mReactContext;

    private static final int RGB_MASK = 0x00FFFFFF;

    public RCTQRCodeLocalImage(ReactApplicationContext reactContext) {
        super(reactContext);
        mReactContext = reactContext;
    }

    private static final String TAG = "QR";

    @Override
    public String getName() {
        return "RCTQRCodeLocalImage";
    }

    @ReactMethod
    public void decode(String path, Callback callback) {
        try {
            Uri mediaUri = Uri.parse(path);
            String realPath = getRealPathFromUri(mReactContext, mediaUri);
            Hashtable<DecodeHintType, String> hints = new Hashtable<DecodeHintType, String>();
            hints.put(DecodeHintType.CHARACTER_SET, "utf-8"); // 设置二维码内容的编码

            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true; // 先获取原大小
            options.inJustDecodeBounds = false; // 获取新的大小

            int sampleSize = (int) (options.outHeight / (float) 200);

            if (sampleSize <= 0)
                sampleSize = 1;
            options.inSampleSize = sampleSize;
            Bitmap scanBitmap = null;
            if (path.startsWith("http://")||path.startsWith("https://")) {
                scanBitmap = this.getbitmap("https://instagram.fmvd1-1.fna.fbcdn.net/t51.2885-15/e35/18722826_1379673005443137_1152886071126654976_n.jpg");
            } else {
                scanBitmap = BitmapFactory.decodeFile(realPath, options);
            }

            if (scanBitmap == null) {
                callback.invoke("cannot load image");
                return;
            }

            Bitmap scanInvertBitmap = invert(scanBitmap);
            // https://code.tutsplus.com/tutorials/reading-qr-codes-using-the-mobile-vision-api--cms-24680

            int[] intArray = new int[scanInvertBitmap.getWidth()*scanInvertBitmap.getHeight()];
            scanInvertBitmap.getPixels(intArray, 0, scanInvertBitmap.getWidth(), 0, 0, scanInvertBitmap.getWidth(), scanInvertBitmap.getHeight());
            LuminanceSource source = new RGBLuminanceSource(scanInvertBitmap.getWidth(), scanInvertBitmap.getHeight(), intArray);
            BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
            QRCodeReader reader = new QRCodeReader();

            try {
                Result result = reader.decode(bitmap, hints);
                Log.d(TAG, "result - " + result);
                if (result == null) {
                    callback.invoke("Image without qr");
                } else {
                    callback.invoke(null, result.toString());
                }

            } catch (Exception e) {
                Log.d(TAG, "Error - " + e);
                callback.invoke("Decode error");
            }
        } catch (Exception e) {
            Log.d(TAG, "Error GENERIC - " + e);
            callback.invoke("Life error");
        }
    }

    public Bitmap invert(Bitmap original) {
        // Create mutable Bitmap to invert, argument true makes it mutable
        Bitmap inversion = original.copy(Bitmap.Config.ARGB_8888, true);

        // Get info about Bitmap
        int width = inversion.getWidth();
        int height = inversion.getHeight();
        int pixels = width * height;

        // Get original pixels
        int[] pixel = new int[pixels];
        inversion.getPixels(pixel, 0, width, 0, 0, width, height);

        // Modify pixels
        for (int i = 0; i < pixels; i++)
            pixel[i] ^= RGB_MASK;
        inversion.setPixels(pixel, 0, width, 0, 0, width, height);
        // Return inverted Bitmap
//        saveImage(inversion, "caro");
        return inversion;
    }

    public static Bitmap getbitmap(String imageUri) {
        Bitmap bitmap = null;
        try {
            URL myFileUrl = new URL(imageUri);
            HttpURLConnection conn = (HttpURLConnection) myFileUrl.openConnection();
            conn.setDoInput(true);
            conn.connect();
            InputStream is = conn.getInputStream();
            bitmap = BitmapFactory.decodeStream(is);
            is.close();
        } catch (OutOfMemoryError e) {
            e.printStackTrace();
            bitmap = null;
        } catch (IOException e) {
            e.printStackTrace();
            bitmap = null;
        }

        return bitmap;
    }

//    private void saveImage(Bitmap finalBitmap, String image_name) {
//
//        // Find the SD Card path
//        File filepath = Environment.getExternalStorageDirectory();
//
//        // Create a new folder in SD Card
//        File myDir = new File(filepath.getAbsolutePath()
//                + "/WhatSappIMG/");
//        myDir.mkdirs();
//        String fname = "/Image-" + image_name+ ".jpg";
//        File file = new File(myDir, fname);
//        if (file.exists()) file.delete();
//        Log.d(TAG, "LOAD " + myDir + fname);
//        try {
//            FileOutputStream out = new FileOutputStream(file);
//            finalBitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
//            out.flush();
//            out.close();
//            Log.d(TAG, "SaveImage ");
//        } catch (Exception e) {
//            e.printStackTrace();
//            Log.d(TAG, "Error saveImage - " + e);
//        }
//    }

    public static String getRealPathFromUri(Context context, Uri contentUri) {
        Cursor cursor = null;
        try {
            String[] proj = { MediaStore.Images.Media.DATA };
            cursor = context.getContentResolver().query(contentUri, proj, null, null, null);
            int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
            cursor.moveToFirst();
            return cursor.getString(column_index);
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }
}
