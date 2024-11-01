import 'package:ips_project/trilateration_method.dart';
import 'package:flutter/material.dart';
import 'package:ips_project/grid/grid_widget.dart';
import 'package:get/get.dart';
import 'package:ips_project/ble_data.dart';
import 'dart:math';

class CircleRoute extends StatefulWidget {
  const CircleRoute({super.key});

  @override
  CircleRouteState createState() => CircleRouteState();
}

class CircleRouteState extends State<CircleRoute>
    with SingleTickerProviderStateMixin {
  double waveRadius = 100.0;
  late AnimationController controller;
  var centerXList = [];
  var centerYList = [];
  List<num> radiusList = [];

  @override
  void initState() {
    super.initState();
    final bleController = Get.put(BLEResult());

    //animation duration 2 seconds
    controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..addListener(() => setState(() {}))
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
          centerXList = bleController.selectedCenterXList;
          centerYList = bleController.selectedCenterYList;
          // initialize radius list
          radiusList = [];
          for (int i = 0; i < bleController.selectedDistanceList.length; i++) {
            radiusList.add(0.0);
          }
          // rssi to distance
          for (int idx = 0;
              idx < bleController.selectedDistanceList.length;
              idx++) {
            var rssi = bleController
                .scanResultList[bleController.selectedDeviceIdxList[idx]].rssi;
            var alpha = bleController.selectedRSSI_1mList[idx];
            var constantN = bleController.selectedConstNList[idx];
            var distance = logDistancePathLoss(
                rssi.toDouble(), alpha.toDouble(), constantN.toDouble());
            radiusList[idx] = distance;
          }
        }
      });
  }

  /* log distance path loss model */
  num logDistancePathLoss(double rssi, double alpha, double constantN) {
    return pow(10.0, ((alpha - rssi) / (10 * constantN)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GridWidget(
        CirclePainter(centerXList, centerYList, radiusList),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CirclePainter extends CustomPainter {
  var centerXList = [];
  var centerYList = [];
  var radiusList = [];

  var anchorePaint = Paint()
    ..color = Colors.lightBlue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..isAntiAlias = true;
  
  var beaconPointPaint = Paint()
    ..color = Colors.blue[900]! // Warna lebih gelap untuk beacon
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  var positionPaint = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12.0
    ..isAntiAlias = true;

  final bleController = Get.find<BLEResult>();

  CirclePainter(this.centerXList, this.centerYList, this.radiusList);

  @override
  void paint(Canvas canvas, Size size) {
    List<Anchor> anchorList = [];
    List<double> pointDistance = [];

    if (radiusList.isNotEmpty) {
      for (int i = 0; i < radiusList.length; i++) {
        // radius
        var radius = radiusList[i] > bleController.maxDistance
            ? bleController.maxDistance
            : radiusList[i];
        anchorList.add(Anchor(
            centerX: centerXList[i], centerY: centerYList[i], radius: radius));
        canvas.drawCircle(Offset(centerXList[i] * 100, centerYList[i] * 100),
            radius * 100, anchorePaint);

        canvas.drawCircle(
            Offset(centerXList[i] * 100, centerYList[i] * 100),
            12.0, // Ukuran titik beacon
            beaconPointPaint);    
        // anchor text paint
        var anchorTextPainter = TextPainter(
          text: TextSpan(
            text: 'Beacon${i + 1}\n(${centerXList[i]}, ${centerYList[i]})',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        anchorTextPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        anchorTextPainter.paint(canvas,
            Offset(centerXList[i] * 100 - 25, centerYList[i] * 100 + 5));
        // radius text paint
        var radiusTextPainter = TextPainter(
          text: TextSpan(
            text: '  ${radius.toStringAsFixed(2)}m',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        radiusTextPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        radiusTextPainter.paint(
            canvas,
            Offset(centerXList[i] * 100,
                centerYList[i] * 100 - (radius * 100) / 2 - 5));

        drawDashedLine(canvas, anchorePaint, centerXList[i] * 100,
            centerYList[i] * 100, radius * 100);
      }
      // decision max distance
      if (anchorList.length >= 3) {
        for (int i = 0; i < anchorList.length - 1; i++) {
          pointDistance.add(sqrt(
              pow((anchorList[i + 1].centerX - anchorList[0].centerX), 2) +
                  pow((anchorList[i + 1].centerY - anchorList[0].centerY), 2)));
        }
        var maxDistance = pointDistance.reduce(max);
        bleController.maxDistance = maxDistance;
        // ignore: avoid_print
        print(maxDistance);
        //
        var position =
            trilaterationMethod(anchorList, bleController.maxDistance);

        if ((position[0][0] >= 0.0) && (position[1][0] >= 0.0)) {
          canvas.drawCircle(Offset(position[0][0] * 100, position[1][0] * 100),
              5, positionPaint);
          // Perbarui posisi saat ini
          bleController.updateCurrentPosition(position[0][0], position[1][0]);

          var positionTextPainter = TextPainter(
            text: TextSpan(
              text:
                  '(${position[0][0].toStringAsFixed(2)}, ${position[1][0].toStringAsFixed(2)})',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          positionTextPainter.layout(
            minWidth: 0,
            maxWidth: size.width,
          );

          positionTextPainter.paint(canvas,
              Offset(position[0][0] * 100 - 25, position[1][0] * 100 + 10));
        }
      }
    }
  }

  void drawDashedLine(Canvas canvas, Paint paint, double centerX,
      double centerY, double radius) {
    const int dashWidth = 8;
    const int dashSpace = 12;
    double startY = 0;
    while (startY < radius - 2) {
      // Draw a dash line
      canvas.drawLine(Offset(centerX, centerY - startY),
          Offset(centerX, centerY - startY - dashSpace), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) {
    return true;
  }
}
