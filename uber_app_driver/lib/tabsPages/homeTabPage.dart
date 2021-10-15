import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_app_driver/Assistarts/assistantMethods.dart';
import 'package:uber_app_driver/Models/deivers.dart';
import 'package:uber_app_driver/Notifications/pushNotificationService.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/main.dart';
import 'package:uber_app_driver/shared/components/components.dart';

class HomeTabPage extends StatefulWidget {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  @override
  _HomeTabPageState createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();

  late GoogleMapController newGoogleMapController;
  MapType _currentMapType = MapType.normal;

  Geolocator geoLocator = Geolocator();

  bool isOnlone = false;

  @override
  void initState() {
    super.initState();
    getCurrentDriverInfo();
  }

  getRideType() {
    drivesrRef
        .child(currrentFirebaseUser!.uid)
        .child("car_details")
        .child("type")
        .once()
        .then((DataSnapshot snapshot) {
      setState(() {
        rideType = snapshot.value.toString();
      });
    });
  }

  void getRatings() {
    // update ratings
    drivesrRef
        .child(currrentFirebaseUser!.uid)
        .child("ratings")
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        double ratings = double.parse(dataSnapshot.value.toString());
        starCounter = ratings;
        if (starCounter <= 1.5) {
          title = "Very Bad";
        } else if (starCounter <= 2.5) {
          title = "Bad";
        } else if (starCounter <= 3.5) {
          title = "Good";
        } else if (starCounter <= 4.5) {
          title = "Very Good";
        } else if (starCounter <= 5) {
          title = "Excellent";
        }
        setState(() {});
      }
    });
  }

  bool locatePositionChange = false;
  void locatePosition() async {
    locatePositionChange = true;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 14.0);

    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    //
    locatePositionChange = false;
  }

  void getCurrentDriverInfo() async {
    currrentFirebaseUser = FirebaseAuth.instance.currentUser;

    drivesrRef
        .child(currrentFirebaseUser!.uid)
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        driversInformation = Drivers.fromSnapshot(dataSnapshot);
      }
    });

    PushNotificationService pushNotificationService = PushNotificationService();
    pushNotificationService.initialize(context);
    pushNotificationService.getToken();

    AssistantMethods.retrieveHistoryInfo(context);

    getRatings();
    getRideType();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            myLocationButtonEnabled: true,
            initialCameraPosition: HomeTabPage._kGooglePlex,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              locatePosition();
            },
          ),

          // online offline driver Container
          Container(
            height: 140.0,
            width: double.infinity,
            color: Colors.black54,
          ),
          Positioned(
            top: 60.0,
            left: 0.0,
            right: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BuildButton(
                  color: isOnlone ? Colors.green : Colors.black,
                  onPressed: () {
                    print("BuildButtonisOnlone");
                    print("$isOnlone");
                    print("BuildButtonisOnlone");

                    if (!isOnlone) {
                      makeDriverOnlineNow();
                      getLocationLiveUpdates();
                      setState(() {
                        isOnlone = true;
                      });
                    } else {
                      makeDriverOfflineNow();
                      setState(() {
                        isOnlone = false;
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        isOnlone ? "Online Now" : " Offline Now - Go Online ",
                        style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: "Brand Bold",
                            color: Colors.white),
                      ),
                      Icon(Icons.phone_android_outlined, color: Colors.white)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void makeDriverOnlineNow() async {
    // ignore: unused_local_variable
    print("makeDriverOnlineNow");
    Geofire.initialize("availableDrivers");

    Geofire.setLocation(currrentFirebaseUser!.uid, currentPosition.latitude,
        currentPosition.longitude);

    ridetripRequestRef!.set("searching");
    ridetripRequestRef!.onValue.listen((event) {});
  }

  void getLocationLiveUpdates() {
    print("getLocationLiveUpdates");
    homeTabPageStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      currentPosition = position;

      if (isOnlone) {
        Geofire.setLocation(
            currrentFirebaseUser!.uid, position.latitude, position.longitude);
      }

      LatLng latLng = LatLng(position.latitude, position.longitude);

      newGoogleMapController.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

  void makeDriverOfflineNow() {
    Geofire.removeLocation(currrentFirebaseUser!.uid);
    ridetripRequestRef!.onDisconnect();
    ridetripRequestRef!.remove();
    // ridetripRequestRef = null;

    setState(() {
      isOnlone = false;
    });
  }
}
