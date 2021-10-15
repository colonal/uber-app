import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_app_rider/cubit/cubit.dart';
import 'package:uber_app_rider/cubit/state.dart';
import 'package:uber_app_rider/shared/components/components.dart';

import 'registerationScreen.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = "login";
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    TextEditingController eController = TextEditingController();
    TextEditingController pController = TextEditingController();
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
                          "Login as a Rider",
                          style: TextStyle(
                              fontSize: 24.0, fontFamily: "Brand Bold"),
                        ),
                        SizedBox(height: 10),
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
                          controller: pController,
                          keyboardType: TextInputType.visiblePassword,
                          done: true,
                          labelText: "Password",
                          validator: (text) {
                            if (text.toString().isEmpty) {
                              return "Enter your Password";
                            }
                            if (text.toString().length < 7) {
                              return "Password must be atleast 7 Characters";
                            }
                            return null;
                          },
                          obscureText: cubit.isPassword,
                          icon: cubit.isPassword
                              ? Icons.remove_red_eye
                              : Icons.visibility_off_outlined,
                          suffixPressed: () {
                            cubit.isPasswordChange();
                          },
                        ),
                        SizedBox(height: 10),
                        cubit.isLoginLoding
                            ? CircularProgressIndicator()
                            : BuildButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    cubit.loginAndAuthenticateUser(
                                      context,
                                      password: pController.text,
                                      email: eController.text,
                                    );
                                  }
                                },
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                      fontSize: 18.0, fontFamily: "Brand Bold"),
                                ),
                              ),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  RegisterationScreen.idScreen,
                                  (route) => false);
                            },
                            child: Text(
                              "Do not have an Account? Register Here.",
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
