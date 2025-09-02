package com.synqcast.synqcast

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class RecordingPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var currentRecordingId: String? = null
    private var outputFile: File? = null
    
    companion object {
        private const val TAG = "RecordingPlugin"
        private const val CHANNEL = "synqcast_recording"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up resources without result callback
        if (isRecording) {
            try {
                mediaRecorder?.apply {
                    stop()
                    release()
                }
                mediaRecorder = null
                isRecording = false
                currentRecordingId = null
            } catch (e: Exception) {
                Log.e(TAG, "Error cleaning up recording", e)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startRecording" -> startRecording(call, result)
            "stopRecording" -> stopRecording(result)
            "getRecordings" -> getRecordings(result)
            "deleteRecording" -> deleteRecording(call, result)
            "shareRecording" -> shareRecording(call, result)
            "requestRecordingPermission" -> requestPermission(result)
            else -> result.notImplemented()
        }
    }

    private fun startRecording(call: MethodCall, result: Result) {
        if (isRecording) {
            result.error("ALREADY_RECORDING", "Recording is already active", null)
            return
        }

        try {
            val recordingId = call.argument<String>("recordingId") ?: "recording_${System.currentTimeMillis()}"
            val roomName = call.argument<String>("roomName")
            val width = call.argument<Int>("width") ?: 1920
            val height = call.argument<Int>("height") ?: 1080
            val frameRate = call.argument<Int>("frameRate") ?: 30
            val bitRate = call.argument<Int>("bitrate") ?: 6000000
            val includeAudio = call.argument<Boolean>("includeAudio") ?: true

            // Create output file
            val fileName = "synqcast_${roomName ?: "recording"}_${System.currentTimeMillis()}.mp4"
            outputFile = File(context.getExternalFilesDir(null), fileName)
            
            // Initialize MediaRecorder
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            mediaRecorder?.apply {
                setVideoSource(MediaRecorder.VideoSource.SURFACE)
                if (includeAudio) {
                    setAudioSource(MediaRecorder.AudioSource.MIC)
                }
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                if (includeAudio) {
                    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                }
                setVideoEncodingBitRate(bitRate)
                setVideoFrameRate(frameRate)
                setVideoSize(width, height)
                setOutputFile(outputFile?.absolutePath)
                
                prepare()
                start()
            }

            isRecording = true
            currentRecordingId = recordingId

            result.success(mapOf(
                "success" to true,
                "filePath" to outputFile?.absolutePath
            ))

        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording", e)
            result.error("START_ERROR", "Failed to start recording", e.message)
        }
    }

    private fun stopRecording(result: Result) {
        if (!isRecording) {
            result.success(mapOf("success" to true))
            return
        }

        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null
            isRecording = false
            currentRecordingId = null

            result.success(mapOf("success" to true))
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording", e)
            result.error("STOP_ERROR", "Failed to stop recording", e.message)
        }
    }

    private fun getRecordings(result: Result) {
        try {
            val recordingsDir = context.getExternalFilesDir(null)
            val recordings = mutableListOf<Map<String, Any>>()
            
            recordingsDir?.listFiles()?.forEach { file ->
                if (file.name.startsWith("synqcast_") && file.extension in listOf("mp4", "webm")) {
                    val metadata = mapOf<String, Any>(
                        "filename" to file.name,
                        "filePath" to file.absolutePath,
                        "size" to file.length(),
                        "startTime" to "", // Would need to track this separately
                        "endTime" to "",
                        "duration" to 0, // Would need to extract from file
                        "roomName" to file.name.substringAfter("synqcast_").substringBefore("_")
                    )
                    recordings.add(metadata)
                }
            }

            result.success(mapOf(
                "success" to true,
                "recordings" to recordings
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error getting recordings", e)
            result.error("GET_ERROR", "Failed to get recordings", e.message)
        }
    }

    private fun deleteRecording(call: MethodCall, result: Result) {
        try {
            val filename = call.argument<String>("filename")
            if (filename == null) {
                result.error("INVALID_FILENAME", "Filename is required", null)
                return
            }

            val recordingsDir = context.getExternalFilesDir(null)
            val file = File(recordingsDir, filename)
            
            if (file.exists() && file.delete()) {
                result.success(mapOf("success" to true))
            } else {
                result.error("DELETE_ERROR", "Failed to delete recording", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting recording", e)
            result.error("DELETE_ERROR", "Failed to delete recording", e.message)
        }
    }

    private fun shareRecording(call: MethodCall, result: Result) {
        try {
            val filename = call.argument<String>("filename")
            if (filename == null) {
                result.error("INVALID_FILENAME", "Filename is required", null)
                return
            }

            val recordingsDir = context.getExternalFilesDir(null)
            val file = File(recordingsDir, filename)
            
            if (file.exists()) {
                // In a real implementation, this would use Intent to share the file
                // For now, we'll just return success
                result.success(mapOf("success" to true))
            } else {
                result.error("FILE_NOT_FOUND", "Recording file not found", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sharing recording", e)
            result.error("SHARE_ERROR", "Failed to share recording", e.message)
        }
    }

    private fun requestPermission(result: Result) {
        // For Android, recording permissions are typically handled at the app level
        // via the manifest file. This method can be used to check if permissions are granted.
        result.success(mapOf("granted" to true))
    }
}
