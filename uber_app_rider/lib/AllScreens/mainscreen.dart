import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_app_rider/AllScreens/historyScreen.dart';
import 'package:uber_app_rider/AllScreens/loginScreen.dart';
import 'package:uber_app_rider/AllScreens/profileScreen.dart';
import 'package:uber_app_rider/AllScreens/ratingScreen.dart';
import 'package:uber_app_rider/AllScreens/searchScreen.dart';
import 'package:uber_app_rider/AllWidgets/CollectFareDialog.dart';
import 'package:uber_app_rider/AllWidgets/noDriverAvailableDialog.dart';
import 'package:uber_app_rider/AllWidgets/progressDialog.dart';
import 'package:uber_app_rider/Assistarts/assistantMethods.dart';
import 'package:uber_app_rider/Assistarts/geoFireAssistant.dart';
import 'package:uber_app_rider/Models/directDetails.dart';
import 'package:uber_app_rider/Models/nearbyAvailableDrivers.dart';
import 'package:uber_app_rider/configMaps.dart';
import 'package:uber_app_rider/cubit/cubit.dart';
import 'package:uber_app_rider/cubit/state.dart';
import 'package:uber_app_rider/main.dart';
import 'package:uber_app_rider/shared/components/components.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "home";
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();

  late GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails;

  late Position currentPosition;

  Geolocator geoLocator = Geolocator();

  double bottomPaddingOfMap = 0;

  MapType _currentMapType = MapType.normal;

  List<LatLng> pLineCoerordinates = [];
  Set<Polyline> polylineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 320.0;
  double driverDetailsContainerHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference? rideRequestRef;

  bool isRequestingPositionDetails = false;

  void displayDriverDetailsContainer() {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 280.0;
      driverDetailsContainerHeight = 310;
    });
  }

  StreamSubscription<Event?>? rideStreamSubscription;

  @override
  void initState() {
    super.initState();
    Geofire.initialize("availableDrivers");
    AssistantMethods.getCurrentOnlineUserInfo();
    AssistantMethods.retrieveHistoryInfo(context);
    // locatePosition();
  }

  void saveRideRequest() async {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = MainCubit.get(context).pickUpLocation;
    var dropOff = MainCubit.get(context).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp!.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff!.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideinfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo!.name,
      "rider_phone": userCurrentInfo!.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
      "ride_type": carRideType,
    };

    rideRequestRef!.set(rideinfoMap);

    rideStreamSubscription = rideRequestRef!.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }
      if (event.snapshot.value["car_details"] != null) {
        setState(() {
          carDetailsDriver = event.snapshot.value["car_details"].toString();
        });
      }
      if (event.snapshot.value["driver_name"] != null) {
        setState(() {
          driverNameDriver = event.snapshot.value["driver_name"].toString();
        });
      }
      if (event.snapshot.value["driver_phone"] != null) {
        setState(() {
          driverPhoneDriver = event.snapshot.value["driver_phone"].toString();
        });
      }

      if (event.snapshot.value["driver_location"] != null) {
        double driverLat = double.parse(
            event.snapshot.value["driver_location"]["latitude"].toString());
        double driverLng = double.parse(
            event.snapshot.value["driver_location"]["longitude"].toString());

        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);
        if (statusRide == "accepted") {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        } else if (statusRide == "onride") {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        } else if (statusRide == "arrived") {
          setState(() {
            rideStatus = "Driver has Arrived.";
          });
        }
      }

      if (event.snapshot.value["status"] != null) {
        statusRide = event.snapshot.value["status"].toString();
      }
      if (statusRide == "accepted") {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofireMarkers();
      }
      if (statusRide == "ended") {
        if (event.snapshot.value["fares"] != null) {
          //
          usersRef
              .child(firebaseUser!.uid)
              .child("history")
              .child(rideRequestRef!.key)
              .set(true);
          //
          int fare = int.parse(event.snapshot.value["fares"].toString());

          var res = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => CollectFareDialog(
                  fareAmount: fare.toString(), paymentMethod: "cash"));
          String driverId = "";
          if (res == "close") {
            if (event.snapshot.value["driver_id"] != null) {
              driverId = event.snapshot.value["driver_id"].toString();
            }
            if (event.snapshot.value["driver_id"] != null) {
              driverId = event.snapshot.value["driver_id"].toString();
            }

            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RatingScreen(driverId: driverId)));

            rideRequestRef!.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription!.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofireMarkers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;
      var positionUserLatLng = LatLng(
          driverCurrentLocation.latitude, driverCurrentLocation.longitude);

      var details = await AssistantMethods.obtainPlaceDirectionDeails(
          driverCurrentLocation, positionUserLatLng);

      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Driver is Coming - " + details.durationText;
      });
      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var dropOff = MainCubit.get(context).dropOffLocation;
      var dropOffUserLatLng =
          LatLng(dropOff!.latitude ?? 0, dropOff.longitude ?? 0);

      var details = await AssistantMethods.obtainPlaceDirectionDeails(
          driverCurrentLocation, dropOffUserLatLng);

      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Going to Destination - " + details.durationText;
      });
      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    rideRequestRef!.remove();
    setState(() {
      dState = "normal";
    });
  }

  void displayReqestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 260.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 320;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 260.0;
      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoerordinates.clear();

      statusRide = "";
      driverNameDriver = "";
      driverPhoneDriver = "";
      carDetailsDriver = "";
      rideStatus = "Driver is Coming";

      driverDetailsContainerHeight = 0.0;
    });
    locatePosition();
  }

  // void getCurrentDriverInfo() async {
  //   currrentFirebaseUser = FirebaseAuth.instance.currentUser;

  //   usersRef
  //       .child(currrentFirebaseUser!.uid)
  //       .once()
  //       .then((DataSnapshot dataSnapshot) {
  //     if (dataSnapshot.value != null) {
  //       userCurrentInfo = Users.fromSnapshot(dataSnapshot);
  //     }
  //   });
  // }

  void displayRideDetailsContainer() async {
    await getPlaceDirectio();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 340.0;
      bottomPaddingOfMap = 360.0;
      drawerOpen = false;
    });
  }

  bool locatePositionChange = false;
  void locatePosition() async {
    print("locatePosition");
    locatePositionChange = true;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 14.0);

    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    print("This is your address :: $address");
    locatePositionChange = false;

    initGeoFireListner();
    if (userCurrentInfo != null)
      uName = userCurrentInfo!.name ?? "";
    else
      uName = "";
  }

  void _onMapTypeButtonPressed() {
    if (drawerOpen) {
      setState(() {
        _currentMapType = _currentMapType == MapType.normal
            ? MapType.satellite
            : MapType.normal;
      });
    } else {
      resetApp();
    }
  }

  static const colorizeColors = [
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 55.0,
    fontFamily: 'Signatra',
  );

  BitmapDescriptor? nearByIcon;

  List<NearbyAvailableDrivers> availablDrivers = <NearbyAvailableDrivers>[];

  String dState = "normal";

  String uName = "";

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(width: 16.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uName,
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand Bold"),
                          ),
                          SizedBox(height: 6.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ProfileScreen()));
                            },
                            child: Text(
                              "Visit Profile",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0),

              //  Drawer Body Conterllers
              ListTile(
                onTap: () {
                  // HistoryScreen
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => HistoryScreen()));
                },
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ProfileScreen()));
                },
                leading: Icon(Icons.person),
                title: Text(
                  "Vist Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  "About",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.logout_outlined),
                  title: Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<MainCubit, MainState>(
        listener: (context, state) {},
        builder: (context, state) {
          var cubit = MainCubit.get(context);
          return Stack(
            children: [
              GoogleMap(
                padding: EdgeInsets.only(bottom: bottomPaddingOfMap, top: 10),
                mapType: _currentMapType,
                myLocationButtonEnabled: true,
                initialCameraPosition: MainScreen._kGooglePlex,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: true,
                polylines: polylineSet,
                markers: markersSet,
                circles: circlesSet,
                onMapCreated: (GoogleMapController controller) {
                  _controllerGoogleMap.complete(controller);
                  newGoogleMapController = controller;

                  setState(() {
                    bottomPaddingOfMap = 300.0;
                  });

                  locatePosition();
                },
              ),

              // HamburgerButton for Drawer
              Positioned(
                top: 65.0,
                left: 18.0,
                child: GestureDetector(
                  onTap: () {
                    scaffoldKey.currentState!.openDrawer();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.0),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black,
                              blurRadius: 6.0,
                              spreadRadius: 0.5,
                              offset: Offset(0.7, 0.7))
                        ]),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.menu,
                        color: Colors.black,
                      ),
                      radius: 20.0,
                    ),
                  ),
                ),
              ),

              // State Map
              Positioned(
                top: 115.0,
                left: 18.0,
                child: GestureDetector(
                  onTap: _onMapTypeButtonPressed,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.0),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black,
                              blurRadius: 6.0,
                              spreadRadius: 0.5,
                              offset: Offset(0.7, 0.7))
                        ]),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        drawerOpen ? Icons.map : Icons.close,
                        color: Colors.black,
                      ),
                      radius: 20.0,
                    ),
                  ),
                ),
              ),

              // Search Ui
              Positioned(
                bottom: 0.0,
                right: 0.0,
                left: 0.0,
                child: AnimatedSize(
                  vsync: this,
                  curve: Curves.bounceIn,
                  duration: new Duration(milliseconds: 160),
                  child: Container(
                    height: searchContainerHeight,
                    child: Container(
                      // height: searchContainerHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.0),
                            topRight: Radius.circular(18.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 16.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.only(
                          left: 24.0, bottom: 45.0, right: 24.0, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 6.0),
                          Text(
                            "Hi there,",
                            style: TextStyle(fontSize: 12.0),
                          ),
                          Text(
                            "Where to?",
                            style: TextStyle(fontSize: 20.0),
                          ),
                          SizedBox(height: 20.0),
                          GestureDetector(
                            onTap: () async {
                              var res = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => SearchScreen()));

                              if (res == "obtainDirection") {
                                displayRideDetailsContainer();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 6.0,
                                    spreadRadius: 0.5,
                                    offset: Offset(0.7, 0.7),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      color: Colors.blueAccent,
                                    ),
                                    SizedBox(width: 10.0),
                                    Text(
                                      "Search Drop off",
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home, color: Colors.grey),
                              SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        cubit.pickUpLocation != null
                                            ? cubit.pickUpLocation!.placeName
                                                .toString()
                                            : "Add Home",

                                        // overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      "Your living home address",
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.0),
                          DividerWidget(),
                          SizedBox(height: 16.0),
                          Row(
                            children: [
                              Icon(Icons.work, color: Colors.grey),
                              SizedBox(width: 12.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Add Work"),
                                  SizedBox(height: 4.0),
                                  Text(
                                    "Your office address",
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12.0),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Ride Details ui
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: AnimatedSize(
                  vsync: this,
                  curve: Curves.bounceIn,
                  duration: new Duration(milliseconds: 160),
                  child: Container(
                    height: rideDetailsContainerHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 17.0),
                      child: Column(
                        children: [
                          // bike ride
                          GestureDetector(
                            onTap: () {
                              BotToast.showText(text: "searching Bike ...");
                              setState(() {
                                dState = "requesting";
                                carRideType = "bike";
                              });
                              displayReqestRideContainer();
                              availablDrivers =
                                  GeoFireAssistant.nearByAvailableDriversList;

                              searchNearestDriver();
                            },
                            child: Container(
                              width: double.infinity,
                              // color: Colors.tealAccent[100],
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(children: [
                                Image.asset(
                                  "assets/images/bike.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Bike",
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                    Text(
                                      (tripDirectionDetails == null)
                                          ? ""
                                          : tripDirectionDetails!
                                                  .distanceText ??
                                              "",
                                      style: TextStyle(
                                          fontSize: 16.0, color: Colors.grey),
                                    ),
                                    Container(
                                      height: 30,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          child: Text(
                                            ((tripDirectionDetails != null)
                                                ? "${(AssistantMethods.calculateFares(tripDirectionDetails!)) / 2} JOD"
                                                : " "),
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ]),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Divider(height: 2, thickness: 2),
                          SizedBox(height: 10.0),

                          // uber-go ride
                          GestureDetector(
                            onTap: () {
                              BotToast.showText(text: "searching Uber-Go ...");
                              setState(() {
                                dState = "requesting";
                                carRideType = "uber-go";
                              });
                              displayReqestRideContainer();
                              availablDrivers =
                                  GeoFireAssistant.nearByAvailableDriversList;

                              searchNearestDriver();
                            },
                            child: Container(
                              width: double.infinity,
                              // color: Colors.tealAccent[100],
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(children: [
                                Image.asset(
                                  "assets/images/ubergo.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Uber-Go",
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                    Text(
                                      (tripDirectionDetails == null)
                                          ? ""
                                          : tripDirectionDetails!
                                                  .distanceText ??
                                              "",
                                      style: TextStyle(
                                          fontSize: 16.0, color: Colors.grey),
                                    ),
                                    Container(
                                      height: 30,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          child: Text(
                                            ((tripDirectionDetails != null)
                                                ? "${AssistantMethods.calculateFares(tripDirectionDetails!)} JOD"
                                                : " "),
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ]),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Divider(height: 2, thickness: 2),
                          SizedBox(height: 10.0),

                          // uber-x ride
                          GestureDetector(
                            onTap: () {
                              displayReqestRideContainer();
                              availablDrivers =
                                  GeoFireAssistant.nearByAvailableDriversList;

                              searchNearestDriver();
                              BotToast.showText(text: "searching Uber-X ...");
                              setState(() {
                                dState = "requesting";
                                carRideType = "uber-x";
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              // color: Colors.tealAccent[100],
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(children: [
                                Image.asset(
                                  "assets/images/uberx.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Uber-X",
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                    Text(
                                      (tripDirectionDetails == null)
                                          ? ""
                                          : tripDirectionDetails!
                                                  .distanceText ??
                                              "",
                                      style: TextStyle(
                                          fontSize: 16.0, color: Colors.grey),
                                    ),
                                    Container(
                                      height: 30,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          child: Text(
                                            ((tripDirectionDetails != null)
                                                ? "${(AssistantMethods.calculateFares(tripDirectionDetails!)) * 2} JOD"
                                                : " "),
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ]),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Divider(height: 2, thickness: 2),
                          SizedBox(height: 10.0),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.moneyCheckAlt,
                                  size: 18.0,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 16.0),
                                Text("Cash"),
                                SizedBox(width: 6.0),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black54,
                                  size: 16.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Cancel UI
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0)),
                      boxShadow: [
                        BoxShadow(
                          spreadRadius: 0.5,
                          blurRadius: 16.0,
                          color: Colors.black54,
                          offset: Offset(0.7, 0.7),
                        ),
                      ]),
                  height: requestRideContainerHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        SizedBox(height: 12.0),
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedTextKit(
                            animatedTexts: [
                              ColorizeAnimatedText(
                                'Requesting a Ride ...',
                                textStyle: colorizeTextStyle,
                                colors: colorizeColors,
                                textAlign: TextAlign.center,
                              ),
                              ColorizeAnimatedText(
                                'Please wait ...',
                                textStyle: colorizeTextStyle,
                                colors: colorizeColors,
                                textAlign: TextAlign.center,
                              ),
                              ColorizeAnimatedText(
                                'Finding a Driver ...',
                                textStyle: colorizeTextStyle,
                                colors: colorizeColors,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            // isRepeatingAnimation: true,
                            onTap: () {
                              print("Tap Event");
                            },
                          ),
                        ),
                        SizedBox(height: 22.0),
                        GestureDetector(
                          onTap: () {
                            cancelRideRequest();
                            resetApp();
                          },
                          child: Container(
                            height: 60.0,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26.0),
                              border: Border.all(
                                  width: 2.0,
                                  color: Colors.grey[300] ?? Colors.grey),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 26.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Container(
                          width: double.infinity,
                          child: Text(
                            "Cancel Ride",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.0),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Display Assinse Drive Info
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0)),
                      boxShadow: [
                        BoxShadow(
                          spreadRadius: 0.5,
                          blurRadius: 16.0,
                          color: Colors.black54,
                          offset: Offset(0.7, 0.7),
                        ),
                      ]),
                  height: driverDetailsContainerHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rideStatus,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        SizedBox(height: 22.0),
                        Divider(height: 2, thickness: 2),
                        SizedBox(height: 22.0),
                        Text(
                          carDetailsDriver,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          driverNameDriver,
                          style: TextStyle(fontSize: 20),
                        ),
                        Divider(height: 2, thickness: 2),
                        SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: MaterialButton(
                                onPressed: () async {
                                  launch(('tel://$driverPhoneDriver'));
                                },
                                color: Colors.pink,
                                child: Padding(
                                  padding: EdgeInsets.all(17),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        "Call Drive",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      Icon(
                                        Icons.call,
                                        color: Colors.white,
                                        size: 26,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

              if (locatePositionChange)
                Center(
                  child: Container(
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: CupertinoActivityIndicator(
                        radius: 25,
                      )),
                )
            ],
          );
        },
      ),
    );
  }

  Future<void> getPlaceDirectio() async {
    var initialPos = MainCubit.get(context).pickUpLocation;
    var finalPos = MainCubit.get(context).dropOffLocation;

    var pickUpLapLng =
        LatLng(initialPos!.latitude ?? 0.0, initialPos.longitude ?? 00);
    var dropOffLapLng =
        LatLng(finalPos!.latitude ?? 0.0, finalPos.longitude ?? 00);

    showDialog(
        context: context,
        builder: (context) => ProgressDialog(message: "Please wait ..."));

    var details = await AssistantMethods.obtainPlaceDirectionDeails(
        pickUpLapLng, dropOffLapLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.of(context).pop();
    print("This is Encoded Points ::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();

    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoerordinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoerordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {
      print("setState");
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolyLineID"),
        jointType: JointType.round,
        points: pLineCoerordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
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

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "my Location"),
        position: pickUpLapLng,
        markerId: MarkerId("pickUpId"));
    Marker dropOffUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "DropOff Location"),
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
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  Future<void> initGeoFireListner() async {
    print("initGeoFireListner");

    print("currentPosition.latitude: ${currentPosition.latitude}");
    print("currentPosition.longitude: ${currentPosition.longitude}");
    Geofire.initialize("availableDrivers");

    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 20)!
        .listen((map) {
      print("map1234: $map");
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(
              latitude: map['latitude'] ?? "",
              longitude: map['longitude'] ?? "",
              key: map['key'] ?? "",
            );

            GeoFireAssistant.nearByAvailableDriversList
                .add(nearbyAvailableDrivers);

            // if (nearbyAvailableDriverKeysLoaded) {
            //   updateAvailableDriversOnMap();
            // }
            updateAvailableDriversOnMap();

            print("onKeyEntered");
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            print("Geofire.onKeyExited");
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(
              latitude: map['latitude'] ?? "",
              longitude: map['longitude'] ?? "",
              key: map['key'] ?? "",
            );

            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            print("Geofire.onKeyMoved");
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    }).onError((error) {
      print("ERROR : $error");
    });
  }

  void updateAvailableDriversOnMap() {
    print("updateAvailableDriversOnMap");
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMakers = Set<Marker>();
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearByAvailableDriversList) {
      LatLng driverAvaiablePosition = LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId("driver${driver.key}"),
        position: driverAvaiablePosition,
        icon: nearByIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMakers.add(marker);
    }

    setState(() {
      markersSet = tMakers;
    });
  }

  void createIconMarker() {
    print("createIconMarker: $nearByIcon");
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));

      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "assets/images/car_android.png")
          .then((value) {
        nearByIcon = value;
      });
      // setState(() {});
    }
  }

  void noDriverFound() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => NoDriverAvailableDialog());
  }

  void searchNearestDriver() {
    print("searchNearestDriver");
    print("searchNearestDriver");
    print("searchNearestDriver");
    print("availablDrivers: $availablDrivers");
    if (availablDrivers.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availablDrivers[0];
    driversRef
        .child(driver.key)
        .child("car_details")
        .child("type")
        .once()
        .then((DataSnapshot snap) async {
      if (await snap.value != null) {
        String carType = snap.value.toString();
        if (carType == carRideType) {
          notifyDriver(driver);
          availablDrivers.removeAt(0);
        } else {
          BotToast.showText(
              text: carRideType + " driver not available. Try again");
        }
      } else {
        BotToast.showText(text: "No car found. Try again");
      }
    });
  }

  void notifyDriver(NearbyAvailableDrivers drivers) {
    print("notifyDriver");
    print("notifyDriver");
    print("notifyDriver");
    driversRef.child(drivers.key).child("newRide").set(rideRequestRef!.key);

    driversRef
        .child(drivers.key)
        .child("token")
        .once()
        .then((DataSnapshot dataSnapshot) {
      print("dataSnapshot: ${dataSnapshot.value}");
      if (dataSnapshot.value != null) {
        String dToken = dataSnapshot.value.toString();

        AssistantMethods.sendNotificationToDriver(
            context, dToken, rideRequestRef!.key);
      } else {
        return;
      }

      const oneSecondPasses = Duration(seconds: 1);
      Timer.periodic(oneSecondPasses, (timer) {
        print("driverRequestTimeOut");
        if (dState != "requesting") {
          driversRef.child(drivers.key).child("newRide").set("cancelled");
          driversRef.child(drivers.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
        }

        driverRequestTimeOut -= 1;
        print("driverRequestTimeOut: $driverRequestTimeOut");
        if (driverRequestTimeOut == 0) {
          driversRef.child(drivers.key).child("newRide").set("timeout");
          driversRef.child(drivers.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
          searchNearestDriver();
        }

        driversRef.child(drivers.key).child("newRide").onValue.listen((event) {
          if (event.snapshot.value.toString() == "accepted") {
            driversRef.child(drivers.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 10;
            timer.cancel();
          }
        });
      });
    });
  }
}
