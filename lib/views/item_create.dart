import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tg/components/field_model_builder.dart';

class ItemCreatePage extends StatefulWidget {
  final String caminho;
  const ItemCreatePage({super.key, required this.caminho});

  @override
  State<ItemCreatePage> createState() => _ItemCreatePageState();
}

class _ItemCreatePageState extends State<ItemCreatePage> {
  var formKey = GlobalKey<FormState>();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  
  List<String> fieldList = [];
  List<String> typeList = [];
  List valueList = [];
  final TextEditingController novoCampoController = TextEditingController();
  late String? selectedType;
  List<String> listaModelos = [];
  String? modeloSelecionado = "Padrão";

  void onNovoCampoCreated(String nome, var tipo) {
    setState(() {
      fieldList.add(nome);
      typeList.add(tipo);
      if (tipo == 'Descrição') {
        valueList.add('');
      }
      if (tipo == 'Número Inteiro') {
        valueList.add(0);
      }
      if (tipo == 'Número Decimal') {
        valueList.add(0.0);
      }
      if (tipo == 'Calendário') {
        valueList.add(DateTime.now());
      }
      if (tipo == 'Dinheiro') {
        valueList.add('0,00');
      }
    });
  }

  void salvar(BuildContext context) {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      //salvar os dados no banco de dados...
      Map<String, dynamic> data = {};

      for (int i = 0; i < fieldList.length; i++) {
        data[fieldList[i]] = valueList[i];
      }
      firestore.collection(widget.caminho).add(data);

      Navigator.of(context).pop();
    }
  }

  String? validarItem(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório. 😠';
    }

    return null;
  }

  Future<void> selecionarData(BuildContext context, int index,
      TextEditingController dataController) async {
    final DateTime? novaData = await showDatePicker(
      context: context,
      initialDate: valueList[index],
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (novaData != null && novaData != valueList[index]) {
      setState(() {
        valueList[index] = novaData;
        dataController.text = DateFormat('dd/MM/yyyy').format(valueList[index]);
      });
    }
  }

  void getModelos() async{
    listaModelos.clear();
    var documento = await firestore.collection('users').doc(auth.currentUser!.uid).get();
    documento.data()!.forEach((key, value) {
      setState(() {
        listaModelos.add(key);
      });
    });
    setState(() {
      listaModelos.add("Criar Modelo");
    });
  }

  void handleSelect(String? modelo) async{
    if (modelo != "Criar Modelo"){
      setState(() {
        fieldList.clear();
        typeList.clear();
        valueList.clear();
      });
      var documento = await firestore.collection('users').doc(auth.currentUser!.uid).get();
      Map<String, dynamic>? mapaSelecionado = documento.data()?[modelo];
      mapaSelecionado!.forEach((key, value) {
        // print("Key: $key | Value: $value");
        onNovoCampoCreated(key, value);
      });
    } else {
      String nomeModelo = '';
      showGeneralDialog(
        context: context,
        pageBuilder: (ctx, a1, a2) {
          return Container();
        },
        transitionBuilder: (ctx, a1, a2, child) {
          var curve = Curves.easeInOut.transform(a1.value);
          return Transform.scale(
            scale: curve,
            child: AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Criar Modelo"),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: TextField(
                // controller: _subcollectionNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Modelo',
                  hintText: 'Nome do Modelo',
                ),
                onChanged: (value) => nomeModelo = value,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    Map<String, dynamic> novoMapa = {};
                    for (int i = 0; i < fieldList.length; i++) {
                      novoMapa[fieldList[i]] = typeList[i];
                    }

                    await firestore
                        .collection('users')
                        .doc(auth.currentUser!.uid)
                        .update({nomeModelo: novoMapa});

                    getModelos();
                    modeloSelecionado = nomeModelo;
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Criar",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getModelos();
    handleSelect("Padrão");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Novo Item"),
          actions: [
            DropdownButton<String>(
              underline: const SizedBox.shrink(),
              focusNode: FocusNode(canRequestFocus: false),
              value: modeloSelecionado,
              // style: const TextStyle(color: Colors.white),
              items: listaModelos.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  modeloSelecionado = newValue;
                  handleSelect(newValue);
                });
              },
            ),
          ],
        ),
        body: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    FieldModelBuilder(
                      context: context,
                      fieldList: fieldList,
                      typeList: typeList,
                      valueList: valueList,
                      validarItem: validarItem,
                      selecionarData: selecionarData,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width -
                          40, //width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          selectedType = 'Descrição';
                          showGeneralDialog(
                            context: context,
                            pageBuilder: (ctx, a1, a2) {
                              return Container();
                            },
                            transitionBuilder: (ctx, a1, a2, child) {
                              var curve = Curves.easeInOut.transform(a1.value);
                              return Transform.scale(
                                scale: curve,
                                child: AlertDialog(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Criar campo"),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: novoCampoController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nome do campo',
                                        ),
                                      ),
                                      DropdownButtonFormField<String>(
                                        value: selectedType,
                                        items: ['Descrição', 'Número Inteiro', 'Número Decimal', 'Dinheiro', 'Calendário'].map((e) {
                                          return DropdownMenuItem<String>(
                                            value: e,
                                            child: Text(e),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          setState(() {
                                            selectedType = newValue;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Tipo do campo',
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        String novoCampo =
                                            novoCampoController.text;
                                        if (novoCampo.isNotEmpty) {
                                          Navigator.pop(context);
                                          onNovoCampoCreated(
                                              novoCampo, selectedType);
                                        }
                                        novoCampoController.clear();
                                      },
                                      child: const Text(
                                        "Criar",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 300),
                          );
                        },
                        child: const Text("Criar campo"),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Botão salvar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width -
                      40, //width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => salvar(context),
                    child: const Text("Salvar"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
