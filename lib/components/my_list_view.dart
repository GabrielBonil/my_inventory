import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyListView extends StatelessWidget {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  void update(String id, bool finished) {
    firestore.collection('items').doc(id).update({'finished': finished});
  }

  void delete(String id) {
    firestore.collection('items').doc(id).delete();
  }
  
  var lista = [];
  MyListView({super.key, required this.lista});

  @override
  Widget build(BuildContext context) {
    return ListView(
            children: lista
                .map(
                  (item) => Dismissible(
                    background: Container(
                      color: Colors.red,
                    ),
                    key: Key(item.id),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) => delete(item.id),
                    child: CheckboxListTile(
                      title: Text(item['name']),
                      // secondary: Icon(Icons.description),
                      value: item['finished'],
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['description'],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(item['date'].toDate()),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      onChanged: (value) => update(item.id, value!),
                    ),
                  ),
                )
                .toList(),
          );
  }
}