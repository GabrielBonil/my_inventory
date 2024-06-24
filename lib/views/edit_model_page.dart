// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditModelPage extends StatefulWidget {
  final String? modelName;
  final Map<String, String>? modelData;

  const EditModelPage({
    super.key,
    this.modelName,
    this.modelData,
  });

  @override
  State<EditModelPage> createState() => _EditModelPageState();
}

class _EditModelPageState extends State<EditModelPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  late String _userId;
  final TextEditingController _nameController = TextEditingController();
  List<String> fieldList = [];
  List<String> typeList = [];
  String? selectedType = 'Descrição';
  String? newFieldName;
  String originalName = '';

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid;
    if (widget.modelName != null) {
      originalName = widget.modelName!;
      _nameController.text = widget.modelName!;
      if (widget.modelData != null) {
        widget.modelData!.forEach((key, value) {
          fieldList.add(key);
          typeList.add(value);
        });
        // Garantindo que o "Nome" é o primeiro campo e ordenando o resto alfabéticamente
        if (fieldList.contains("Nome")) {
          int index = fieldList.indexOf("Nome");
          fieldList.removeAt(index);
          String type = typeList.removeAt(index);
          fieldList.insert(0, "Nome");
          typeList.insert(0, type);
        }
        List<MapEntry<String, String>> entries = List.generate(
          fieldList.length,
          (index) => MapEntry(fieldList[index], typeList[index]),
        );
        entries.sort((a, b) => a.key.compareTo(b.key));
        entries.insert(
            0,
            entries
                .removeAt(entries.indexWhere((entry) => entry.key == "Nome")));
        fieldList = entries.map((entry) => entry.key).toList();
        typeList = entries.map((entry) => entry.value).toList();
      }
    } else {
      fieldList.insert(0, "Nome");
      typeList.insert(0, "Descrição");
    }
  }

  Future<void> _saveModel() async {
    if (_formKey.currentState!.validate()) {
      Map<String, String> modelData = {};
      for (int i = 0; i < fieldList.length; i++) {
        modelData[fieldList[i]] = typeList[i];
      }

      if (originalName.isNotEmpty && originalName != _nameController.text) {
        await _firestore.collection('users').doc(_userId).update({
          originalName: FieldValue.delete(),
        });
      }

      await _firestore.collection('users').doc(_userId).update({
        _nameController.text: modelData,
      });
      Navigator.of(context).pop();
    }
  }

  void _addField() {
    setState(() {
      if (newFieldName != null && selectedType != null) {
        fieldList.add(newFieldName!);
        typeList.add(selectedType!);
      }
    });
    newFieldName = null;
    selectedType = 'Descrição';
  }

  void _removeField(int index) {
    setState(() {
      fieldList.removeAt(index);
      typeList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.modelName == null ? 'Adicionar Modelo' : 'Editar Modelo'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Modelo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o nome do modelo';
                  }
                  return null;
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: fieldList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(fieldList[index]),
                      subtitle: Text(typeList[index]),
                      trailing: fieldList[index] == "Nome"
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeField(index),
                            ),
                    );
                  },
                ),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nome do Campo'),
                onChanged: (value) {
                  newFieldName = value;
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: [
                  'Descrição',
                  'Número Inteiro',
                  'Número Decimal',
                  'Dinheiro',
                  'Calendário'
                ]
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tipo do Campo'),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addField,
                  child: const Text('Adicionar Campo'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveModel,
                  child: const Text('Salvar Modelo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
