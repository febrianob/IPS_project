import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final double gridWidth = size.width / 8; // Lebar grid dalam satuan piksel
    final double gridHeight =
        size.height / 12; // Tinggi grid dalam satuan piksel

    // Menggambar garis vertikal setiap 1 meter dan menambahkan titik koordinat
    for (int i = 1; i <= 7; i++) {
      double xPos = i * gridWidth;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), paint);
      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, 0));
    }

    // Menggambar garis horizontal setiap 1 meter dan menambahkan titik koordinat
    for (int j = 1; j <= 11; j++) {
      double yPos = j * gridHeight;
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paint);
      textPainter.text = TextSpan(
        text: '$j',
        style: const TextStyle(color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
            0,
            yPos - textPainter.height / 2,
          ));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
