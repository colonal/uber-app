import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber_app_driver/Models/deivers.dart';

import 'Models/allUsers.dart';

String mapKey = "***********************************";

User? firebaseUser;

User? currrentFirebaseUser;

Users? userCurrentInfo;

final assetsAudioPlayer = AssetsAudioPlayer();

late Position currentPosition;

StreamSubscription<Position>? homeTabPageStreamSubscription;

StreamSubscription<Position>? rideStreamSubscription;

Drivers? driversInformation;

String title = "";

double starCounter = 0.0;

String rideType = "";
