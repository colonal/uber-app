import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_app_driver/AllScreens/registerationScreen.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/cubit/cubit.dart';

import 'AllScreens/carInfoScreen.dart';
import 'AllScreens/loginScreen.dart';
import 'AllScreens/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  currrentFirebaseUser = FirebaseAuth.instance.currentUser;

  runApp(MyApp());
}

DatabaseReference usersRef =
    FirebaseDatabase.instance.reference().child("users");
DatabaseReference drivesrRef =
    FirebaseDatabase.instance.reference().child("drivers");
DatabaseReference newRequestsRef =
    FirebaseDatabase.instance.reference().child("Ride Requests");
DatabaseReference? ridetripRequestRef = FirebaseDatabase.instance
    .reference()
    .child("drivers")
    .child(currrentFirebaseUser!.uid)
    .child("newRide");

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainCubit(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Taxi Driver App',
        theme: ThemeData(
          fontFamily: "Brand-Regular",
          primarySwatch: Colors.blue,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null
            ? LoginScreen.idScreen
            : MainScreen.idScreen,
        // initialRoute: MainScreen.idScreen,
        routes: {
          LoginScreen.idScreen: (_) => LoginScreen(),
          RegisterationScreen.idScreen: (_) => RegisterationScreen(),
          MainScreen.idScreen: (_) => MainScreen(),
          CarInfoScreen.idScreen: (_) => CarInfoScreen(),
        },
        home: LoginScreen(),
      ),
    );
  }
}
