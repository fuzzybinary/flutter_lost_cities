package com.fuzzybinary.flutter_lost_cities

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.pytorch.IValue
import org.pytorch.Module
import org.pytorch.PyTorchAndroid
import org.pytorch.Tensor
import org.pytorch.torchvision.TensorImageUtils
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.SynchronousQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

class FlutterPyTorchModule(val objectId: Int, private val module: Module) {
  companion object {
    // For yolov5 model, no need to apply MEAN and STD
    val NO_MEAN_RGB = floatArrayOf(0.0f, 0.0f, 0.0f)
    val NO_STD_RGB = floatArrayOf(1.0f, 1.0f, 1.0f)
  }

  fun destroy() {
    module.destroy()
  }

  fun execute(imageData: IntArray, imageWidth: Int, imageHeight: Int): Tensor? {
    var bitmap = Bitmap.createBitmap(imageData, imageWidth, imageHeight, Bitmap.Config.ARGB_8888)

    val inputTensor = TensorImageUtils.bitmapToFloat32Tensor(bitmap, NO_MEAN_RGB, NO_STD_RGB)
    val outputTensor = module.forward(IValue.from(inputTensor))
    val outputTuple = outputTensor.toTuple()
    return outputTuple[0].toTensor()
  }
}

class PyTorchPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  companion object {
    const val METHOD_CHANNEL_NAME = "fuzzybinary.com/pytorch"
    const val FIRST_OBJECT_ID = 1022
  }

  private var _channel: MethodChannel? = null
  private var _binding: FlutterPlugin.FlutterPluginBinding? = null
  private val executor: ExecutorService = ThreadPoolExecutor(0, 1, 30L, TimeUnit.SECONDS, SynchronousQueue<Runnable>())

  private var currentObjectId = FIRST_OBJECT_ID
  private val moduleMap = HashMap<Int, FlutterPyTorchModule>()

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    _channel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
    _channel?.setMethodCallHandler(this)

    _binding = binding
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    _channel?.setMethodCallHandler(null)
    _channel = null
    _binding = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val binding = _binding ?: run {
      result.error("PyTorch:InvalidOperation", "Attempting to call into PyTorch with detached plugin", null)
      return
    }

    when(call.method) {
      "loadModel" -> {
        val modelFileName: String? = call.argument("model")
        try {
          val assetPath = binding.flutterAssets.getAssetFilePathByName(modelFileName!!)
          val module = PyTorchAndroid.loadModuleFromAsset(binding.applicationContext.assets, assetPath)
          val flutterModule = FlutterPyTorchModule(currentObjectId, module)
          moduleMap[flutterModule.objectId] = flutterModule
          currentObjectId++

          result.success(flutterModule.objectId)
        } catch (e: IOException) {
          result.error("PyTorch:IOException", e.localizedMessage, null)
        }
      }
      "close" -> {
        val module = _getReceiver(call)
        module?.let {
          it.destroy()
          moduleMap.remove(it.objectId)
        }
      }
      "execute" -> {
        val moduleQ = _getReceiver(call)
        val imageData: IntArray? = call.argument("image")
        val imageWidth: Int? = call.argument("width")
        val imageHeight: Int? = call.argument("height")

        val (module) = guardLet(moduleQ) {
          result.error("PyTorch:InvalidState", "The module passed to 'execute' is no longer valid'", null)
          return
        }

        val handler = Handler(Looper.getMainLooper())
        executor.execute {
          val tensor = module.execute(imageData!!, imageWidth!!, imageHeight!!)
          var data: DoubleArray? = null;
          tensor?.let {
            val floatData = it.dataAsFloatArray
            data = DoubleArray(floatData.size)
            floatData.forEachIndexed { index, value -> data!![index] = value.toDouble() }
          }
          handler.post {
            tensor?.let {
              result.success(mapOf(
                  "shape" to it.shape(),
                  "data" to data
              ))
            } ?: result.success(null)
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun _getReceiver(call: MethodCall): FlutterPyTorchModule? {
    var module: FlutterPyTorchModule? = null
    val objectId: Int? = call.argument("nativeId")
    objectId?.let {
      module = moduleMap[it]
    }
    return module
  }

  private inline fun <T : Any> guardLet(vararg elements: T?, closure: () -> Nothing): List<T> {
    return if (elements.all { it != null }) {
      elements.filterNotNull()
    } else {
      closure()
    }
  }
}