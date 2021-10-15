import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber_app_driver/Assistarts/requestAssistant.dart';
import 'package:uber_app_driver/Models/directDetails.dart';
import 'package:uber_app_driver/Models/history.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/cubit/cubit.dart';
import 'package:uber_app_driver/main.dart';

class AssistantMethods {
  static Future obtainPlaceDirectionDeails(
      LatLng initialPosition, LatLng finalPosition) async {
    print("obtainPlaceDirectionDeails");
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

    print("directionDetails2");
    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    // in terms US
    double timeTraveledFare = (directionDetails.durationValue! / 60) * 0.20;
    double distancTraveledFare =
        (directionDetails.distanceValue! / 1000) * 0.20;

    double totalFareAmount = timeTraveledFare + distancTraveledFare;

    double totalLocalAmount = totalFareAmount * 0.709;

    if (rideType == "uber-x") {
      double result = totalLocalAmount.truncate() * 2.0;
      return result.truncate();
    } else if (rideType == "uber-go") {
      return totalLocalAmount.truncate();
    } else if (rideType == "bike") {
      double result = totalLocalAmount.truncate() / 2.0;
      return result.truncate();
    }
    return totalLocalAmount.truncate();
  }

  static void disablehomeTabLiveLocationUpdates() {
    homeTabPageStreamSubscription!.pause();
    Geofire.removeLocation(currrentFirebaseUser!.uid);
  }

  static void enablehomeTabLiveLocationUpdates() {
    homeTabPageStreamSubscription!.resume();
    Geofire.setLocation(currrentFirebaseUser!.uid, currentPosition.latitude,
        currentPosition.longitude);
  }

  static void retrieveHistoryInfo(context) {
    // retrieve and display Earnings
    drivesrRef
        .child(currrentFirebaseUser!.uid)
        .child("earnings")
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        String earnings = dataSnapshot.value.toString();
        MainCubit.get(context).updateEarnings(earnings);
      }
    });

    // retrieve and display Trip History
    drivesrRef
        .child(currrentFirebaseUser!.uid)
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
