import 'package:firebase_auth/firebase_auth.dart';

import 'Models/allUsers.dart';

String mapKey = "A**********************************";

User? firebaseUser;

Users? userCurrentInfo;

int driverRequestTimeOut = 10;

String rideStatus = "Driver is Coming";
String statusRide = "";
String carDetailsDriver = "";
String driverNameDriver = "";
String driverPhoneDriver = "";

double starCounter = 3;
String title = "";
String carRideType = "";

String serverToken = "**********************************";
