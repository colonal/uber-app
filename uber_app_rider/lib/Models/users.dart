import 'package:firebase_database/firebase_database.dart';

class Usersss {
  String? name;
  String? phone;
  String? email;
  String? id;

  Usersss({this.email, this.id, this.name, this.phone});

  Usersss.fromSnapshot(DataSnapshot dataSnapshot) {
    id = dataSnapshot.key;
    phone = dataSnapshot.value["phone"];
    name = dataSnapshot.value["name"];
    email = dataSnapshot.value["email"];
  }
}
