import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_app_driver/AllWidgets/CollectFareDialog.dart';
import 'package:uber_app_driver/AllWidgets/progressDialog.dart';
import 'package:uber_app_driver/Assistarts/assistantMethods.dart';
import 'package:uber_app_driver/Assistarts/mapKitAssistant.dart';
import 'package:uber_app_driver/Models/rideDetails.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/main.dart';

class NewRideScreen extends StatefulWidget {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final RideDetails rideDetails;
  const NewRideScreen({required this.rideDetails});

  @override
  _NewRideScreenState createState() => _NewRideScreenState();
}

class _NewRideScreenState extends State<NewRideScreen> {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  MapType _currentMapType = MapType.normal;

  late GoogleMapController newRideGoogleMapController;

  Set<Marker> markersSet = Set<Marker>();
  Set<Circle> circleSet = Set<Circle>();
  Set<Polyline> polyLineSet = Set<Polyline>();
  List<LatLng> polylineCorOrdinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  Position? myPostion;

  String status = "accepted";
  String durationRide = " ";
  bool isRequestingDirection = false;
  String btnTitle = "Arrived";
  MaterialStateProperty<Color?> btnColor =
      MaterialStateProperty.all(Colors.blueAccent);
  Timer? timer;
  int durationCounter = 0;

  var geoLocator = Geolocator();
  var locationOptions =
      LocationOptions(accuracy: LocationAccuracy.bestForNavigation);
  BitmapDescriptor? animatingMarkerIcon;

  double mapPaddingFormBottom = 0;

  @override
  void initState() {
    super.initState();

    acceptRideRequest();
  }

