import 'dart:io';
import 'package:flutter/material.dart';

String getOS() {
  return Platform.operatingSystem;
}

// ignore: must_be_immutable
class BuildTextField extends StatelessWidget {
  final controller;
  final keyboardType;
  final labelText;
  final obscureText;
  final String? Function(String?)? validator;
  bool done;
  IconData? icon;
  Function? suffixPressed;
  BuildTextField({
    required this.controller,
    required this.keyboardType,
    required this.labelText,
    required this.validator,
    this.obscureText = false,
    this.done = false,
    this.icon,
    this.suffixPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: done ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          suffixIcon: icon != null
              ? IconButton(
                  onPressed: () {
                    suffixPressed!();
                  },
                  icon: Icon(
                    icon,
                    // color: color,
                  ),
                )
              : null,
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 20.0, fontFamily: "Signatra"),
          hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          errorStyle: TextStyle(fontSize: 10.0, fontFamily: "Brand Bold"),
        ),
        style: TextStyle(fontSize: 14.0, fontFamily: "Brand Bold"),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}

class BuildButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;
  const BuildButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: MaterialButton(
        color: Colors.yellow,
        textColor: Colors.white,
        height: 40,
        minWidth: 200,
        onPressed: onPressed,
        child: child,
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(24)),
      ),
    );
  }
}

class DividerWidget extends StatelessWidget {
  const DividerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1.0,
      color: Colors.black,
      thickness: 1.0,
    );
  }
}
