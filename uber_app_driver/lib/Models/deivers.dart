import 'package:firebase_database/firebase_database.dart';

class Drivers {
  String? name;
  String? phone;
  String? email;
  String? id;
  String? carColor;
  String? carModel;
  String? carNumber;

  Drivers(
      {this.carColor,
      this.carModel,
      this.carNumber,
      this.email,
      this.id,
      this.name,
      this.phone});

  Drivers.fromSnapshot(DataSnapshot dataSnapshot) {
    id = dataSnapshot.key;
    phone = dataSnapshot.value["phone"];
    name = dataSnapshot.value["name"];
    email = dataSnapshot.value["email"];
    carColor = dataSnapshot.value["car_details"]["car_color"];
    carModel = dataSnapshot.value["car_details"]["car_model"];
    carNumber = dataSnapshot.value["car_details"]["car_number"];
  }
}
