import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_app_rider/Assistarts/requestAssistant.dart';
import 'package:uber_app_rider/Models/address.dart';
import 'package:uber_app_rider/Models/allUsers.dart';
import 'package:uber_app_rider/Models/directDetails.dart';
import 'package:uber_app_rider/Models/history.dart';
import 'package:uber_app_rider/configMaps.dart';
import 'package:uber_app_rider/cubit/cubit.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:uber_app_rider/main.dart';

class AssistantMethods {
  static Future<String> searchCoordinateAddress(
      Position position, BuildContext context) async {
    String placeAddress = '';

    String st1, st2, st3, st4;

    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestAssistant.getRequest(url);

    if (response != "Failed") {
      print(url);
      print('length ${response["results"][1]["address_components"].length}');
      st1 = "";
      if (response["results"][1]['address_components'].length == 4) {
        st1 =
            response["results"][1]['address_components'][3]["long_name"] ?? "";
      }

      st2 = response["results"][1]['address_components'][2]["long_name"] ?? "";
      st3 = response["results"][1]['address_components'][1]["long_name"] ?? "";
      st4 = response["results"][1]['address_components'][0]["long_name"] ?? "";

      placeAddress = "$st1, $st2, $st3, $st4";

      Address userPickUpAddress = new Address();
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.placeName = placeAddress;

      MainCubit.get(context).updatePickUpLocation(userPickUpAddress);
    }
    return placeAddress;
  }

  static Future obtainPlaceDirectionDeails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if (res == "Failed") {
      return null;
    }
    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodedPoints =
        res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText =
        res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue =
        res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText =
        res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue =
        res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    // in terms US
    double timeTraveledFare = (directionDetails.durationValue! / 60) * 0.20;
    double distancTraveledFare =
        (directionDetails.distanceValue! / 1000) * 0.20;

    double totalFareAmount = timeTraveledFare + distancTraveledFare;

    double totalLocalAmount = totalFareAmount * 0.709;
    return totalLocalAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = FirebaseAuth.instance.currentUser;

    String userId = firebaseUser!.uid;

    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        userCurrentInfo = Users.fromSnapshot(dataSnapshot);
      }
    });
  }

  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationToDriver(
      BuildContext context, String token, String rideRequestId) async {
    var destionation = MainCubit.get(context).dropOffLocation;

    Map<String, String> headerMap = {
      "Content-Type": "application/json",
      "Authorization": "$serverToken"
    };

    Map bodyMap = {
      "to": token,
      "notification": {
        "title": "title",
        "body": "DropOff Address, ${destionation!.placeName}",
        "sound": "default"
      },
      "android": {
        "priority": "HIGH",
        "direct_boot_ok": true,
        "notification": {
          "notification_priority": "PRIORITY_MAX",
          "sound": "default",
          "default_sound": true,
          "default_vibrate_timings": true,
          "default_light_settings": true
        }
      },
      "data": {
        "type": "order",
        "id": "2",
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "ride_request_id": rideRequestId,
      },
      "priority": "high"
    };
    print("bodyMap: $bodyMap");
    var res = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      body: jsonEncode(bodyMap),
      headers: headerMap,
    );
    print("res 22:${res.body} ");
  }

  static void retrieveHistoryInfo(context) {
    // retrieve and display Trip History
    usersRef
        .child(firebaseUser!.uid)
        .child("history")
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        // update total number of trip counts to provide
        Map<dynamic, dynamic> keys = dataSnapshot.value;
        int tripCounter = keys.length;
        MainCubit.get(context).updateTrips(tripCounter);

        // update trip keys to provider
        List<String> tripHistoryKeys = [];
        keys.forEach((key, value) {
          tripHistoryKeys.add(key);
        });
        MainCubit.get(context).updateTripKeys(tripHistoryKeys);

        abtainTripRequestsHistoryData(context);
      }
    });
  }

  static void abtainTripRequestsHistoryData(context) {
    var keys = MainCubit.get(context).tripHistoryKeys;

    for (String key in keys) {
      newRequestsRef.child(key).once().then((DataSnapshot dataSnapshot) {
        if (dataSnapshot.value != null) {
          var history = History.formSnapshot(dataSnapshot);
          MainCubit.get(context).updateTripHistoryData(history);
        }
      });
    }
  }

  static String formatTripDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate =
        "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}";

    return formattedDate;
  }
}
