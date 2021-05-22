package com.fuzzybinary.flutter_lost_cities

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    flutterEngine?.plugins?.add(PyTorchPlugin())
  }
}
