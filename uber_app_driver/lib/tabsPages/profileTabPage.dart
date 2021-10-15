import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:uber_app_driver/AllScreens/loginScreen.dart';
import 'package:uber_app_driver/configMaps.dart';
import 'package:uber_app_driver/main.dart';

class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              driversInformation!.name ?? "",
              style: TextStyle(
                fontSize: 65,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Signatra",
              ),
            ),
            Text(
              title + " driver",
              style: TextStyle(
                fontSize: 20,
                color: Colors.blueGrey[200],
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                fontFamily: "Brand-Regular",
              ),
            ),
            SizedBox(
                height: 20, width: 200, child: Divider(color: Colors.white)),
            SizedBox(height: 40),
            InfoCard(
              text: driversInformation!.phone ?? "",
              icon: Icons.phone,
              onPressed: () async {
                print("this is phone");
              },
            ),
            InfoCard(
              text: driversInformation!.email ?? "",
              icon: Icons.email_outlined,
              onPressed: () async {
                print("this is email");
              },
            ),
            InfoCard(
              text: (driversInformation!.carColor ?? "") +
                  " " +
                  (driversInformation!.carModel ?? "") +
                  " " +
                  (driversInformation!.carNumber ?? ""),
              icon: Icons.car_repair,
              onPressed: () async {
                print("this is car Info");
              },
            ),
            GestureDetector(
              onTap: () {
                Geofire.removeLocation(currrentFirebaseUser!.uid);
                ridetripRequestRef!.onDisconnect();
                ridetripRequestRef!.remove();
                ridetripRequestRef = null;
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginScreen.idScreen, (route) => false);
              },
              child: Card(
                color: Colors.red,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 110),
                child: ListTile(
                  trailing: Icon(
                    Icons.follow_the_signs_outlined,
                    color: Colors.white,
                  ),
                  title: Text(
                    "Sing out",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: "Brand Bold"),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Function()? onPressed;

  InfoCard({required this.text, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.black87,
          ),
          title: Text(
            text,
            style: TextStyle(
                color: Colors.black87, fontSize: 16, fontFamily: "Brand Bold"),
          ),
        ),
      ),
    );
  }
}
