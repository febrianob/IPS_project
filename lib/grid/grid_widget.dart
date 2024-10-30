import 'package:flutter/material.dart';
import 'package:zoom_widget/zoom_widget.dart';
import 'grid_painter.dart';

class GridWidget extends StatelessWidget {
  final CustomPainter foreground;

  const GridWidget(this.foreground, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
          width: 1.0,
        ),
      ),
      width: 400, // 8 meters * 50 pixels per meter
      height: 600, // 12 meters * 50 pixels per meter
      child: Zoom(
        maxZoomWidth: 800,
        maxZoomHeight: 1200,
        backgroundColor: Colors.grey.shade200,
        child: CustomPaint(
          painter: GridPainter(),
          foregroundPainter: foreground,
           child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/MapLab.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}