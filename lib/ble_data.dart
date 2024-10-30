import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:ips_project/rssi_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* Provider class */
class BLEResult extends GetxController {
  // Raw BLE Scan Result
  List<ScanResult> scanResultList = [];

  // BLE advertising pacekt format
  List<String> deviceNameList = [];
  List<String> macAddressList = [];
  List<String> rssiList = [];

  List<String> txPowerLevelList = [];
  List<String> manuFacturerDataList = [];
  List<String> serviceUuidsList = [];

  // BTN flag
  List<bool> flagList = [];

  // selected beacon param for distance
  List<int> selectedDeviceIdxList = [];
  List<String> selectedDeviceNameList = [];
  List<num> selectedConstNList = [];
  List<int> selectedRSSI_1mList = [];
  List<double> selectedCenterXList = [];
  List<double> selectedCenterYList = [];
  List<num> selectedDistanceList = [];

  // max distance
  double maxDistance = 12.0;

  // distance value
  List<double> distanceList = [];

  RxDouble currentX = 0.0.obs;
  RxDouble currentY = 0.0.obs;

  RxList<Map<String, dynamic>> positionHistory = <Map<String, dynamic>>[].obs;
  final int maxHistoryLength = 10;
  final Map<String, List<Map<String, dynamic>>> uniquePositions = {};
  void updateCurrentPosition(double x, double y) {
    currentX.value = x;
    currentY.value = y;

    String positionKey = "${x.toStringAsFixed(2)},${y.toStringAsFixed(2)}";

    if (!uniquePositions.containsKey(positionKey)) {
      uniquePositions[positionKey] = [];
    }
    // Tambahkan posisi baru ke riwayat dengan timestamp
    Map<String, dynamic> newPosition = {
      'x': x,
      'y': y,
      'timestamp': DateTime.now().toIso8601String(),
      'beacon1RSSI': beaconRSSI['D4:D4:DA:CF:75:A6'],
      'beacon2RSSI': beaconRSSI['D4:D4:DA:CF:A2:02'],
      'beacon3RSSI': beaconRSSI['40:22:D8:60:C0:8E'],
    };

    uniquePositions[positionKey]!.insert(0, newPosition);
    if (uniquePositions[positionKey]!.length > maxHistoryLength) {
      uniquePositions[positionKey]!.removeLast();
    }

    // Update positionHistory dengan data terbaru
    positionHistory.value = uniquePositions.values.expand((i) => i).toList();
    positionHistory.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    _savePositionHistory();
    update();
  }

  RxMap<String, int> beaconRSSI = <String, int>{}.obs;
  void updateBeaconRSSI(String macAddress, int rssi) {
    beaconRSSI[macAddress] = rssi;
    update();
  }

  // Fungsi untuk menyimpan riwayat posisi ke penyimpanan lokal
  Future<void> _savePositionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedHistory = json.encode(positionHistory.toList());
    await prefs.setString('position_history', encodedHistory);
  }

  // Fungsi untuk memuat riwayat posisi dari penyimpanan lokal
  Future<void> loadPositionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedHistory = prefs.getString('position_history');
    if (encodedHistory != null) {
      final List<dynamic> decodedHistory = json.decode(encodedHistory);
      positionHistory.value = decodedHistory.cast<Map<String, dynamic>>();
    }
  }

  // Fungsi untuk mendapatkan posisi terakhir
  Map<String, double> getLastPosition() {
    if (positionHistory.isNotEmpty) {
      final lastPosition = positionHistory.last;
      return {
        'x': lastPosition['x'],
        'y': lastPosition['y'],
      };
    }
    return {'x': 0.0, 'y': 0.0};
  }

  // Fungsi untuk membersihkan riwayat posisi
  void clearPositionHistory() {
    positionHistory.clear();
    _savePositionHistory();
    update();
  }

  void initBLEList() {
    scanResultList = [];

    deviceNameList = [];
    macAddressList = [];
    rssiList = [];
    txPowerLevelList = [];
    manuFacturerDataList = [];
    serviceUuidsList = [];
    flagList = [];
    selectedDeviceIdxList = [];
    selectedDeviceNameList = [];
    selectedConstNList = [];
    selectedRSSI_1mList = [];
    selectedCenterXList = [];
    selectedCenterYList = [];
    selectedDistanceList = [];
  }

  final MovingAverageFilter _rssiFilter = MovingAverageFilter(5);

  void updateBLEList({
    required String deviceName,
    required String macAddress,
    required String rssi,
    required String serviceUUID,
    required String manuFactureData,
    required String tp,
  }) {
    double filteredRSSI = _rssiFilter.filter(macAddress, double.parse(rssi));

    if (macAddressList.contains(macAddress)) {
      rssiList[macAddressList.indexOf(macAddress)] = filteredRSSI.toString();
    } else {
      deviceNameList.add(deviceName);
      macAddressList.add(macAddress);
      rssiList.add(filteredRSSI.toString());
      serviceUuidsList.add(serviceUUID);
      manuFacturerDataList.add(manuFactureData);
      txPowerLevelList.add(tp);
      flagList.add(false);
    }
    update();
  }

  void updateFlagList({required bool flag, required int index}) {
    flagList[index] = flag;
    update();
  }

  final Map<String, List<double>> _defaultBeaconPositions = {
    'D4:D4:DA:CF:75:A6': [4.0, 12.0], // MAC Address untuk Beacon 1
    'D4:D4:DA:CF:A2:02': [0.0, 6.0], // MAC Address untuk Beacon 2
    '40:22:D8:60:C0:8E': [8.0, 6.0], // MAC Address untuk Beacon 3
  };

  void updateselectedDeviceIdxList() {
    flagList.forEachIndexed((index, element) {
      if (element == true) {
        if (!selectedDeviceIdxList.contains(index)) {
          String macAddress = macAddressList[index];
          selectedDeviceIdxList.add(index);
          selectedDeviceNameList.add(deviceNameList[index]);
          selectedConstNList.add(2.0);
          selectedRSSI_1mList.add(-59);

          // Gunakan posisi default jika tersedia untuk MAC Address ini
          if (_defaultBeaconPositions.containsKey(macAddress)) {
            List<double> position = _defaultBeaconPositions[macAddress]!;
            selectedCenterXList.add(position[0]);
            selectedCenterYList.add(position[1]);
          } else {
            // Jika tidak ada posisi default, gunakan posisi umum
            selectedCenterXList.add(4.0);
            selectedCenterYList.add(6.0);
          }

          selectedDistanceList.add(0.0);
        }
      } else {
        int idx = selectedDeviceIdxList.indexOf(index);
        if (idx != -1) {
          selectedDeviceIdxList.remove(index);
          selectedDeviceNameList.removeAt(idx);
          selectedConstNList.removeAt(idx);
          selectedRSSI_1mList.removeAt(idx);
          selectedCenterXList.removeAt(idx);
          selectedCenterYList.removeAt(idx);
          selectedDistanceList.removeAt(idx);
        }
      }
    });
    update();
  }

  // Tambahkan fungsi untuk menambah atau memperbarui posisi beacon
  void updateBeaconPosition(String macAddress, double x, double y) {
    _defaultBeaconPositions[macAddress] = [x, y];

    // Jika beacon sudah terpilih, perbarui posisinya
    int idx = macAddressList.indexOf(macAddress);
    if (idx != -1 && selectedDeviceIdxList.contains(idx)) {
      int selectedIdx = selectedDeviceIdxList.indexOf(idx);
      selectedCenterXList[selectedIdx] = x;
      selectedCenterYList[selectedIdx] = y;
    }

    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadPositionHistory();
  }
}
