import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_app_rider/AllWidgets/progressDialog.dart';
import 'package:uber_app_rider/Assistarts/requestAssistant.dart';
import 'package:uber_app_rider/Models/address.dart';
import 'package:uber_app_rider/Models/placePredictions.dart';
import 'package:uber_app_rider/configMaps.dart';
import 'package:uber_app_rider/cubit/cubit.dart';
import 'package:uber_app_rider/cubit/state.dart';
import 'package:uber_app_rider/shared/components/components.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController pickUpControllet = TextEditingController();
  final TextEditingController dropOffControllet = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        toolbarHeight: 0,
      ),
      body: BlocConsumer<MainCubit, MainState>(
        listener: (context, state) {},
        builder: (context, state) {
          //
          Address? add = MainCubit.get(context).pickUpLocation;
          String placeAddress = "";
          if (add != null) {
            placeAddress = add.placeName!;
          }
          pickUpControllet.text = placeAddress;
          var cubit = MainCubit.get(context);
          List<PlacePredictions> placePredictionList =
              cubit.placePredictionList;
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  // height: 215.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ],
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0),
                  child: Column(
                    children: [
                      SizedBox(height: 5.0),
                      Stack(
                        children: [
                          GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(Icons.arrow_back)),
                          Center(
                            child: Text(
                              "Set Drop off",
                              style: TextStyle(fontSize: 18.0),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/posimarker.png",
                            height: 25.0,
                            width: 25.0,
                          ),
                          SizedBox(width: 18.0),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              padding: EdgeInsets.all(3.0),
                              child: TextFormField(
                                controller: pickUpControllet,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    hintText: "PickUp Lpcation",
                                    fillColor: Colors.grey[200],
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        top: 8.0, left: 11.0, bottom: 8.0)),
                                validator: (text) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/desticon.png",
                            height: 25.0,
                            width: 25.0,
                          ),
                          SizedBox(width: 18.0),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              padding: EdgeInsets.all(3.0),
                              child: TextFormField(
                                controller: dropOffControllet,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    hintText: "Where to ?",
                                    fillColor: Colors.grey[200],
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        top: 8.0, left: 11.0, bottom: 8.0)),
                                validator: (text) {},
                                onChanged: (String text) {
                                  cubit.findPlace(text);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (cubit.placePredictionListSeach)
                  LinearProgressIndicator(
                    color: Colors.grey[100],
                    backgroundColor: Colors.grey,
                  ),
                // tile for predictions
                (placePredictionList.length > 0)
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListView.separated(
                          padding: EdgeInsets.all(0.0),
                          itemBuilder: (context, index) {
                            return PredictionTile(
                                placePredictions:
                                    cubit.placePredictionList[index]);
                          },
                          separatorBuilder: (context, index) => DividerWidget(),
                          itemCount: cubit.placePredictionList.length,
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                        ),
                      )
                    : Container()
              ],
            ),
          );
        },
      ),
    );
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;
  const PredictionTile({Key? key, required this.placePredictions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        getPlaceAddressDetails(placePredictions.placeId ?? "", context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(placePredictions.mainText ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16.0)),
                      SizedBox(height: 3.0),
                      Text(placePredictions.secondaryText ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16.0, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (context) =>
            ProgressDialog(message: "Setting Dropoff, Please wait ..."));
    String plaseDetails =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var res = await RequestAssistant.getRequest(plaseDetails);

    Navigator.of(context).pop();

    if (res == "Failed") {
      return;
    }
    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      MainCubit.get(context).updateDropOffLocation(address);
      print("This is Drop off Location:: ${address.placeName}");
      Navigator.of(context).pop("obtainDirection");
    }
  }
}
