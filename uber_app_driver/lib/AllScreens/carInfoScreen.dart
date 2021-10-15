import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_app_driver/cubit/cubit.dart';
import 'package:uber_app_driver/cubit/state.dart';
import 'package:uber_app_driver/shared/components/components.dart';

class CarInfoScreen extends StatelessWidget {
  static const String idScreen = "carinfo";

  final TextEditingController carModelController = TextEditingController();
  final TextEditingController carNumberController = TextEditingController();
  final TextEditingController carColorController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MainCubit, MainState>(
        listener: (context, state) {},
        builder: (context, state) {
          var cubit = MainCubit.get(context);
          return SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    SizedBox(height: 22.0),
                    Image.asset(
                      "assets/images/logo.png",
                      width: 390.0,
                      height: 250.0,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(22.0, 22.0, 22.0, 32.0),
                      child: Column(
                        children: [
                          SizedBox(height: 12.0),
                          Text(
                            "Enter Car Details",
                            style: TextStyle(fontSize: 24.0),
                          ),
                          SizedBox(height: 25.0),
                          BuildTextField(
                            controller: carModelController,
                            keyboardType: TextInputType.text,
                            labelText: "Car Model",
                            validator: (text) {
                              if (text.toString().isEmpty) {
                                return "Enter your Car Model";
                              }
                              // if (text.toString().length < 4) {
                              //   return "Name must be atleast 3 Characters";
                              // }
                              return null;
                            },
                          ),
                          SizedBox(height: 10.0),
                          BuildTextField(
                            controller: carNumberController,
                            keyboardType: TextInputType.text,
                            labelText: "Car Number",
                            validator: (text) {
                              if (text.toString().isEmpty) {
                                return "Enter your Car Number";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10.0),
                          BuildTextField(
                            controller: carColorController,
                            keyboardType: TextInputType.text,
                            labelText: "Car Color",
                            validator: (text) {
                              if (text.toString().isEmpty) {
                                return "Enter your Car Color";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 42.0),
                          cubit.isCarInfoLoading
                              ? CircularProgressIndicator()
                              : BuildButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      print("login");

                                      cubit.saveDriverCarInfo(
                                        context,
                                        model: carModelController.text,
                                        number: carNumberController.text,
                                        color: carColorController.text,
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        "NEXT",
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontFamily: "Brand Bold",
                                            color: Colors.grey),
                                      ),
                                      Icon(Icons.arrow_forward,
                                          color: Colors.grey)
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
