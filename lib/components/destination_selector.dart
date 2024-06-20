import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DestinationSelector extends StatefulWidget {
  final List<String> selectedUids;
  final Function(String) onDestinationSelected;

  const DestinationSelector({
    super.key,
    required this.selectedUids,
    required this.onDestinationSelected,
  });

  @override
  State<DestinationSelector> createState() => _DestinationSelectorState();
}

class _DestinationSelectorState extends State<DestinationSelector> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  late  String currentPath = 'users/${auth.currentUser!.uid}/MyInventory';
  List<String> folderHistory = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('Selecionar Destino'),
            leading: folderHistory.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        currentPath = folderHistory.removeLast();
                      });
                    },
                  )
                : Container(),
          ),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: firestore
                  .collection(currentPath)
                  .doc(auth.currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Nenhuma pasta encontrada.'));
                }

                var places =
                    snapshot.data!.get('places') as Map<String, dynamic>;
                var folders = places.entries
                    .where((entry) => !widget.selectedUids.contains(entry.key))
                    .toList();

                return ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    var folder = folders[index];
                    return ListTile(
                      title: Text(folder.value),
                      onTap: () {
                        setState(() {
                          folderHistory.add(currentPath);
                          currentPath = '$currentPath/${auth.currentUser!.uid}/${folder.key}';
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          widget.onDestinationSelected('$currentPath/${auth.currentUser!.uid}/${folder.key}');
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
