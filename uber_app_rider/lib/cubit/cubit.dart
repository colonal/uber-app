import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uber_app_rider/AllScreens/mainscreen.dart';
import 'package:uber_app_rider/AllWidgets/progressDialog.dart';
import 'package:uber_app_rider/Assistarts/requestAssistant.dart';
import 'package:uber_app_rider/Models/address.dart';
import 'package:uber_app_rider/Models/history.dart';
import 'package:uber_app_rider/Models/placePredictions.dart';
import 'package:uber_app_rider/configMaps.dart';
import 'package:uber_app_rider/cubit/state.dart';

import '../main.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit() : super(LoginInitialState());

  static MainCubit get(context) => BlocProvider.of(context);

  bool isPassword = true;

  void isPasswordChange() {
    isPassword = !isPassword;
    emit(IsPasswordChangeState());
  }

  String uid = "";
  bool isRegisterLoading = false;
  void registerNewUser(BuildContext context,
      {password, name, email, phone}) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            ProgressDialog(message: "Authenticating, Please wait ..."));
    isRegisterLoading = true;
    emit(RegisterLoadingState());
    try {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

      final firebaseUser = (await _firebaseAuth
              .createUserWithEmailAndPassword(email: email, password: password)
              .catchError((onError) {
        showToast("Error $onError", context);
        isRegisterLoading = false;
      }))
          .user;

      if (firebaseUser != null) //user created
      {
        Map userDateMap = {
          "name": name,
          "email": email,
          "phone": phone,
        };
        usersRef.child(firebaseUser.uid).set(userDateMap);
        uid = firebaseUser.uid.toString();
        isRegisterLoading = false;
        Navigator.pop(context);
        emit(RegisterSuccessState());
        showToast("Congratulations, your account has been created.", context);
        Navigator.of(context)
            .pushNamedAndRemoveUntil(MainScreen.idScreen, (route) => false);
      } else {
        // error
        showToast("New user account has not been Created.", context);
        isRegisterLoading = false;
        Navigator.pop(context);
        emit(RegisterErrorState("Error"));
      }
    } catch (E) {
      Navigator.pop(context);
      isRegisterLoading = false;
      emit(RegisterErrorState("Error"));
    }
  }

  var showToast = (mess, context) => Fluttertoast.showToast(
      msg: mess,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);

  bool isLoginLoding = false;
  void loginAndAuthenticateUser(context, {password, email}) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            ProgressDialog(message: "Authenticating, Please wait ..."));
    isLoginLoding = true;
    emit(LoginLoadingState());

    try {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

      final firebaseUser = (await _firebaseAuth
              .signInWithEmailAndPassword(email: email, password: password)
              .catchError((onError) {
        showToast("Error $onError", context);
        isLoginLoding = false;
      }))
          .user;

      if (firebaseUser != null) {
        usersRef.child(firebaseUser.uid).once().then((DataSnapshot snap) {
          if (snap.value != null) {
            uid = firebaseUser.uid.toString();
            isRegisterLoading = false;
            Navigator.pop(context);
            emit(RegisterSuccessState());
            showToast("you are logged-in now", context);
            Navigator.of(context)
                .pushNamedAndRemoveUntil(MainScreen.idScreen, (route) => false);
          } else {
            _firebaseAuth.signOut();
            showToast(
                "No record exists for this user. Please create new account.",
                context);
            isRegisterLoading = false;
            Navigator.pop(context);
            emit(RegisterSuccessState());
            showToast("you are logged-in now", context);
          }
        });
      } else {
        // error
        showToast("Error Occured, can not Login", context);
        isRegisterLoading = false;
        Navigator.pop(context);
        emit(RegisterErrorState("Error"));
      }
    } catch (E) {
      showToast("Error Occured, can not Login", context);
      isRegisterLoading = false;
      Navigator.pop(context);
      emit(RegisterErrorState("Error"));
    }
  }

  Address? pickUpLocation;

  void updatePickUpLocation(Address picUpAddress) {
    pickUpLocation = picUpAddress;
    emit(PickUpLocationState());
  }

  Address? dropOffLocation;

  void updateDropOffLocation(Address dropOffAddress) {
    dropOffLocation = dropOffAddress;
    emit(DropOffLocationState());
  }

  bool placePredictionListSeach = false;
  List<PlacePredictions> placePredictionList = [];
  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      placePredictionListSeach = true;
      emit(FindPlaceState());
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&components=country:jo&key=$mapKey";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "Failed") {
        return;
      }

      if (res["status"] == "OK") {
        var predictions = res["predictions"];
        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();
        placePredictionList = placesList;
      }
      placePredictionListSeach = false;
      emit(FindPlaceState());
    }
  }

  int tripCount = 0;

  void updateTrips(int tripCounter) {
    tripCount = tripCounter;
    emit(UpdateTripsState());
  }

  List<String> tripHistoryKeys = [];

  void updateTripKeys(List<String> tripkeys) {
    tripHistoryKeys = tripkeys;
    emit(UpdateTripsState());
  }

  List<History> tripHistoryDataList = [];
  void updateTripHistoryData(History eachHistory) {
    tripHistoryDataList.add(eachHistory);
    emit(UpdateTripHistoryData());
  }
}
