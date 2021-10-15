import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:uber_app_rider/configMaps.dart';

class RatingScreen extends StatefulWidget {
  final String driverId;

  RatingScreen({required this.driverId});

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
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
                "Rate this Driver",
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                    fontFamily: "Brand Bold"),
              ),
              SizedBox(height: 22.0),
              Divider(height: 2, thickness: 2),
              SizedBox(height: 16.0),
              RatingBar.builder(
                initialRating: starCounter,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 45,
                itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.green,
                ),
                onRatingUpdate: (rating) {
                  print(rating);
                  starCounter = rating;
                  if (starCounter == 1) {
                    setState(() {
                      title = "Very Bad";
                    });
                  } else if (starCounter == 2) {
                    setState(() {
                      title = "Bad";
                    });
                  } else if (starCounter == 3) {
                    setState(() {
                      title = "Good";
                    });
                  } else if (starCounter == 4) {
                    setState(() {
                      title = "Very Good";
                    });
                  } else if (starCounter == 5) {
                    setState(() {
                      title = "Excellent";
                    });
                  }
                },
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: MaterialButton(
                  onPressed: () async {
                    DatabaseReference driverRatingRef = FirebaseDatabase
                        .instance
                        .reference()
                        .child("drivers")
                        .child(widget.driverId)
                        .child("ratings");

                    driverRatingRef.once().then((DataSnapshot dataSnapshot) {
                      if (dataSnapshot.value != null) {
                        double oldRatings =
                            double.parse(dataSnapshot.value.toString());
                        double addRatings = oldRatings + starCounter;
                        double averageRatings = addRatings / 2;
                        driverRatingRef.set(averageRatings.toString());
                      } else {
                        driverRatingRef.set(starCounter.toString());
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  color: Colors.deepPurpleAccent,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "Submit",
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}
