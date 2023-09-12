import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItemCreatePage extends StatefulWidget {
  const ItemCreatePage({super.key});

  @override
  State<ItemCreatePage> createState() => _ItemCreatePageState();
}

class _ItemCreatePageState extends State<ItemCreatePage> {
  var formKey = GlobalKey<FormState>();

  String name = '';
  String description = '';
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  //Variáveis para o dropdown de prioridade
  final itens = ["baixa", "média", "alta"];
  int priorityIndex = 0;
  String? valorPrioridade;

  //Variáveis para o DataPicker
  late DateTime dataSelecionada;
  late TextEditingController dataController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  //InitState para selecionar a data de hoje/agora e deixar pré-fixado a prioridade baixa.
  @override
  void initState() {
    super.initState();
    dataSelecionada = DateTime.now();
    // dataController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada);
    valorPrioridade = itens[0]; //setState não necessário
  }

  //Selecionar a data, função
  Future<void> selecionarData(BuildContext context) async {
    final DateTime? novaData = await showDatePicker(
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (novaData != null && novaData != dataSelecionada) {
      setState(() {
        dataSelecionada = novaData;
        dataController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada);
      });
    }
  }

  void salvar(BuildContext context) {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      //salvar os dados no banco de dados...
      firestore.collection('items').add({
        'name': name,
        'finished': false,
        'priority': valorPrioridade,
        'priorityIndex': priorityIndex,
        'description': description,
        'date': dataSelecionada,
        'uid': auth.currentUser!.uid,
      });

      Navigator.of(context).pop();
    }
  }

  String? validarTarefa(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório. 😠';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Task"),
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
              validator: validarTarefa,
            ),

            //Decrição Tarefa
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              minLines: 1,
              maxLines: 5,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: "Descrição",
              ),
              onSaved: (newValue) => description = newValue!,
              validator: validarTarefa,
            ),

            //Prioridade
            DropdownButtonFormField<String>(
              value: valorPrioridade,
              items: itens.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  valorPrioridade = newValue;
                  priorityIndex = itens.indexOf(valorPrioridade!);
                });
              },
              decoration: const InputDecoration(
                labelText: 'Prioridade',
              ),
            ),
            
            //Data
            TextFormField(
              readOnly: true,
              controller: dataController,
              decoration: InputDecoration(
                labelText: 'Data',
                suffixIcon: InkWell(
                  onTap: () {
                    selecionarData(context);
                  },
                  child: const Icon(Icons.calendar_today),
                ),
              ),
              onTap: () {
                selecionarData(context);
              },
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
    );
  }
}