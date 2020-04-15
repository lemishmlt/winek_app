import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:battery/battery.dart';
import 'package:map_controller/map_controller.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/rendering.dart';


const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
 Firestore _firestore=Firestore.instance;


void main() => runApp(MyApp());


class MyApp extends StatelessWidget{
  
  @override
  Widget build(BuildContext context) {
   return ChangeNotifierProvider<DeviceInformationService>(
       create:(BuildContext context) => DeviceInformationService(),
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Maps',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter Map Home Page'),
      ),  
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class DeviceInformationService extends ChangeNotifier{
  bool _broadcastBattery = false;
  Battery _battery = Battery();
  int  batteryLvl=100;
  
 Future broadcastBatteryLevel() async {
    _broadcastBattery = true;
    while (_broadcastBattery) {
      batteryLvl = await _battery.batteryLevel;
      notifyListeners();
       _firestore.collection('battery').document('lemis').updateData({'name': 'lemis', 'baterie': batteryLvl});
      await Future.delayed(Duration(seconds: 5));
    }
  }

  void stopBroadcast() {
   _broadcastBattery = false;
  }

}

class _MyHomePageState extends State<MyHomePage> {

  GoogleMapController _controller;
 
 Geoflutterfire geo=Geoflutterfire();
 StreamSubscription<List<DocumentSnapshot>> stream;
 Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Marker _marker;
  MarkerId id;

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(36.7135, 4.0473),
    zoom: 10.0,
    tilt: CAMERA_TILT,
   bearing: CAMERA_BEARING,
  );


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        myLocationEnabled: true,
        compassEnabled : true,
        indoorViewEnabled: true,
        tiltGesturesEnabled: false,
        initialCameraPosition: initialLocation,
        onMapCreated:_onMapCreated,
        markers: Set<Marker>.of(markers.values),
        ),
       // body:Text('${Provider.of<DeviceInformationService>(context).batteryLvl}'),
      /* body:StreamBuilder(
         stream:_firestore.collection('battery').document('lemis').snapshots(),        
         builder:(context,snapshot){
           if(!snapshot.hasData)
           return Text('Loading data ... please wait');
           return Text('Le niveau de batterie est : ${snapshot.data['baterie']}');
         } ,
         ),*/
       

      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.location_searching),
          onPressed:()
          {   getCurrentLocation();
            /* var btr=Provider.of<DeviceInformationService>(context).batteryLvl;
            _firestore.collection('battery').document('lemis').setData({'name': 'lemis', 'baterie': btr});
            Provider.of<DeviceInformationService>(context).broadcastBatteryLevel();*/

           }
           ),    
    );
    
  }

    void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

   void getCurrentLocation() async {   
     var geolocator = Geolocator();
     var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
     var collectionReference = _firestore.collection('locations');

     GeoFirePoint destination = geo.point(latitude: 36.7525000, longitude:  3.0419700);
  
    LatLng rima = new LatLng(36.5927, 2.2538);
   LatLng hiba= new LatLng(36.4334, 3.1058);
   LatLng soumeya = new LatLng(36.7525000, 3.0419700);

      GeoFirePoint geoFPointr = geo.point(latitude: rima.latitude, longitude: rima.longitude);
    _firestore
        .collection('locations').document('rima')
        .setData({'name': 'rima', 'position': geoFPointr.data});

          GeoFirePoint geoFPointh = geo.point(latitude: hiba.latitude, longitude: hiba.longitude);
    _firestore
        .collection('locations').document('hiba')
        .setData({'name': 'hiba', 'position': geoFPointh.data});

          GeoFirePoint geoFPoints = geo.point(latitude: soumeya.latitude, longitude: soumeya.longitude);
    _firestore
        .collection('locations').document('soumeya')
        .setData({'name': 'soumeya', 'position': geoFPoints.data});
    
     StreamSubscription<Position> positionStream = geolocator.getPositionStream(locationOptions).listen(
     (Position position) {
         
        var speed=position.speed;
        print('la vitesseeeeeeeeeeee');
        print(speed);
            LatLng latLng = new LatLng(position.latitude, position.longitude);
            CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(latLng, 12);
            _controller.animateCamera(cameraUpdate);
            
            GeoFirePoint geoFirePoint = geo.point(latitude: position.latitude, longitude: position.longitude);
           _firestore.collection('locations').document('lemis').setData({'name': 'Lemis', 'position': geoFirePoint.data});
                 double radius = 50;
      String field = 'position';
      stream = geo.collection(collectionRef: collectionReference)
                                        .within(center: destination, radius: radius, field: field).listen(_updateMarkers);
    });
                    
  }
  
 void _updateMarkers(List<DocumentSnapshot> documentList) async{
    markers.remove('lemis');
   Position position=await Geolocator().getCurrentPosition(desiredAccuracy:LocationAccuracy.high);
    documentList.forEach((DocumentSnapshot document) async{
      GeoPoint point = document.data['position']['geopoint'];
      double distance=await Geolocator().distanceBetween(point.latitude, point.longitude,position.latitude, position.longitude);
      _addMarker(point.latitude, point.longitude,distance);
    });
  }

  void _addMarker(double lat, double lng,double distance) {
   
     MarkerId id = MarkerId(lat.toString() + lng.toString());
    // id=MarkerId('lemis');
      _marker = Marker(
      markerId: id,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(title: 'distance', snippet: '$distance'),
    );
    setState(() {
      markers[id] = _marker;
    });
  }
}

