import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideDetails {
  String? pickupAddress;
  String? dropoffAddress;

  LatLng? pickup;
  LatLng? dropoff;

  String? rideRequesId;
  String? paymentMethod;
  String? riderName;
  String? riderPhone;

  RideDetails(
      {this.paymentMethod,
      this.dropoff,
      this.dropoffAddress,
      this.pickup,
      this.pickupAddress,
      this.rideRequesId,
      this.riderName,
      this.riderPhone});
}
