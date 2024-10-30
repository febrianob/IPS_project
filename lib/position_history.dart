import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ips_project/ble_data.dart';
import 'package:ips_project/grid/grid_widget.dart';

class PositionHistoryPage extends StatelessWidget {
  // ignore: use_super_parameters
  PositionHistoryPage({Key? key}) : super(key: key);

  final BLEResult bleController = Get.find<BLEResult>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Expanded(
              flex: 1,
              child: GridWidget(
                HistoryPainter(bleController.positionHistory),
              ),
            ),
            Expanded(
              flex: 1,
              child: bleController.positionHistory.isEmpty
              ? const Center(child: Text('History posisi kosong'))
              :ListView.builder(
                itemCount: bleController.positionHistory.length,
                itemBuilder: (context, index) {
                  final position = bleController.positionHistory[index];
                  return ListTile(
                    title: Text(
                        'Position: (${position['x'].toStringAsFixed(2)}, ${position['y'].toStringAsFixed(2)})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Time: ${position['timestamp']}'),
                    Text('Beacon 1 RSSI: ${position['beacon1RSSI'] ?? 'N/A'}'),
                    Text('Beacon 2 RSSI: ${position['beacon2RSSI'] ?? 'N/A'}'),
                    Text('Beacon 3 RSSI: ${position['beacon3RSSI'] ?? 'N/A'}'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ElevatedButton(
          onPressed: () => bleController.clearPositionHistory(),
          child: const Text('Clear History'),
        ),
      ],
      )
    );
  }
}

class HistoryPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;

  HistoryPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (var position in history) {
      canvas.drawCircle(
        Offset(position['x'] * 100, position['y'] * 100),
        3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
