import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class ItemCreatePage extends StatefulWidget {
  final String caminho;
  const ItemCreatePage({super.key, required this.caminho});

  @override
  State<ItemCreatePage> createState() => _ItemCreatePageState();
}

class _ItemCreatePageState extends State<ItemCreatePage> {
  var formKey = GlobalKey<FormState>();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> fieldList = ["nome"];
  List<String> typeList = ["Descrição"];
  List valueList = [""];
  final TextEditingController novoCampoController = TextEditingController();
  late String? selectedType;

  @override
  void initState() {
    super.initState();
  }

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
        valueList.add('');
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Novo Item"),
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
                    ...List.generate(
                      fieldList.length,
                      (index) {
                        if (typeList[index] == 'Descrição') {
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
                        if (typeList[index] == 'Número Inteiro') {
                          return TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
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

                        if (typeList[index] == 'Número Decimal') {
                          return TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            // keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\,?\d{0,2}')),
                            ],
                            // maxLines: 1,
                            // maxLength: 30,
                            decoration: InputDecoration(
                              labelText: fieldList[index],
                              hintText: fieldList[index],
                            ),
                            onSaved: (newValue) =>
                                valueList[index] = double.parse(newValue!.replaceAll(',', '.')),
                            validator: validarItem,
                          );
                        }
              
                        if (typeList[index] == 'Calendário') {
                          late TextEditingController dataController =
                              TextEditingController(
                                  text: DateFormat('dd/MM/yyyy')
                                      .format(valueList[index]));
              
                          return TextFormField(
                            readOnly: true,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            // keyboardType: TextInputType.datetime,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^[0-9\/]*$')),
                              LengthLimitingTextInputFormatter(10),
                            ],
                            controller: dataController,
                            decoration: InputDecoration(
                              labelText: 'Data',
                              suffixIcon: InkWell(
                                onTap: () {
                                  selecionarData(context, index, dataController);
                                },
                                child: const Icon(Icons.calendar_today),
                              ),
                            ),
                            onTap: () {
                              selecionarData(context, index, dataController);
                            },
                            onSaved: (newValue) => valueList[index] =
                                DateFormat('dd/MM/yyyy').parse(newValue!),
                            validator: validarItem,
                          );
                        }

                        if (typeList[index] == 'Dinheiro'){
                          var moneyController = MoneyMaskedTextController(decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$', precision: 2);
                          return TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            keyboardType: TextInputType.number,
                            controller: moneyController,
                            // maxLines: 1,
                            // maxLength: 30,
                            decoration: InputDecoration(
                              labelText: fieldList[index],
                              hintText: fieldList[index],
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onSaved: (newValue) => valueList[index] = newValue!,
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
