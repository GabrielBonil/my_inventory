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

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> fieldList = ["nome", 'qtd'];
  List<String> typeList = ["String", 'int'];
  List valueList = ["", 0];
  final TextEditingController novoCampoController = TextEditingController();
  late String? selectedType;

  //InitState para selecionar a data de hoje/agora e deixar pré-fixado a prioridade baixa.
  @override
  void initState() {
    super.initState();
  }

  void onNovoCampoCreated(String nome, var tipo) {
    setState(() {
      fieldList.add(nome);
      typeList.add(tipo);
      if (tipo == 'String') {
        valueList.add('');
      }
      if (tipo == 'int') {
        valueList.add(0);
      }
    });
  }

  void salvar(BuildContext context) {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      //salvar os dados no banco de dados...
      Map<String, dynamic> data = {};

      for (int i = 0; i < fieldList.length; i++) {
        data[fieldList[i]] =
            valueList[i]; // Cria um campo 'item_0', 'item_1', etc.
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("New Item"),
        ),
        body: Form(
          key: formKey,
          child: Stack(
            children: [
              ListView(
                children: [
                  ...List.generate(
                    fieldList.length,
                    (index) {
                      if (typeList[index] == 'String') {
                        return TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          // maxLines: 1,
                          // maxLength: 30,
                          decoration: InputDecoration(
                            labelText: fieldList[index],
                            hintText: fieldList[index],
                          ),
                          onSaved: (newValue) => valueList[index] = newValue!,
                          validator: validarItem,
                        );
                      }
                      if (typeList[index] == 'int') {
                        return TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          // maxLines: 1,
                          // maxLength: 30,
                          decoration: InputDecoration(
                            labelText: fieldList[index],
                            hintText: fieldList[index],
                          ),
                          onSaved: (newValue) =>
                              valueList[index] = int.parse(newValue!),
                          validator: validarItem,
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width -
                        40, //width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        selectedType = 'String';
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
                                      items: ['String', 'int'].map((e) {
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
                ],
              ),
              // Botão salvar
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