/*const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
 Firestore _firestore=Firestore.instance;


void main() => runApp(MyApp());


class MyApp extends StatelessWidget{
  
  @override
  Widget build(BuildContext context) {
   return ChangeNotifierProvider<DeviceInformationService>(
       create:(BuildContext context) => DeviceInformationService(),
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Maps',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter Map Home Page'),
      ),  
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class DeviceInformationService extends ChangeNotifier{
  bool _broadcastBattery = false;
  Battery _battery = Battery();
  int  batteryLvl=100;
  
 Future broadcastBatteryLevel() async {
    _broadcastBattery = true;
    while (_broadcastBattery) {
      batteryLvl = await _battery.batteryLevel;
      notifyListeners();
       _firestore.collection('battery').document('lemis').updateData({'name': 'lemis', 'baterie': batteryLvl});
      await Future.delayed(Duration(seconds: 5));
    }
  }

  void stopBroadcast() {
   _broadcastBattery = false;
  }

}

class _MyHomePageState extends State<MyHomePage> {

  GoogleMapController _controller;
 
 Geoflutterfire geo=Geoflutterfire();
 StreamSubscription<List<DocumentSnapshot>> stream;
 Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Marker _marker;
  MarkerId id;
  var speed;
  var distanced;

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(36.7135, 4.0473),
    zoom: 10.0,
    tilt: CAMERA_TILT,
   bearing: CAMERA_BEARING,
  );


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        myLocationEnabled: true,
        compassEnabled : true,
        indoorViewEnabled: true,
        tiltGesturesEnabled: false,
        initialCameraPosition: initialLocation,
        onMapCreated:_onMapCreated,
        markers: Set<Marker>.of(markers.values),
        ),
        /*body:Center(child: RichText( 
          text: TextSpan(
            style:TextStyle(color:Color(0xFF3b466b),fontSize:25,fontFamily:'Montserrat'),
            children:<TextSpan>[
              TextSpan(text:" voici la distance de l'utilisateur par rapport a la destination   "),
              TextSpan(text:'$distanced',style:TextStyle(color:Color(0xFF389490),fontSize:25,fontFamily:'Montserrat',fontWeight:FontWeight.bold)), 
              TextSpan(text:' m'),
              TextSpan(text:'\n\n et voici sa vitesse   '),
              TextSpan(text:'$speed',style:TextStyle(color:Color(0xFF389490),fontSize:25,fontFamily:'Montserrat',fontWeight:FontWeight.bold)),
              TextSpan(text:' m/s'), 
            ]
          ),
        ),
        ),*/
       /*body:StreamBuilder(
         stream:_firestore.collection('battery').document('lemis').snapshots(),        
         builder:(context,snapshot){
           if(!snapshot.hasData)
           return Center(child: Text('Loading data ... please wait'));
           return Center(child: RichText(
               text: TextSpan(
            style:TextStyle(color:Color(0xFF3b466b),fontSize:25,fontFamily:'Montserrat'),
            children:<TextSpan>[
             TextSpan(text:'Le niveau de batterie est:'),
             TextSpan(text:'  ${snapshot.data['baterie']}%',style:TextStyle(color:Color(0xFF389490),fontSize:25,fontFamily:'Montserrat',fontWeight:FontWeight.bold)), 
            ]),
           ),
           );
         } ,
         ),*/
      

      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.location_searching),
          onPressed:()
          {   getCurrentLocation();
             /*var btr=Provider.of<DeviceInformationService>(context).batteryLvl;
            _firestore.collection('battery').document('lemis').setData({'name': 'lemis', 'baterie': btr});
            Provider.of<DeviceInformationService>(context).broadcastBatteryLevel();*/

           }
           ),    
    );
    
  }

    void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

   void getCurrentLocation() async {   
     var geolocator = Geolocator();
     var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
     var collectionReference = _firestore.collection('locations');

     GeoFirePoint destination = geo.point(latitude: 36.7525000, longitude:  3.0419700);
   LatLng rima = new LatLng(36.5927, 2.2538);
   LatLng hiba= new LatLng(36.4334, 3.1058);
   LatLng soumeya = new LatLng(36.7525000, 3.0419700);

      GeoFirePoint geoFPointr = geo.point(latitude: rima.latitude, longitude: rima.longitude);
    _firestore
        .collection('locations').document('rima')
        .setData({'name': 'rima', 'position': geoFPointr.data});

          GeoFirePoint geoFPointh = geo.point(latitude: hiba.latitude, longitude: hiba.longitude);
    _firestore
        .collection('locations').document('hiba')
        .setData({'name': 'hiba', 'position': geoFPointh.data});

          GeoFirePoint geoFPoints = geo.point(latitude: soumeya.latitude, longitude: soumeya.longitude);
    _firestore
        .collection('locations').document('soumeya')
        .setData({'name': 'soumeya', 'position': geoFPoints.data});

      LatLng dest = new LatLng(36.3650000,6.6147200);
     StreamSubscription<Position> positionStream = geolocator.getPositionStream(locationOptions).listen(
     (Position position)  {
         
         //speed=position.speed;
              // getDistance(position,dest);
             LatLng latLng = new LatLng(position.latitude, position.longitude);
            CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(latLng, 12);
            _controller.animateCamera(cameraUpdate);
            
            GeoFirePoint geoFirePoint = geo.point(latitude: position.latitude, longitude: position.longitude);
           _firestore.collection('locations').document('lemis').setData({'name': 'Lemis', 'position': geoFirePoint.data});
                 double radius = 50;
      String field = 'position';
      stream = geo.collection(collectionRef: collectionReference)
                                        .within(center: destination, radius: radius, field: field).listen(_updateMarkers);
    });
                    
  }

  void getDistance(Position position, LatLng dest)async{
    distanced= await Geolocator().distanceBetween(position.latitude, position.longitude,dest.latitude, dest.longitude);
  }
  
 void _updateMarkers(List<DocumentSnapshot> documentList) async{
    markers.remove('lemis');
    
   Position position=await Geolocator().getCurrentPosition(desiredAccuracy:LocationAccuracy.high);
    documentList.forEach((DocumentSnapshot document) async{
      GeoPoint point = document.data['position']['geopoint'];
      _addMarker(point.latitude, point.longitude);
    });
  }

  void _addMarker(double lat, double lng) {
   
     // MarkerId id = MarkerId(lat.toString() + lng.toString());
     id=MarkerId('lemis');
      _marker = Marker(
      markerId: id,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      //infoWindow: InfoWindow(title: 'distance', snippet: '$distance'),
    );
    setState(() {
      markers[id] = _marker;
    });
  }
}*/