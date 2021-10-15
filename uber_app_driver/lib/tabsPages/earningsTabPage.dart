import 'package:flutter/material.dart';
import 'package:uber_app_driver/AllScreens/HistoryScreen.dart';
import 'package:uber_app_driver/cubit/cubit.dart';

class EarningsTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String totle = MainCubit.get(context).earnings;
    print(double.parse(totle));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.black87,
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    "Total Earnings",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "${double.parse(totle)} JOD",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontFamily: "Brand Bold"),
                  )
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HistoryScreen()));
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                child: Row(
                  children: [
                    Image(
                      width: 70,
                      image: AssetImage(
                        "assets/images/uberx.png",
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      "Total Trips",
                      style: TextStyle(fontSize: 16),
                    ),
                    Expanded(
                      child: Container(
                        child: Text(
                          MainCubit.get(context).tripCount.toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 2.0,
              thickness: 2.0,
            )
          ],
        ),
      ),
    );
  }
}
