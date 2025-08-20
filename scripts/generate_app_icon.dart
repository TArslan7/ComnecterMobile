import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  // Create a canvas to draw the app icon
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);
  
  // Draw the background gradient
  final paint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF3B82F6), // Royal Blue
        Color(0xFF06B6D4), // Sky Blue
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  
  // Draw the "C" logo
  final textPainter = TextPainter(
    text: const TextSpan(
      text: 'C',
      style: TextStyle(
        color: Colors.white,
        fontSize: 400,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    ),
  );
  
  // Draw concentric circles
  final circlePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  
  final center = Offset(size.width / 2, size.height / 2);
  final radius1 = 200.0;
  final radius2 = 280.0;
  final radius3 = 360.0;
  
  // Draw circles with gaps
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius1),
    0,
    2 * 3.14159,
    false,
    circlePaint,
  );
  
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius2),
    0,
    2 * 3.14159,
    false,
    circlePaint,
  );
  
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius3),
    0,
    2 * 3.14159,
    false,
    circlePaint,
  );
  
  // Draw the pointer/checkmark
  final path = Path();
  path.moveTo(center.dx + radius3 * 0.7, center.dy - radius3 * 0.7);
  path.lineTo(center.dx + radius3 * 0.9, center.dy - radius3 * 0.5);
  path.lineTo(center.dx + radius3 * 0.8, center.dy - radius3 * 0.3);
  
  final pointerPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round;
  
  canvas.drawPath(path, pointerPaint);
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  // Save the icon
  final file = File('assets/app_icon.png');
  await file.writeAsBytes(bytes);
  
  print('App icon generated successfully!');
}
