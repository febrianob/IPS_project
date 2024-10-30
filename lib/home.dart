import 'package:flutter/material.dart';
import 'package:bottom_bar/bottom_bar.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rolling_switch/rolling_switch.dart';
import 'package:get/get.dart';
import 'package:ips_project/ble_data.dart';
import 'dart:math';
import 'package:ips_project/animation_paint.dart';
import 'package:ips_project/position_history.dart';

class BLEProjectPage extends StatefulWidget {
  const BLEProjectPage({super.key});

  @override
  State<BLEProjectPage> createState() => _BLEProjectPageState();
}

class _BLEProjectPageState extends State<BLEProjectPage> {
  var bleController = Get.put(BLEResult());

  // Page Controller
  int _currentBody = 0;
  final _pageController = PageController();
  TextEditingController textController = TextEditingController();

  // Flutter Blue instance
  FlutterBlue flutterBlue = FlutterBlue.instance;
  bool isScanning = false;

  // BLE value
  String deviceName = '';
  String macAddress = '';
  String rssi = '';
  String serviceUUID = '';
  String manuFactureData = '';
  String tp = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('IPS PROJECT'),
          backgroundColor: const Color.fromARGB(255, 204, 202, 202),
          actions: [
            IconButton(
              icon: Icon(isScanning ? Icons.stop : Icons.bluetooth),
              onPressed: () {
                toggleState();
              },
            )
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            isScanning
                ? pageBLEScan()
                : Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/LOGO2.png',
                              height: 150,
                              width: 150,
                            ),
                            const SizedBox(
                                height:
                                    10), // Tambahkan jarak antara gambar dan teks
                            const Text(
                              'Silahkan Menekan Search Untuk Memulai Scanning',
                              style: TextStyle(fontSize: 14), // Ukuran teks
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: IconButton(
                          icon: Icon(isScanning ? Icons.stop : Icons.search),
                          iconSize: 50, // Ukuran ikon
                          onPressed: () {
                            toggleState();
                          },
                        ),
                      ),
                    ],
                  ),
            pageBLESelected(),
            const CircleRoute(),            
            PositionHistoryPage(),
            Container(color: Colors.orange),
          ],
        ),
        bottomNavigationBar: BottomBar(
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          backgroundColor: const Color.fromARGB(255, 204, 202, 202),
          selectedIndex: _currentBody,
          onTap: (int index) {
            _pageController.jumpToPage(index);
            setState(() => _currentBody = index);
          },
          items: <BottomBarItem>[
            BottomBarItem(
              icon: const Icon(Icons.bluetooth),
              title: const Text('BLE Scan'),
              activeColor: Colors.blue,
              activeTitleColor: Colors.blue.shade600,
            ),
            BottomBarItem(
              icon: const Icon(Icons.bar_chart),
              title: const Text('Beacon'),
              backgroundColorOpacity: 0.1,
              activeColor: Colors.blueAccent.shade700,
            ),
            BottomBarItem(
              icon: const Icon(Icons.place),
              title: const Text('Indoor Map'),
              backgroundColorOpacity: 0.1,
              activeColor: Colors.redAccent.shade700,
            ),
            BottomBarItem(
              icon: const Icon(Icons.history),
              title: const Text('History'),
              backgroundColorOpacity: 0.1,
              activeColor: Colors.purpleAccent.shade700,
            ),
          ],
        ));
  }

  /* start or stop callback */
  void toggleState() {
    isScanning = !isScanning;
    if (isScanning) {
      flutterBlue.startScan(scanMode: ScanMode.balanced, allowDuplicates: true);
      scan();
    } else {
      flutterBlue.stopScan();
      bleController.initBLEList();
    }
    setState(() {});
  }

  final List<String> knownBeaconAddresses = [
    'D4:D4:DA:CF:75:A6', // Beacon 1
    'D4:D4:DA:CF:A2:02', // Beacon 2
    '40:22:D8:60:C0:8E', // Beacon 3
  ];

  /* Scan */
   void scan() async {
    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
      // do something with scan results
      bleController.scanResultList = results.cast<ScanResult>();
       for (ScanResult r in results) {
        // Perbarui RSSI untuk setiap beacon yang dikenali
        if (knownBeaconAddresses.contains(r.device.id.id)) {
          bleController.updateBeaconRSSI(r.device.id.id, r.rssi);

          // Auto-connect to known beacons
          autoConnectToBeacon(r);
        }
      }
      // update state
      setState(() {});
    });
  }

