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

  late String user = auth.currentUser!.uid;
  late String caminho = 'users/$user/MyInventory';
  late String currentPath = user;
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
              future: firestore.collection(caminho).doc(user).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Nenhuma pasta encontrada.'));
                }

                var places =
                    snapshot.data!.get('places') as Map<String, dynamic>;

                var folders = Map<String, dynamic>.from(
                  places
                    ..removeWhere((key, value) =>
                        value[auth.currentUser!.uid] != currentPath ||
                        widget.selectedUids.contains(key)),
                );

                folders = Map.fromEntries(folders.entries.toList()
                  ..sort((e1, e2) => e1.value['name']
                      .toLowerCase()
                      .compareTo(e2.value['name'].toLowerCase())));

                return Column(
                  children: [
                    ListTile(
                      title: const Text('Mover para o caminho atual'),
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          widget.onDestinationSelected(currentPath);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          var folderKey = folders.keys.elementAt(index);
                          var folder = folders[folderKey];
                          return ListTile(
                            title: Text(folder['name']),
                            onTap: () {
                              setState(() {
                                folderHistory.add(currentPath);
                                currentPath = folderKey;
                              });
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                widget.onDestinationSelected(folderKey);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
