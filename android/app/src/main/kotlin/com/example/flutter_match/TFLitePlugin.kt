package com.example.flutter_match

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.Tensor
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel


class TFLitePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  companion object {
    const val METHOD_CHANNEL_NAME = "fuzzybinary.com/tflite"
    const val FIRST_OBJECT_ID = 1022
  }

  private lateinit var channel: MethodChannel
  private lateinit var binding: FlutterPlugin.FlutterPluginBinding
  private var currentObjectId = FIRST_OBJECT_ID;
  private val interpreterMap = HashMap<Integer, Interpreter>()


  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
    channel.setMethodCallHandler(this)

    this.binding = binding
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "createInterpreter" -> {
        val modelFileName: String? = call.argument("model")
        val options: HashMap<String, Any?>? = call.argument("options")
        val interpreterOptions = options?.let { createOptions(it) } ?: Interpreter.Options()
        val mappedModel = getMappedFile(modelFileName!!)
        val interpreter = Interpreter(mappedModel, interpreterOptions)

        val nativeId = currentObjectId
        interpreterMap[Integer(nativeId)] = interpreter
        currentObjectId++

        var ret = mapOf(
            "nativeId" to Integer(nativeId)
        )
        result.success(ret)
      }
      "destroyInterpreter" -> {
        val objectId: Integer? = call.argument("nativeId")
        objectId?.let {
          val interpreter = interpreterMap[it]
          interpreter?.close()
          interpreterMap.remove(it)
        }

        result.success(null)
      }
      "getOutputTensors" -> {
        val objectIdP: Integer? = call.argument("nativeId")
        val (objectId) = guardLet(objectIdP) {
          result.error("", "", null)
          return
        }

        val interpreter = interpreterMap[objectId]
        val outputTensorCount = interpreter!!.outputTensorCount
        val outputTensorMaps = ArrayList<Map<String, Any>>()
        for (i in 0..outputTensorCount) {
          var tensorMap = serializeTensor(interpreter.getOutputTensor(i))
          outputTensorMaps.add(tensorMap)
        }
        val tensorResult = mapOf(
            "tensors" to outputTensorMaps
        )
        result.success(tensorResult);
      }
      "run" -> {
        val objectId: Integer? = call.argument("nativeId")
        val input: ByteArray? = call.argument("input")
        val output: ByteArray? = call.argument("output")

        val interpreter = interpreterMap[objectId!!]
        interpreter?.run(ByteBuffer.wrap(input!!), ByteBuffer.wrap(output!!))
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  inline fun <T : Any> guardLet(vararg elements: T?, closure: () -> Nothing): List<T> {
    return if (elements.all { it != null }) {
      elements.filterNotNull()
    } else {
      closure()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun serializeTensor(tensor: Tensor): Map<String, Any> {
    return mapOf<String, Any>(
        "dataType" to tensor.dataType().toString(),
        "numBytes" to Integer(tensor.numBytes()),
        "shape" to tensor.shape()
    )
  }

  private fun createOptions(optionMap: HashMap<String, Any?>): Interpreter.Options {
    val options = Interpreter.Options()
    optionMap["allowBufferHandleOutput"]?.let { options.setAllowBufferHandleOutput(it as Boolean) }
    optionMap["isCancellable"]?.let { options.setCancellable(it as Boolean) }
    optionMap["numThreads"]?.let { options.setNumThreads((it as Integer).toInt()) }
    optionMap["useNNAPI"]?.let { options.setUseNNAPI(it as Boolean) }
    optionMap["useXNNPACK"]?.let { options.setUseXNNPACK(it as Boolean) }

    return options
  }

  private fun getMappedFile(fileName: String): MappedByteBuffer {
    val path = binding.flutterAssets.getAssetFilePathByName(fileName)
    val fd = binding.applicationContext.assets.openFd(path)
    val inputStream = FileInputStream(fd.fileDescriptor)
    val startOffset: Long = fd.getStartOffset()
    val declaredLength: Long = fd.getDeclaredLength()
    return inputStream.channel.map(
        FileChannel.MapMode.READ_ONLY,
        startOffset,
        declaredLength)
  }
}