import 'package:flutter/material.dart';
import 'package:uber_app_rider/Assistarts/assistantMethods.dart';
import 'package:uber_app_rider/Models/history.dart';

class HistoryItme extends StatelessWidget {
  final History history;
  const HistoryItme(this.history);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                child: Row(
                  children: [
                    Image.asset("assets/images/pickicon.png",
                        height: 16, width: 16),
                    SizedBox(width: 18),
                    Expanded(
                        child: Container(
                      child: Text(
                        history.pickup ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(),
                      ),
                    )),
                    SizedBox(width: 5),
                    Text(
                      "\$${history.fares}",
                      style: TextStyle(
                          fontFamily: "Brand-Regular",
                          fontSize: 16,
                          color: Colors.black87),
                    )
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Image.asset("assets/images/desticon.png",
                      height: 16, width: 16),
                  SizedBox(width: 18),
                  Text(
                    history.dropOff ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                AssistantMethods.formatTripDate(history.createsAt ?? ""),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }
}
