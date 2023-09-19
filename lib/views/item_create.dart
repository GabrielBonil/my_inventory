import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemCreatePage extends StatefulWidget {
  final String caminho;
  const ItemCreatePage({super.key, required this.caminho});

  @override
  State<ItemCreatePage> createState() => _ItemCreatePageState();
}

class _ItemCreatePageState extends State<ItemCreatePage> {
  var formKey = GlobalKey<FormState>();

  String name = '';
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //InitState para selecionar a data de hoje/agora e deixar pré-fixado a prioridade baixa.
  @override
  void initState() {
    super.initState();
  }

  void salvar(BuildContext context) {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      //salvar os dados no banco de dados...
      firestore.collection(widget.caminho).add({
        'nome': name,
      });

      Navigator.of(context).pop();
    }
  }

  String? validarItem(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório. 😠';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("New Item"),
        ),
        body: Form(
          key: formKey,
          child: Column(
            children: [
              //Nome Tarefa
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLines: 1,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: "Nome",
                ),
                onSaved: (newValue) => name = newValue!,
                validator: validarItem,
              ),

              // Botão salvar
              SizedBox(
                width: MediaQuery.of(context).size.width -
                    40, //width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => salvar(context),
                  child: const Text("Salvar"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
