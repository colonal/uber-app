import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_app_driver/Models/rideDetails.dart';
import 'package:uber_app_driver/Notifications/nitificationDialog.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/main.dart';

class PushNotificationService {
  BuildContext? mainContext;
  Future<void> backgroundMassage(RemoteMessage message, context) async {
    print("\n\nbackgroundMassage\n\n");
    print(message.data.toString());
    retrieveRideRequestInfo(getRideRequestId(message.data), context);
  }

  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message");
    await Firebase.initializeApp();
  }

  Future initialize(context) async {
    FirebaseMessaging.onMessage.listen((message) {
      print("\n\nonMessage\n\n");
      print(message.data.toString());

      retrieveRideRequestInfo(getRideRequestId(message.data), context);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("\n\nonMessageOpenedApp\n\n");
      print(message.data.toString());
      retrieveRideRequestInfo(getRideRequestId(message.data), context);
    });

    mainContext = context;
  }

  Future<String> getToken() async {
    String token = await FirebaseMessaging.instance.getToken() ?? " ";
    print("token: $token");
    drivesrRef.child(currrentFirebaseUser!.uid).child("token").set(token);

    FirebaseMessaging.instance.subscribeToTopic("alldrivers");
    FirebaseMessaging.instance.subscribeToTopic("allusers");

    return "";
  }

  String getRideRequestId(Map<String, dynamic> message) {
    String rideRequestId = "";
    if (Platform.isAndroid) {
      rideRequestId = message["ride_request_id"];
      print("This is Ride Request Id:: $rideRequestId");
    } else {
      rideRequestId = message["ride_request_id"];
      print("This is Ride Request Id:: $rideRequestId");
    }

    return rideRequestId;
  }

  void retrieveRideRequestInfo(String rideRequestId, BuildContext context) {
    print("retrieveRideRequestInfo::$rideRequestId");
    newRequestsRef
        .child(rideRequestId)
        .once()
        .then((DataSnapshot dataSnapshot) {
      print("dataSnapshot.value: ${dataSnapshot.value}");

      if (dataSnapshot.value != null) {
        assetsAudioPlayer.open(Audio("assets/sounds/alert.mp3"));
        assetsAudioPlayer.play();

        double pickUpLocationLat =
            double.parse(dataSnapshot.value["pickup"]["latitude"].toString());
        double pickUpLocationLng =
            double.parse(dataSnapshot.value["pickup"]["longitude"].toString());
        String pickUpAddress = dataSnapshot.value["pickup_address"].toString();

        double dropOffLocationLat =
            double.parse(dataSnapshot.value["dropoff"]["latitude"].toString());
        double dropOffLocationLng =
            double.parse(dataSnapshot.value["dropoff"]["longitude"].toString());
        String dropOffAddress =
            dataSnapshot.value["dropoff_address"].toString();

        String paymentMethod = dataSnapshot.value["payment_method"].toString();

        String riderName = dataSnapshot.value["rider_name"];
        String riderPhone = dataSnapshot.value["rider_phone"];

        RideDetails rideDetails = RideDetails();
        rideDetails.rideRequesId = rideRequestId;
        rideDetails.pickupAddress = pickUpAddress;
        rideDetails.dropoffAddress = dropOffAddress;
        rideDetails.pickup = LatLng(pickUpLocationLat, pickUpLocationLng);
        rideDetails.dropoff = LatLng(dropOffLocationLat, dropOffLocationLng);
        rideDetails.paymentMethod = paymentMethod;
        rideDetails.riderName = riderName;
        rideDetails.riderPhone = riderPhone;

        print("Information:: ");
        print(rideDetails.pickupAddress);
        print(rideDetails.dropoffAddress);
        print("Information:: ");

        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => NotificationDialog(
                  rideDetails: rideDetails,
                ));
      }
    });
  }
}
