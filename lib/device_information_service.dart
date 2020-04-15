import 'dart:async';
import 'package:battery/battery.dart';
import 'package:flutter/cupertino.dart';
import 'package:winek_app/main.dart';


/*class DeviceInformationService {
  bool _broadcastBattery = false;
  Battery _battery = Battery();
  

 Stream<BatteryInformation> get batteryLevel => _batteryLevelController.stream;
 StreamController<BatteryInformation> _batteryLevelController =StreamController<BatteryInformation>();
  
 Future _broadcastBatteryLevel() async {
    _broadcastBattery = true;
    while (_broadcastBattery) {
     var  batteryLevel = await _battery.batteryLevel;
      _batteryLevelController.add(BatteryInformation(batteryLevel));
      await Future.delayed(Duration(seconds: 5));
    }
  }

  void stopBroadcast() {
    _broadcastBattery = false;
  }

}*/

class DeviceInformationService extends ChangeNotifier{
  bool _broadcastBattery = false;
  Battery _battery = Battery();
  int  batteryLvl=100;
  
 Future broadcastBatteryLevel() async {
    _broadcastBattery = true;
    while (_broadcastBattery) {
      batteryLvl = await _battery.batteryLevel;
      notifyListeners();
       
      await Future.delayed(Duration(seconds: 5));
    }
  }

  void stopBroadcast() {
   _broadcastBattery = false;
  }

}