/* Auto-connect to known beacons */
  void autoConnectToBeacon(ScanResult r) async {
    int index = bleController.macAddressList.indexOf(r.device.id.id);
    if (index != -1 && !bleController.flagList[index]) {
      // If the device is not already connected, connect to it
      bleController.updateFlagList(flag: true, index: index);
      bleController.updateselectedDeviceIdxList();
      
      // Attempt to connect
      try {
        await r.device.connect();
        // ignore: avoid_print
        print('Connected to ${r.device.name}');
        // You might want to perform additional actions after successful connection
      } catch (e) {
        // ignore: avoid_print
        print('Failed to connect to ${r.device.name}: $e');
      }
    }
  }

  /* BLE Scan Page */
  Center pageBLEScan() => Center(
        child:
            /* listview */
            ListView.separated(
                itemCount: bleController.scanResultList.length,
                itemBuilder: (context, index) =>
                    widgetBLEList(index, bleController.scanResultList[index]),
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider()),
      );

  /* Selected BLE Scan Page */
  Center pageBLESelected() => Center(
        child:
            /* listview */
            ListView.separated(
                itemCount: bleController.selectedDeviceIdxList.length,
                itemBuilder: (context, index) => widgetSelectedBLEList(
                      index,
                      bleController.scanResultList[
                          bleController.selectedDeviceIdxList[index]],
                    ),
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider()),
      );

  /* listview widget for ble data */
  Widget widgetSelectedBLEList(int currentIdx, ScanResult r) {
    toStringBLE(r);

    bleController.updateBLEList(
        deviceName: deviceName,
        macAddress: macAddress,
        rssi: rssi,
        serviceUUID: serviceUUID,
        manuFactureData: manuFactureData,
        tp: tp);
    double constantN = bleController.selectedConstNList[currentIdx].toDouble();
    double alpha = bleController.selectedRSSI_1mList[currentIdx].toDouble();
    num distance = logDistancePathLoss(rssi, alpha, constantN);
    bleController.selectedDistanceList[currentIdx] = distance;
    String constN = bleController.selectedConstNList[currentIdx].toString();
    String rssi1m = bleController.selectedRSSI_1mList[currentIdx].toString();
    return ExpansionTile(
      //leading: leading(r),
      title: Text('$deviceName ($macAddress)',
          style: const TextStyle(color: Colors.black)),
      subtitle: Text('\n N : $constN\n RSSI at 1m : ${rssi1m}dBm',
          style: const TextStyle(color: Colors.blueAccent)),
      trailing: Text('${distance.toStringAsPrecision(3)}m\n',
          style: const TextStyle(color: Colors.black)),
      children: <Widget>[
        ListTile(
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: SpinBox(
                      min: 2.0,
                      max: 4.0,
                      value: bleController.selectedConstNList[currentIdx]
                          .toDouble(),
                      decimals: 1,
                      step: 0.1,
                      onChanged: (value) =>
                          bleController.selectedConstNList[currentIdx] = value,
                      decoration: const InputDecoration(
                          labelText:
                              'N (Constant depends on the Environmental factor)'),
                    )),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SpinBox(
                    min: -100,
                    max: -30,
                    value: bleController.selectedRSSI_1mList[currentIdx]
                        .toDouble(),
                    decimals: 0,
                    step: 1,
                    onChanged: (value) => bleController
                        .selectedRSSI_1mList[currentIdx] = value.toInt(),
                    decoration: const InputDecoration(labelText: 'RSSI at 1m'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SpinBox(
                    min: 0.0,
                    max: 20.0,
                    value: bleController.selectedCenterXList[currentIdx]
                        .toDouble(),
                    decimals: 1,
                    step: 0.1,
                    onChanged: (value) =>
                        bleController.selectedCenterXList[currentIdx] = value,
                    decoration:
                        const InputDecoration(labelText: 'Center X [m]'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SpinBox(
                    min: 0.0,
                    max: 20.0,
                    value: bleController.selectedCenterYList[currentIdx]
                        .toDouble(),
                    decimals: 1,
                    step: 0.1,
                    onChanged: (value) =>
                        bleController.selectedCenterYList[currentIdx] = value,
                    decoration:
                        const InputDecoration(labelText: 'Center Y [m]'),
                  ),
                ),
              ]),
        )
      ],
    );
  }

  /* listview widget for ble data */
  Widget widgetBLEList(int index, ScanResult r) {
    toStringBLE(r);

    bleController.updateBLEList(
        deviceName: deviceName,
        macAddress: macAddress,
        rssi: rssi,
        serviceUUID: serviceUUID,
        manuFactureData: manuFactureData,
        tp: tp);

    serviceUUID.isEmpty ? serviceUUID = 'null' : serviceUUID;
    manuFactureData.isEmpty ? manuFactureData = 'null' : manuFactureData;
    bool switchFlag = bleController.flagList[index];
    switchFlag ? deviceName = '$deviceName (Connect)' : deviceName;

    bleController.updateselectedDeviceIdxList();

    return ExpansionTile(
      leading: leading(r),
      title: Text(deviceName,
          style:
              TextStyle(color: switchFlag ? Colors.lightBlue : Colors.black)),
      subtitle: Text(macAddress,
          style:
              TextStyle(color: switchFlag ? Colors.lightBlue : Colors.black)),
      trailing: Text(rssi,
          style:
              TextStyle(color: switchFlag ? Colors.lightBlue : Colors.black)),
      children: <Widget>[
        ListTile(
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'UUID : $serviceUUID\nManufacture data : $manuFactureData\nTX power : ${tp == 'null' ? tp : '${tp}dBm'}',
                  style: const TextStyle(fontSize: 10),
                ),
                const Padding(padding: EdgeInsets.all(2)),
                Row(
                  children: [
                    const Spacer(),
                    RollingSwitch.icon(
                      width: 155,
                      height: 50,
                      initialState: bleController.flagList[index],
                      onChanged: (bool state) {
                        bleController.updateFlagList(flag: state, index: index);
                      },
                      rollingInfoRight: const RollingIconInfo(
                        icon: Icons.flag,
                        text: Text(
                          'Connect',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      rollingInfoLeft: const RollingIconInfo(
                        icon: Icons.check,
                        backgroundColor: Colors.grey,
                        text: Text('Disconnect'),
                      ),
                    )
                  ],
                ),
              ]),
        )
      ],
    );
  }

  /* string */
  void toStringBLE(ScanResult r) {
    deviceName = deviceNameCheck(r);
    macAddress = r.device.id.id;
    rssi = r.rssi.toString();

    serviceUUID = r.advertisementData.serviceUuids
        .toString()
        .toString()
        .replaceAll('[', '')
        .replaceAll(']', '');
    manuFactureData = r.advertisementData.manufacturerData
        .toString()
        .replaceAll('{', '')
        .replaceAll('}', '');
    tp = r.advertisementData.txPowerLevel.toString();
  }

  /* device name check */
  String deviceNameCheck(ScanResult r) {
    String name;

    if (r.device.name.isNotEmpty) {
      // Is device.name
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // Is advertisementData.localName
      name = r.advertisementData.localName;
    } else {
      // null
      name = 'N/A';
    }
    return name;
  }

  /* BLE icon widget */
  Widget leading(ScanResult r) => const CircleAvatar(
        backgroundColor: Colors.cyan,
        child: Icon(
          Icons.bluetooth,
          color: Colors.white,
        ),
      );

  /* log distance path loss model */
  num logDistancePathLoss(String rssi, double alpha, double constantN) =>
      pow(10.0, ((alpha - double.parse(rssi)) / (10 * constantN)));
}
