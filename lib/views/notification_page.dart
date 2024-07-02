import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> itemList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      var itemDocs = await firestore
          .collection('users/${auth.currentUser!.uid}/MyInventory')
          .where(auth.currentUser!.uid, whereNotIn: ['Lixeira']).get();

      List<Map<String, dynamic>> itemsWithDates = itemDocs.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data();
            DateTime? earliestDate;

            // Find the earliest date in the document
            data.forEach((key, value) {
              if (value is Timestamp) {
                DateTime date = value.toDate();
                if (earliestDate == null || date.isBefore(earliestDate!)) {
                  earliestDate = date;
                }
              }
            });

            return {
              'data': data,
              'earliestDate': earliestDate ?? DateTime(1970),
            };
          })
          .where((item) => item['earliestDate'] != DateTime(1970))
          .toList();

      // Sort the items by the earliest date
      itemsWithDates
          .sort((a, b) => a['earliestDate'].compareTo(b['earliestDate']));

      setState(() {
        itemList = itemsWithDates;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemList.isEmpty
              ? const Center(child: Text('Nenhum item para exibir'))
              : ListView.builder(
                  itemCount: itemList.length,
                  itemBuilder: (context, index) {
                    var item = itemList[index]['data'];
                    var earliestDate = itemList[index]['earliestDate'];
                    var formattedDate =
                        DateFormat('dd/MM/yyyy').format(earliestDate);

                    return ListTile(
                      title: Text(item['Nome'] ?? 'Sem Nome'),
                      subtitle: Text('Data: $formattedDate'),
                    );
                  },
                ),
    );
  }
}
