import 'package:uber_app_rider/Models/nearbyAvailableDrivers.dart';

class GeoFireAssistant {
  static List<NearbyAvailableDrivers> nearByAvailableDriversList = [];

  static void removeDriverFromList(String key) {
    int index =
        nearByAvailableDriversList.indexWhere((element) => element.key == key);

    nearByAvailableDriversList.removeAt(index);
  }

  static void updateDriverNearbyLocation(NearbyAvailableDrivers drivers) {
    int index = nearByAvailableDriversList
        .indexWhere((element) => element.key == drivers.key);
    print("updateDriverNearbyLocation index: $index");
    nearByAvailableDriversList[index].latitude = drivers.latitude;
    nearByAvailableDriversList[index].longitude = drivers.longitude;
  }
}
