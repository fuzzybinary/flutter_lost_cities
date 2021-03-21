import 'package:camera/camera.dart';
import 'package:image/image.dart';

class CameraUtils {
  static Image? convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    } else {
      return null;
    }
  }

  static Image convertBGRA8888ToImage(CameraImage cameraImage) {
    Image img = Image.fromBytes(cameraImage.planes[0].width!,
        cameraImage.planes[0].height!, cameraImage.planes[0].bytes,
        format: Format.bgra);
    return img;
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int pixelStride = cameraImage.planes[0].bytesPerRow;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = Image(width, height);

    for (int y = 0; y < height; y++) {
      final yUvIndex = uvRowStride * (y / 2).floor();
      final yPixelIndex = y * pixelStride;
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + yUvIndex;
        final int index = yPixelIndex + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255).toInt();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255)
            .toInt();
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b);
      }
    }
    return image;
  }
}
