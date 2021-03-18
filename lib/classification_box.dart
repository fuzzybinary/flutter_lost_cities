import 'package:flutter/material.dart';
import 'package:flutter_match/tflite/classifier.dart';

class ClassificationBox extends StatelessWidget {
  final Rect location;
  final ClassificationResult classification;

  ClassificationBox(
      {Key? key, required this.location, required this.classification});

  @override
  Widget build(BuildContext context) {
    Color color = Colors
        .primaries[(classification.bestClassIndex) % Colors.primaries.length];

    return Positioned(
      left: location.left,
      top: location.top,
      width: location.width,
      height: location.height,
      child: Container(
        width: location.width,
        height: location.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(classification.bestClassIndex.toString()),
                  Text(" " + classification.score.toString()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
