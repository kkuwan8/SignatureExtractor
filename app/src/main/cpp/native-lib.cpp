#include <jni.h>
#include <android/bitmap.h>
#include <android/log.h>

extern "C" JNIEXPORT void JNICALL
Java_com_example_signatureextractor_MainActivity_extractSignature(
        JNIEnv *env,
        jobject /* this */,
        jobject inputBitmap,
        jobject outputBitmap
) {
    AndroidBitmapInfo inputInfo, outputInfo;
    void *inputPixels, *outputPixels;

    if (AndroidBitmap_getInfo(env, inputBitmap, &inputInfo) < 0) return;
    if (AndroidBitmap_lockPixels(env, inputBitmap, &inputPixels) < 0) return;
    if (AndroidBitmap_getInfo(env, outputBitmap, &outputInfo) < 0) return;
    if (AndroidBitmap_lockPixels(env, outputBitmap, &outputPixels) < 0) return;

    int width = inputInfo.width;
    int height = inputInfo.height;

    for (int y = 0; y < height; y++) {
        auto *inputRow = (uint32_t *) ((char *) inputPixels + y * inputInfo.stride);
        auto *outputRow = (uint32_t *) ((char *) outputPixels + y * outputInfo.stride);

        for (int x = 0; x < width; x++) {
            uint32_t pixel = inputRow[x];
            uint8_t r = (pixel >> 16) & 0xFF;
            uint8_t g = (pixel >> 8) & 0xFF;
            uint8_t b = pixel & 0xFF;

            int grayscale = (int) (0.299 * r + 0.587 * g + 0.114 * b);

            if (grayscale < 150) {
                outputRow[x] = 0xFF000000;
            } else {
                outputRow[x] = 0x00000000;
            }
        }
    }

    AndroidBitmap_unlockPixels(env, inputBitmap);
    AndroidBitmap_unlockPixels(env, outputBitmap);
}
