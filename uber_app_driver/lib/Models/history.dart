import 'package:firebase_database/firebase_database.dart';

class History {
  String? paymentMethod;
  String? createsAt;
  String? status;
  String? fares;
  String? dropOff;
  String? pickup;

  History(
      {this.paymentMethod,
      this.createsAt,
      this.dropOff,
      this.fares,
      this.pickup,
      this.status});

  History.formSnapshot(DataSnapshot dataSnapshot) {
    paymentMethod = dataSnapshot.value["payment_method"];
    createsAt = dataSnapshot.value["created_at"];
    status = dataSnapshot.value["status"];
    fares = dataSnapshot.value["fares"];
    dropOff = dataSnapshot.value["dropoff_address"];
    pickup = dataSnapshot.value["pickup_address"];
  }
}
