import 'package:flutter/material.dart';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:uber_app_driver/configMaps.dart';

class RatindTabPage extends StatefulWidget {
  @override
  _RatindTabPageState createState() => _RatindTabPageState();
}

class _RatindTabPageState extends State<RatindTabPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(5.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22.0),
              Text(
                "your's Rating",
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                    fontFamily: "Brand Bold"),
              ),
              SizedBox(height: 22.0),
              Divider(height: 2, thickness: 2),
              SizedBox(height: 16.0),
              RatingBarIndicator(
                rating: starCounter,
                direction: Axis.horizontal,
                itemCount: 5,
                itemSize: 45,
                itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 14.0),
              Text(
                title,
                style: TextStyle(
                    fontSize: 65,
                    fontFamily: "Signatra",
                    color: starCounter > 2 ? Colors.green : Colors.redAccent),
              ),
              SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
