package com.example.signatureextractor

import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.widget.Button
import android.widget.ImageView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var originalImageView: ImageView
    private lateinit var processedImageView: ImageView
    private var originalBitmap: Bitmap? = null

    private external fun extractSignature(inputBitmap: Bitmap, outputBitmap: Bitmap)

    private val pickImageLauncher = registerForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        uri?.let {
            try {
                originalBitmap = if (Build.VERSION.SDK_INT < 28) {
                    MediaStore.Images.Media.getBitmap(this.contentResolver, it)
                } else {
                    val source = ImageDecoder.createSource(this.contentResolver, it)
                    ImageDecoder.decodeBitmap(source)
                }.copy(Bitmap.Config.ARGB_8888, true)

                originalImageView.setImageBitmap(originalBitmap)
                processedImageView.setImageBitmap(null)
            } catch (e: Exception) {
                e.printStackTrace()
                Toast.makeText(this, "Gagal memuat gambar", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        originalImageView = findViewById(R.id.image_view_original)
        processedImageView = findViewById(R.id.image_view_processed)
        val selectButton: Button = findViewById(R.id.select_image_button)
        val processButton: Button = findViewById(R.id.process_image_button)

        selectButton.setOnClickListener {
            pickImageLauncher.launch("image/*")
        }

        processButton.setOnClickListener {
            originalBitmap?.let { inputBmp ->
                val outputBmp = Bitmap.createBitmap(inputBmp.width, inputBmp.height, Bitmap.Config.ARGB_8888)
                extractSignature(inputBmp, outputBmp)
                processedImageView.setImageBitmap(outputBmp)
                Toast.makeText(this, "Proses Selesai!", Toast.LENGTH_SHORT).show()
            } ?: run {
                Toast.makeText(this, "Silakan pilih gambar terlebih dahulu", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    companion object {
        init {
            System.loadLibrary("nativelib")
        }
    }
}
