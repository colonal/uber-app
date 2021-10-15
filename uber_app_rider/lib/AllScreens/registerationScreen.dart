import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_app_rider/cubit/cubit.dart';
import 'package:uber_app_rider/cubit/state.dart';
import 'package:uber_app_rider/shared/components/components.dart';

import 'loginScreen.dart';

// ignore: must_be_immutable
class RegisterationScreen extends StatelessWidget {
  static const String idScreen = "register";
  final TextEditingController eController = TextEditingController();
  final TextEditingController pController = TextEditingController();
  final TextEditingController rpController = TextEditingController();
  final TextEditingController nController = TextEditingController();
  final TextEditingController poController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {},
      builder: (context, state) {
        var cubit = MainCubit.get(context);
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 35.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Hero(
                          tag: "logo",
                          child: Image(
                            image: AssetImage("assets/images/logo.png"),
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Text(
                          "Register as a Rider",
                          style: TextStyle(
                              fontSize: 24.0, fontFamily: "Brand Bold"),
                        ),
                        SizedBox(height: 10),
                        BuildTextField(
                          controller: nController,
                          keyboardType: TextInputType.text,
                          labelText: "Name",
                          validator: (text) {
                            if (text.toString().isEmpty) {
                              return "Enter your Name";
                            }
                            if (text.toString().length < 4) {
                              return "Name must be atleast 3 Characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 5),
                        BuildTextField(
                          controller: eController,
                          keyboardType: TextInputType.emailAddress,
                          labelText: "Email",
                          validator: (text) {
                            if (text.toString().isEmpty) {
                              return "Enter your Email";
                            }
                            if (!text.toString().contains("@")) {
                              return "Email is not valid.";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 5),
                        BuildTextField(
                          controller: poController,
                          keyboardType: TextInputType.phone,
                          labelText: "Phone",
                          validator: (text) {
                            if (text.toString().isEmpty) {
                              return "Enter your Phone";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 5),
                        BuildTextField(
                          controller: pController,
                          keyboardType: TextInputType.visiblePassword,
                          labelText: "Password",
                          obscureText: cubit.isPassword,
                          icon: cubit.isPassword
                              ? Icons.remove_red_eye
                              : Icons.visibility_off_outlined,
                          suffixPressed: () {
                            cubit.isPasswordChange();
                          },
                          validator: (text) {
                            if (text.toString().isEmpty) {
                              return "Enter your Password";
                            }
                            if (text.toString().length < 7) {
                              return "Password must be atleast 7 Characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        BuildTextField(
                          controller: rpController,
                          keyboardType: TextInputType.visiblePassword,
                          done: true,
                          labelText: "Retype Password",
                          obscureText: true,
                          validator: (text) {
                            if (rpController.text != pController.text) {
                              return "Retype password does not match the password";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        cubit.isRegisterLoading
                            ? CircularProgressIndicator()
                            : BuildButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    print("login");
                                    cubit.registerNewUser(
                                      context,
                                      name: nController.text.trim(),
                                      email: eController.text.trim(),
                                      phone: pController.text.trim(),
                                      password: pController.text,
                                    );
                                  }
                                },
                                child: Text(
                                  "Register",
                                  style: TextStyle(
                                      fontSize: 18.0, fontFamily: "Brand Bold"),
                                ),
                              ),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  LoginScreen.idScreen, (route) => false);
                            },
                            child: Text(
                              "Already have an Account? Login Here.",
                              style: TextStyle(
                                  fontSize: 12.0, fontFamily: "Brand Bold"),
                            ))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
