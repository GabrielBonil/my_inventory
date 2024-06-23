import 'package:myinventory/views/edit_model_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModelManagementPage extends StatefulWidget {
  const ModelManagementPage({super.key});

  @override
  State<ModelManagementPage> createState() => _ModelManagementPageState();
}

class _ModelManagementPageState extends State<ModelManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  Map<String, dynamic> _models = {};

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid;
    _loadModels();
  }

  Future<void> _loadModels() async {
    var doc = await _firestore.collection('users').doc(_userId).get();
    if (doc.exists) {
      setState(() {
        _models = Map<String, dynamic>.from(doc.data() ?? {});

        _models = Map.fromEntries(_models.entries.toList()
          ..sort((e1, e2) =>
              e1.key.toLowerCase().compareTo(e2.key.toLowerCase())));
        //_models.remove('places');
      });
    }
  }

  Future<void> _deleteModel(String modelName) async {
    _models.remove(modelName);
    await _firestore.collection('users').doc(_userId).update({
      modelName: FieldValue.delete(),
    });
    await _loadModels();
  }

  void _navigateToEditPage(
      {String? modelName, Map<String, String>? modelData}) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EditModelPage(
          modelName: modelName,
          modelData: modelData,
        ),
      ),
    )
        .then((_) {
      _loadModels(); // Reload models after coming back from the edit page
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Modelos'),
      ),
      body: ListView.builder(
        itemCount: _models.length,
        itemBuilder: (context, index) {
          String modelName = _models.keys.elementAt(index);
          Map<String, String> modelData =
              Map<String, String>.from(_models[modelName]);

          return ListTile(
            title: Text(modelName),
            subtitle: Text(modelData.toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditPage(
                      modelName: modelName, modelData: modelData),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _deleteModel(modelName);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
