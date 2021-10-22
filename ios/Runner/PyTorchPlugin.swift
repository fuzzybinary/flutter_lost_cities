//
//  PyTorchPlugin.swift
//  Runner
//
//  Created by Jeff Ward on 5/27/21.
//

import Foundation
import Flutter

public class PyTorchPlugin: NSObject, FlutterPlugin {
  static let MethodChannelName = "fuzzybinary.com/pytorch"
  static let FirstObjectId = 1022

  var instanceMap: Dictionary<Int32, TorchModule> = [:]
  var nextObjectId = Int32(FirstObjectId)
  let registrar: FlutterPluginRegistrar

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: MethodChannelName, binaryMessenger: registrar.messenger())
    let instance = PyTorchPlugin(withRegistrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(withRegistrar registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String:Any] else {
      result(FlutterError(code: "PyTorch:InvalidOperation", message: "No arguments in call", details: nil))
      return
    }

    switch call.method {
    case "loadModel":
      guard let modelFileName = arguments["model"] as? String else {
        result(FlutterError(code: "PyTorch:InvalidOperation", message: "model argument must be a string", details: nil))
        return
      }

      let modelKey = registrar.lookupKey(forAsset: modelFileName)

      if let filePath = Bundle.main.path(forResource: modelKey, ofType: nil),
         let module = TorchModule(fileAtPath: filePath, objectId: nextObjectId) {
        nextObjectId = nextObjectId + 1
        instanceMap[module.objectId] = module
        result(module.objectId)
      } else {
        result(FlutterError(code: "PyTorch:IOException", message: "Cannot find pytorch module", details: nil))
      }
    case "close":
      guard let module = getReceiver(call) else {
        result(FlutterError(code: "PyTorch:InvalidOperation", message: "Could not find module instance", details: nil))
        return
      }
      instanceMap[module.objectId] = nil
    case "execute":
      guard let arguments = call.arguments as? [String:Any],
            let module = getReceiver(call),
            let imageData = arguments["image"] as? FlutterStandardTypedData,
            let imageWidth = arguments["width"] as? NSNumber,
            let imageHeight = arguments["height"] as? NSNumber else {
        result(FlutterError(code: "PyTorch:InvalidOperation", message: "Invalid arguments passed to 'execute'", details: nil))
        return
      }

      DispatchQueue.global(qos: .background).async {
        let dataResult = module.execute(with: imageData.data, width: imageWidth.int32Value, height: imageHeight.int32Value)
        let shape = dataResult["shape"] as! [Int64]
        let shapeData = shape.withUnsafeBufferPointer { Data(buffer:$0) }

        let flutterResult = [
          "shape": FlutterStandardTypedData(int64: shapeData),
          "data": FlutterStandardTypedData(float32: dataResult["data"] as! Data)
        ]

        DispatchQueue.main.async {
          result(flutterResult)
        }
      }


    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func getReceiver(_ call: FlutterMethodCall) -> TorchModule? {
    guard let arguments = call.arguments as? [String:Any],
          let nativeIdNum = arguments["nativeId"] as? NSNumber else {
      return nil
    }

    let nativeId = nativeIdNum.int32Value
    return instanceMap[nativeId]
  }
}
