import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uber_app_driver/AllScreens/newRideScreen.dart';
import 'package:uber_app_driver/Assistarts/assistantMethods.dart';
import 'package:uber_app_driver/Models/rideDetails.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/main.dart';
import 'package:uber_app_driver/shared/components/components.dart';

class NotificationDialog extends StatelessWidget {
  final RideDetails rideDetails;
  NotificationDialog({required this.rideDetails});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.transparent,
      elevation: 1,
      child: Container(
        margin: EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
            ),
            Image.asset("assets/images/taxi.png", width: 120.0),
            SizedBox(height: 18),
            Text(
              "New Ride Request",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/images/pickicon.png",
                    width: 16.0,
                    height: 16.0,
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      child: Text(
                        rideDetails.pickupAddress ?? "",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.0),
            Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/images/desticon.png",
                    width: 16.0,
                    height: 16.0,
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      child: Text(
                        rideDetails.dropoffAddress ?? "",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Divider(height: 2.0, color: Colors.black, thickness: 2.0),
            SizedBox(height: 8.0),
            Padding(
              padding: EdgeInsets.all(20),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.red)),
                  color: Colors.white,
                  textColor: Colors.red,
                  padding: EdgeInsets.all(8.0),
                  onPressed: () {
                    assetsAudioPlayer.stop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancel".toUpperCase(),
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
                SizedBox(width: 50.0),
                MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.green)),
                  color: Colors.white,
                  textColor: Colors.green,
                  padding: EdgeInsets.all(8.0),
                  onPressed: () {
                    assetsAudioPlayer.stop();
                    Navigator.of(context).pop();
                    checkAvailabilityOfRide(context);
                  },
                  child: Text(
                    "Accept".toUpperCase(),
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
              ]),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void checkAvailabilityOfRide(BuildContext context) {
    ridetripRequestRef!.once().then((DataSnapshot dataSnapshot) {
      String theRideId = "";
      if (dataSnapshot.value != null) {
        theRideId = dataSnapshot.value.toString();
      } else {
        displayToastMessage("Ride not exists.");
      }
      if (theRideId == rideDetails.rideRequesId) {
        ridetripRequestRef!.set("accepted");
        AssistantMethods.disablehomeTabLiveLocationUpdates();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NewRideScreen(rideDetails: rideDetails)));
      } else if (theRideId == "cancelled") {
        displayToastMessage("Ride has been Cancelled.");
      } else if (theRideId == "timeout") {
        displayToastMessage("Ride has time out.");
      } else {
        displayToastMessage("Ride not exists.");
      }
    });
  }
}
