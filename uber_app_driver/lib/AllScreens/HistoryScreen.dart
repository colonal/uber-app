import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_app_driver/AllWidgets/HistoryItem.dart';
import 'package:uber_app_driver/cubit/cubit.dart';
import 'package:uber_app_driver/cubit/state.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trip History"),
        backgroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.keyboard_arrow_left),
        ),
      ),
      body: BlocConsumer<MainCubit, MainState>(
        listener: (context, state) {},
        builder: (context, state) {
          print("object");
          print("objectt ${MainCubit.get(context).tripHistoryDataList.length}");
          print("object");
          return ListView.separated(
            padding: EdgeInsets.all(0),
            itemBuilder: (context, index) =>
                HistoryItme(MainCubit.get(context).tripHistoryDataList[index]),
            separatorBuilder: (context, index) => Divider(
              thickness: 2,
              height: 3,
            ),
            itemCount: MainCubit.get(context).tripHistoryDataList.length,
            physics: ClampingScrollPhysics(),
            shrinkWrap: true,
          );
        },
      ),
    );
  }
}
