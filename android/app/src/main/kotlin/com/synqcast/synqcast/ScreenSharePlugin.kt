package com.synqcast.synqcast

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import android.view.Surface
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.nio.ByteBuffer

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class ScreenSharePlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaCodec: MediaCodec? = null
    private var mediaMuxer: MediaMuxer? = null
    private var surface: Surface? = null
    
    private var screenWidth = 1920
    private var screenHeight = 1080
    private var screenDensity = 1
    private var bitRate = 6000000
    private var frameRate = 30
    private var includeAudio = false
    
    private var isRecording = false
    private var outputFile: File? = null
    private var pendingResult: Result? = null
    private var pendingPermissionResult: Result? = null
    
    companion object {
        private const val TAG = "ScreenSharePlugin"
        private const val CHANNEL = "synqcast_screen_share"
        private const val REQUEST_MEDIA_PROJECTION = 1001
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            mediaProjectionManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up resources without result callback
        if (isRecording) {
            try {
                mediaCodec?.stop()
                mediaCodec?.release()
                virtualDisplay?.release()
                mediaMuxer?.stop()
                mediaMuxer?.release()
                surface?.release()
                mediaProjection?.stop()

                mediaCodec = null
                virtualDisplay = null
                mediaMuxer = null
                surface = null
                mediaProjection = null
                isRecording = false
            } catch (e: Exception) {
                Log.e(TAG, "Error cleaning up screen share", e)
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startScreenShare" -> startScreenShare(call, result)
            "stopScreenShare" -> stopScreenShare(result)
            "isScreenShareSupported" -> checkSupport(result)
            "requestScreenRecordingPermission" -> requestPermission(result)
            else -> result.notImplemented()
        }
    }

    private fun startScreenShare(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            result.error("UNSUPPORTED", "Screen sharing requires API level 21+", null)
            return
        }

        if (isRecording) {
            result.error("ALREADY_RECORDING", "Screen sharing is already active", null)
            return
        }

        // Get parameters
        screenWidth = call.argument("width") ?: 1920
        screenHeight = call.argument("height") ?: 1080
        frameRate = call.argument("frameRate") ?: 30
        bitRate = call.argument("bitrate") ?: 6000000
        includeAudio = call.argument("includeAudio") ?: false

        pendingResult = result
        
        // Request permission
        val intent = mediaProjectionManager?.createScreenCaptureIntent()
        activity?.startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
    }

    private fun stopScreenShare(result: Result) {
        if (!isRecording) {
            result.success(mapOf("success" to true))
            return
        }

        try {
            mediaCodec?.stop()
            mediaCodec?.release()
            virtualDisplay?.release()
            mediaMuxer?.stop()
            mediaMuxer?.release()
            surface?.release()
            mediaProjection?.stop()

            mediaCodec = null
            virtualDisplay = null
            mediaMuxer = null
            surface = null
            mediaProjection = null
            isRecording = false

            result.success(mapOf("success" to true))
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping screen share", e)
            result.error("STOP_ERROR", "Failed to stop screen sharing", e.message)
        }
    }

    private fun checkSupport(result: Result) {
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP
        result.success(mapOf("supported" to supported))
    }

    private fun requestPermission(result: Result) {
        pendingPermissionResult = result
        val intent = mediaProjectionManager?.createScreenCaptureIntent()
        activity?.startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Permission granted
                pendingPermissionResult?.success(mapOf("granted" to true))
                pendingPermissionResult = null
                
                // Start screen sharing if pending
                if (pendingResult != null) {
                    startRecording(resultCode, data)
                }
            } else {
                // Permission denied
                pendingPermissionResult?.success(mapOf("granted" to false))
                pendingPermissionResult = null
                pendingResult?.error("PERMISSION_DENIED", "Screen recording permission denied", null)
                pendingResult = null
            }
            return true
        }
        return false
    }

    private fun startRecording(resultCode: Int, data: Intent) {
        try {
            // Create output file
            val fileName = "synqcast_screen_${System.currentTimeMillis()}.mp4"
            outputFile = File(context.getExternalFilesDir(null), fileName)
            
            // Initialize MediaCodec
            val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, screenWidth, screenHeight)
            format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
            format.setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
            format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)

            mediaCodec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            mediaCodec?.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            surface = mediaCodec?.createInputSurface()
            mediaCodec?.start()

            // Initialize MediaMuxer
            mediaMuxer = MediaMuxer(outputFile?.absolutePath ?: "", MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Start MediaProjection
            mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenShare",
                screenWidth, screenHeight, screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                surface, null, null
            )

            isRecording = true
            
            pendingResult?.success(mapOf(
                "success" to true,
                "streamId" to System.currentTimeMillis().toString(),
                "filePath" to outputFile?.absolutePath
            ))
            pendingResult = null

            // Start encoding loop
            startEncodingLoop()

        } catch (e: Exception) {
            Log.e(TAG, "Error starting screen recording", e)
            pendingResult?.error("START_ERROR", "Failed to start screen sharing", e.message)
            pendingResult = null
        }
    }

    private fun startEncodingLoop() {
        Thread {
            val bufferInfo = MediaCodec.BufferInfo()
            
            while (isRecording) {
                val outputBufferId = mediaCodec?.dequeueOutputBuffer(bufferInfo, 10000)
                
                when (outputBufferId) {
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val format = mediaCodec?.outputFormat
                        if (format != null) {
                            val trackIndex = mediaMuxer?.addTrack(format)
                            mediaMuxer?.start()
                        }
                    }
                    MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> {
                        // Ignore
                    }
                    MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        // Timeout, continue
                    }
                    else -> {
                        if (outputBufferId != null && outputBufferId >= 0) {
                            val outputBuffer = mediaCodec?.getOutputBuffer(outputBufferId)
                            if (outputBuffer != null && bufferInfo.size > 0) {
                                mediaMuxer?.writeSampleData(0, outputBuffer, bufferInfo)
                            }
                            mediaCodec?.releaseOutputBuffer(outputBufferId, false)
                        }
                    }
                }
            }
        }.start()
    }
}