  void createIconMarker() {
    print("createIconMarker: $animatingMarkerIcon");
    if (animatingMarkerIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));

      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "assets/images/car_android.png")
          .then((value) {
        animatingMarkerIcon = value;
      });
    }
  }

  void getRideLiveLocationUpdates() {
    LatLng oldPos = LatLng(0, 0);

    rideStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      currentPosition = position;
      myPostion = position;
      LatLng mPostion = LatLng(position.latitude, position.longitude);

      var rot = MapKitAssistant.getMarkerRotation(oldPos.latitude,
          oldPos.longitude, mPostion.latitude, mPostion.longitude);

      Marker animationMarker = Marker(
          markerId: MarkerId("animating"),
          position: mPostion,
          rotation: rot,
          icon: animatingMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(title: "Current Location"));
      setState(() {
        CameraPosition cameraPosition =
            new CameraPosition(target: mPostion, zoom: 17);

        newRideGoogleMapController
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet
            .removeWhere((element) => element.markerId.value == "animating");

        markersSet.add(animationMarker);
      });

      oldPos = mPostion;
      updateRideDetails();

      Map locMap = {
        "latitude": currentPosition.latitude.toString(),
        "longitude": currentPosition.longitude.toString(),
      };
      String rideRequestId = widget.rideDetails.rideRequesId ?? "";
      newRequestsRef.child(rideRequestId).child("driver_location").set(locMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: mapPaddingFormBottom),
              mapType: _currentMapType,
              myLocationButtonEnabled: true,
              initialCameraPosition: NewRideScreen._kGooglePlex,
              myLocationEnabled: true,
              markers: markersSet,
              circles: circleSet,
              polylines: polyLineSet,
              onMapCreated: (GoogleMapController controller) async {
                _controllerGoogleMap.complete(controller);
                newRideGoogleMapController = controller;

                setState(() {
                  mapPaddingFormBottom = 265.0;
                });
                var currentLatLng =
                    LatLng(currentPosition.latitude, currentPosition.longitude);
                var pickUpLatLng = widget.rideDetails.pickup;

                if (pickUpLatLng != null) {
                  await getPlaceDirectio(currentLatLng, pickUpLatLng);
                }

                getRideLiveLocationUpdates();
              },
            ),
            Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                height: 270.0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      Text(
                        "$durationRide",
                        style: TextStyle(fontSize: 14.0, color: Colors.black),
                      ),
                      SizedBox(height: 6.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.rideDetails.riderName!,
                            style: TextStyle(fontSize: 14.0),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 10.0),
                            child: Icon(Icons.phone_android),
                          ),
                        ],
                      ),
                      SizedBox(height: 26.0),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/pickicon.png",
                            height: 16.0,
                            width: 16.0,
                          ),
                          SizedBox(height: 18.0),
                          Expanded(
                            child: Container(
                              child: Text(
                                widget.rideDetails.pickupAddress!,
                                style: TextStyle(fontSize: 14.0),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 26.0),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/desticon.png",
                            height: 16.0,
                            width: 16.0,
                          ),
                          SizedBox(height: 18.0),
                          Expanded(
                            child: Container(
                              child: Text(
                                widget.rideDetails.dropoffAddress!,
                                style: TextStyle(fontSize: 14.0),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 26.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          style: ButtonStyle(backgroundColor: btnColor),
                          onPressed: () async {
                            if (status == "accepted") {
                              status = "arrived";
                              String rideRequestId =
                                  widget.rideDetails.rideRequesId ?? "";
                              newRequestsRef
                                  .child(rideRequestId)
                                  .child("status")
                                  .set(status);

                              setState(() {
                                btnTitle = "Start Trip";
                                btnColor =
                                    MaterialStateProperty.all(Colors.purple);
                              });
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      ProgressDialog(
                                          message: "Please wait ..."));
                              await getPlaceDirectio(widget.rideDetails.pickup!,
                                  widget.rideDetails.dropoff!);

                              Navigator.of(context).pop();
                            } else if (status == "arrived") {
                              status = "onride";
                              String rideRequestId =
                                  widget.rideDetails.rideRequesId ?? "";
                              newRequestsRef
                                  .child(rideRequestId)
                                  .child("status")
                                  .set(status);

                              setState(() {
                                btnTitle = "End Trip";
                                btnColor =
                                    MaterialStateProperty.all(Colors.redAccent);
                              });
                              initTimer();
                            } else if (status == "onride") {
                              endTheTrip();
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  btnTitle,
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 26.0,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> getPlaceDirectio(
      LatLng pickUpLapLng, LatLng dropOffLapLng) async {
    showDialog(
        context: context,
        builder: (context) => ProgressDialog(message: "Please wait ..."));

    var details = await AssistantMethods.obtainPlaceDirectionDeails(
        pickUpLapLng, dropOffLapLng);

    Navigator.of(context).pop();
    print("This is Encoded Points ::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();

    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    polylineCorOrdinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        polylineCorOrdinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polyLineSet.clear();
    setState(() {
      print("setState");
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolyLineID"),
        jointType: JointType.round,
        points: polylineCorOrdinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLapLng.latitude > dropOffLapLng.latitude &&
        pickUpLapLng.longitude > dropOffLapLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLapLng, northeast: pickUpLapLng);
    } else if (pickUpLapLng.longitude > dropOffLapLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLapLng.latitude, dropOffLapLng.longitude),
          northeast: LatLng(dropOffLapLng.latitude, pickUpLapLng.longitude));
    } else if (pickUpLapLng.latitude > dropOffLapLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLapLng.latitude, pickUpLapLng.longitude),
          northeast: LatLng(pickUpLapLng.latitude, dropOffLapLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLapLng, northeast: dropOffLapLng);
    }

    newRideGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        position: pickUpLapLng,
        markerId: MarkerId("pickUpId"));
    Marker dropOffUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        position: dropOffLapLng,
        markerId: MarkerId("dropOffId"));

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffUpLocMarker);
    });

    Circle pickUpLocCircle = Circle(
        fillColor: Colors.blueAccent,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent,
        center: pickUpLapLng,
        circleId: CircleId("pickUpId"));
    Circle dropOffLocCircle = Circle(
        fillColor: Colors.deepPurple,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurpleAccent,
        center: dropOffLapLng,
        circleId: CircleId("dropOffId"));

    setState(() {
      circleSet.add(pickUpLocCircle);
      circleSet.add(dropOffLocCircle);
    });
  }

  void acceptRideRequest() {
    String rideRequestId = widget.rideDetails.rideRequesId ?? "";

    newRequestsRef.child(rideRequestId).child("status").set("accepted");
    newRequestsRef
        .child(rideRequestId)
        .child("driver_name")
        .set(driversInformation!.name);
    newRequestsRef
        .child(rideRequestId)
        .child("driver_phone")
        .set(driversInformation!.phone);
    newRequestsRef
        .child(rideRequestId)
        .child("driver_id")
        .set(driversInformation!.id);
    newRequestsRef.child(rideRequestId).child("car_details").set(
        '${driversInformation!.carColor} - ${driversInformation!.carModel} - ${driversInformation!.carNumber}');

    Map locMap = {
      "latitude": currentPosition.latitude.toString(),
      "longitude": currentPosition.longitude.toString(),
    };

    newRequestsRef.child(rideRequestId).child("driver_location").set(locMap);

    drivesrRef
        .child(currrentFirebaseUser!.uid)
        .child("history")
        .child(rideRequestId)
        .set(true);
  }

  void updateRideDetails() async {
    if (isRequestingDirection == false) {
      isRequestingDirection = true;
      if (myPostion == null) {
        return;
      }
      var postLatLng = LatLng(myPostion!.latitude, myPostion!.longitude);
      LatLng destinationLatLng;

      if (status == "accepted") {
        destinationLatLng = widget.rideDetails.pickup!;
      } else {
        destinationLatLng = widget.rideDetails.dropoff!;
      }

      var directionDetaols = await AssistantMethods.obtainPlaceDirectionDeails(
          postLatLng, destinationLatLng);
      print("directionDetaols");
      print("directionDetaols: $directionDetaols");
      print("directionDetaols: ${directionDetaols.durationText}");
      print("directionDetaols");
      if (directionDetaols != null) {
        setState(() {
          durationRide = (directionDetaols.durationText).toString();
        });
      }

      isRequestingDirection = false;
    }
  }

  void initTimer() {
    const interval = Duration(seconds: 1);

    timer = Timer.periodic(interval, (timer) {
      durationCounter += 1;
    });
  }

  void endTheTrip() async {
    timer!.cancel();
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Please wait ..."));

    var currentLatLng = LatLng(myPostion!.latitude, myPostion!.longitude);

    var directionalDetails = await AssistantMethods.obtainPlaceDirectionDeails(
        widget.rideDetails.pickup!, currentLatLng);

    Navigator.of(context).pop();

    int foreAmount = AssistantMethods.calculateFares(directionalDetails);

    newRequestsRef
        .child(widget.rideDetails.rideRequesId ?? "")
        .child("fares")
        .set(foreAmount.toString());
    newRequestsRef
        .child(widget.rideDetails.rideRequesId ?? "")
        .child("status")
        .set("ended");

    rideStreamSubscription!.cancel();

    showDialog(
        context: context,
        builder: (BuildContext context) => CollectFareDialog(
            fareAmount: foreAmount.toString(),
            paymentMethod: widget.rideDetails.paymentMethod!));
    saveEarnings(foreAmount);
  }

  void saveEarnings(int fareAmount) {
    drivesrRef
        .child(currrentFirebaseUser!.uid)
        .child("earnings")
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        double oldEarnings = double.parse(dataSnapshot.value.toString());
        double totalEarnings = fareAmount + oldEarnings;

        drivesrRef
            .child(currrentFirebaseUser!.uid)
            .child("earnings")
            .set(totalEarnings.toStringAsExponential(2));
      } else {
        double totalEarnings = fareAmount.toDouble();
        drivesrRef
            .child(currrentFirebaseUser!.uid)
            .child("earnings")
            .set(totalEarnings.toStringAsExponential(2));
      }
    });
  }
}
