import 'package:cloud_firestore/cloud_firestore.dart';

class ListPlaces {
  List<String> filtrar = ['all'];

  Future<void> getPlaces() async {
    final CollectionReference places = FirebaseFirestore.instance.collection('places');
    QuerySnapshot queryPlaces = await places.get();
    DocumentSnapshot documentPlace = queryPlaces.docs.first;
    List<dynamic> arrayField = documentPlace['place'];
    for (var i in arrayField) {
      filtrar.add(i);
    }
  }
}