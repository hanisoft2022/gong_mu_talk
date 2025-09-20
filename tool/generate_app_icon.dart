import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const int size = 1024;
  final img.Image icon = img.Image(width: size, height: size);

  const List<int> startColor = [15, 92, 186];
  const List<int> endColor = [64, 195, 141];

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double t = ((x + (size - y)) / (2 * size)).clamp(0.0, 1.0);
      final int r = (startColor[0] + (endColor[0] - startColor[0]) * t).round();
      final int g = (startColor[1] + (endColor[1] - startColor[1]) * t).round();
      final int b = (startColor[2] + (endColor[2] - startColor[2]) * t).round();
      icon.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  final int bubbleLeft = (size * 0.18).round();
  final int bubbleRight = (size * 0.82).round();
  final int bubbleTop = (size * 0.21).round();
  final int bubbleBottom = (size * 0.63).round();
  final int bubbleRadius = (size * 0.18).round();
  final int tailWidth = (size * 0.16).round();
  final int tailHeight = (size * 0.13).round();
  final int shadowOffset = (size * 0.035).round();

  final img.ColorRgba8 shadowColor = img.ColorRgba8(12, 36, 80, 90);
  final img.ColorRgba8 bubbleColor = img.ColorRgba8(255, 255, 255, 255);
  final img.ColorRgba8 highlightColor = img.ColorRgba8(255, 255, 255, 28);
  final img.ColorRgba8 innerColor = img.ColorRgba8(28, 75, 150, 255);

  void drawRoundedRect(
    img.Image target, {
    required int left,
    required int top,
    required int right,
    required int bottom,
    required int radius,
    required img.Color color,
  }) {
    img.fillRect(target,
        x1: left,
        y1: top,
        x2: right,
        y2: bottom,
        radius: radius,
        color: color);
  }

  final img.Image shadowLayer = img.Image(width: size, height: size);
  drawRoundedRect(shadowLayer,
      left: bubbleLeft + shadowOffset,
      top: bubbleTop + shadowOffset,
      right: bubbleRight + shadowOffset,
      bottom: bubbleBottom + shadowOffset,
      radius: bubbleRadius,
      color: shadowColor);
  img.fillPolygon(shadowLayer,
      vertices: <img.Point>[
        img.Point((bubbleLeft +
                    (bubbleRight - bubbleLeft - tailWidth) ~/ 2 +
                    shadowOffset)
                .toDouble(),
            (bubbleBottom + shadowOffset).toDouble()),
        img.Point((bubbleLeft +
                    (bubbleRight - bubbleLeft + tailWidth) ~/ 2 +
                    shadowOffset)
                .toDouble(),
            (bubbleBottom + shadowOffset).toDouble()),
        img.Point(((bubbleLeft + bubbleRight) / 2 + shadowOffset).toDouble(),
            (bubbleBottom + tailHeight + shadowOffset).toDouble()),
      ],
      color: shadowColor);
  img.gaussianBlur(shadowLayer, radius: 6);
  img.compositeImage(icon, shadowLayer);

  drawRoundedRect(icon,
      left: bubbleLeft,
      top: bubbleTop,
      right: bubbleRight,
      bottom: bubbleBottom,
      radius: bubbleRadius,
      color: bubbleColor);
  img.fillPolygon(icon,
      vertices: <img.Point>[
        img.Point(
            (bubbleLeft + (bubbleRight - bubbleLeft - tailWidth) ~/ 2).toDouble(),
            bubbleBottom.toDouble()),
        img.Point(
            (bubbleLeft + (bubbleRight - bubbleLeft + tailWidth) ~/ 2).toDouble(),
            bubbleBottom.toDouble()),
        img.Point(
            ((bubbleLeft + bubbleRight) / 2).toDouble(),
            (bubbleBottom + tailHeight).toDouble()),
      ],
      color: bubbleColor);

  final img.Image highlight = img.Image(width: size, height: size);
  drawRoundedRect(highlight,
      left: bubbleLeft,
      top: bubbleTop,
      right: bubbleRight,
      bottom: bubbleTop + (bubbleBottom - bubbleTop) ~/ 2,
      radius: bubbleRadius,
      color: highlightColor);
  img.gaussianBlur(highlight, radius: 4);
  img.compositeImage(icon, highlight);

  final img.Image innerBubble = img.Image(width: size, height: size);
  final int innerLeft = bubbleLeft + (size * 0.08).round();
  final int innerRight = bubbleRight - (size * 0.08).round();
  final int innerTop = bubbleTop + (size * 0.08).round();
  final int innerBottom = bubbleBottom - (size * 0.12).round();
  final int innerRadius = (size * 0.14).round();
  drawRoundedRect(innerBubble,
      left: innerLeft,
      top: innerTop,
      right: innerRight,
      bottom: innerBottom,
      radius: innerRadius,
      color: innerColor);
  img.fillPolygon(innerBubble,
      vertices: <img.Point>[
        img.Point(
            (innerLeft +
                    (innerRight - innerLeft - (tailWidth * 0.7).round()) ~/ 2)
                .toDouble(),
            innerBottom.toDouble()),
        img.Point(
            (innerLeft +
                    (innerRight - innerLeft + (tailWidth * 0.7).round()) ~/ 2)
                .toDouble(),
            innerBottom.toDouble()),
        img.Point(
            ((innerLeft + innerRight) / 2).toDouble(),
            (innerBottom + (tailHeight * 0.6).round()).toDouble()),
      ],
      color: innerColor);
  img.gaussianBlur(innerBubble, radius: 1);
  img.compositeImage(icon, innerBubble);

  const String outputPath = 'assets/icons/app_icon.png';
  final File outputFile = File(outputPath);
  outputFile
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(icon));

  stdout.writeln('Generated icon at ${outputFile.path}');
}
