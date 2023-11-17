import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tg/components/loading.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
// import 'package:date_time_picker/date_time_picker.dart';

class ShowItemModal extends StatefulWidget {
  final BuildContext context;
  final DocumentSnapshot<Object?> document;
  final String caminho;

  const ShowItemModal({
    super.key,
    required this.context,
    required this.document,
    required this.caminho,
  });

  @override
  State<ShowItemModal> createState() => _ShowItemModalState();
}

class _ShowItemModalState extends State<ShowItemModal> {
  void deletarCampo(String id, String campo) {
    FirebaseFirestore.instance
        .collection(widget.caminho)
        .doc(widget.document.id)
        .update({campo: FieldValue.delete()});
  }

  // Future<void> selecionarData(BuildContext context, dynamic valor,
  //     TextEditingController editController) async {
  //   final DateTime? novaData = await showDatePicker(
  //     context: context,
  //     initialDate: valor,
  //     firstDate: DateTime(2023),
  //     lastDate: DateTime(2100),
  //     helpText: 'Selecione a data',
  //     cancelText: 'Cancelar',
  //     confirmText: 'Confirmar',
  //   );
  //   if (novaData != null && novaData != valor) {
  //     setState(() {
  //       valor = novaData;
  //       editController.text = DateFormat('dd/MM/yyyy').format(valor);
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String nomeEditado = '';
    // Map<String, dynamic>? data = widget.document.data() as Map<String, dynamic>?;

    void onNovoCampoCreated(String nome, var tipo) {
      setState(() {
        if (tipo == 'Descrição') {
          firestore.collection(widget.caminho).doc(widget.document.id).set(
            {nome: ''},
            SetOptions(merge: true),
          );
        }
        if (tipo == 'Número Inteiro') {
          firestore.collection(widget.caminho).doc(widget.document.id).set(
            {nome: 0},
            SetOptions(merge: true),
          );
        }
        if (tipo == 'Número Decimal') {
          firestore.collection(widget.caminho).doc(widget.document.id).set(
            {nome: 0.0},
            SetOptions(merge: true),
          );
        }
        if (tipo == 'Calendário') {
          firestore.collection(widget.caminho).doc(widget.document.id).set(
            {nome: DateTime.now()},
            SetOptions(merge: true),
          );
        }
        if (tipo == 'Dinheiro') {
          firestore.collection(widget.caminho).doc(widget.document.id).set(
            {nome: 'RS:0,00'},
            SetOptions(merge: true),
          );
        }
      });
    }

    Widget editField(
      String type,
      TextEditingController editController,
    ) {
      if (type == 'Número Inteiro') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                editController.text =
                    (int.parse(editController.text) - 1).toString();
                nomeEditado = editController.text;
              },
              icon: const Icon(Icons.remove),
            ),
            TextField(
              controller: editController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Novo valor',
                hintText: 'Novo valor',
              ),
              onChanged: (value) => nomeEditado = value,
            ),
            IconButton(
              onPressed: () {
                editController.text =
                    (int.parse(editController.text) + 1).toString();
                nomeEditado = editController.text;
              },
              icon: const Icon(Icons.add),
            ),
          ],
        );
      } else if (type == 'Número Decimal') {
        editController.text =
            editController.text.toString().replaceAll('.', ',');
        return TextField(
          controller: editController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\,?\d{0,2}'))
          ],
          decoration: const InputDecoration(
            labelText: 'Novo valor',
            hintText: 'Novo valor',
          ),
          onChanged: (value) => nomeEditado = value,
        );
      } else if (type == 'Calendário') {
        // dynamic valor = editController.text;
        var dataController = MaskedTextController(
          mask: '00/00/0000',
          text: editController.text,
        );

        return TextField(
          // readOnly: true,
          controller: dataController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[0-9\/]*$')),
            LengthLimitingTextInputFormatter(10)
          ],
          decoration: const InputDecoration(
            labelText: 'Novo valor',
            // suffixIcon: InkWell(
            //   onTap: () {
            //     selecionarData(context, valor, editController);
            //   },
            //   child: const Icon(Icons.calendar_today),
            // ),
          ),
          // onTap: () {
          //   selecionarData(context, valor, editController);
          // },
          onChanged: (value) => nomeEditado = value,
        );
      } else if (type == 'Descrição') {}
      return TextField(
        controller: editController,
        decoration: const InputDecoration(
          labelText: 'Novo valor',
          hintText: 'Novo valor',
        ),
        onChanged: (value) => nomeEditado = value,
      );
    }

    void editarCampo(String campo, dynamic valor, String id, String type) {
      final TextEditingController editController =
          TextEditingController(text: valor.toString());
      if (valor.runtimeType == Timestamp) {
        editController.text = DateFormat('dd/MM/yyyy').format(valor.toDate());
      }
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
                  Text("Editar $campo"),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      nomeEditado = '';
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: editField(type, editController),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    if (type == 'Calendário') {
                      firestore.collection(widget.caminho).doc(id).update(
                          {campo: DateFormat('dd/MM/yyyy').parse(nomeEditado)});
                    }
                    if (type == 'Número Inteiro') {
                      firestore
                          .collection(widget.caminho)
                          .doc(id)
                          .update({campo: int.parse(nomeEditado)});
                    }
                    if (type == 'Número Decimal') {
                      double novoValor;
                      if (!nomeEditado.contains(",")) {
                        novoValor = double.parse("$nomeEditado.0");
                      } else {
                        novoValor =
                            double.parse(nomeEditado.replaceAll(',', '.'));
                      }
                      firestore
                          .collection(widget.caminho)
                          .doc(id)
                          .update({campo: novoValor});
                    }
                    if (type == 'Descrição') {
                      firestore
                          .collection(widget.caminho)
                          .doc(id)
                          .update({campo: nomeEditado});
                    }
                    // if (type == 'Money'){
                    //   firestore
                    //     .collection(widget.caminho)
                    //     .doc(id)
                    //     .update({campo: nomeEditado});
                    // }

                    // firestore
                    //     .collection(widget.caminho)
                    //     .doc(id)
                    //     .update({campo: nomeEditado});

                    nomeEditado = '';
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Editar",
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: .4,
        maxChildSize: .7,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: Theme.of(context).cardColor,
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Center(
                        child: Container(
                          // decoration: BoxDecoration(
                          //   color: Theme.of(context).colorScheme.primary,
                          //   borderRadius: BorderRadius.circular(50),
                          // ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Text(
                            widget.document["Nome"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder(
                          stream: firestore
                              .collection(widget.caminho)
                              .doc(widget.document.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Loading();
                            } else if (snapshot.hasError) {
                              return Text(
                                  'Erro ao obter dados dos itens: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const Text('Nenhum item encontrado.');
                            }

                            final data =
                                snapshot.data?.data() as Map<String, dynamic>;
                            return ListView(
                              shrinkWrap: true,
                              children: [
                                ...data.entries.map((entry) {
                                  String campo = entry.key;
                                  dynamic valor = entry.value;

                                  //   return ListTile(
                                  //     title: Text('Campo: $campo'),
                                  //     subtitle: Text(
                                  //         'Valor: $valor, Tipo: ${valor.runtimeType}'),
                                  //   );
                                  // }).toList(),

                                  // bool isMoney = valor.runtimeType == Timestamp;
                                  String type;
                                  if (valor.runtimeType == Timestamp) {
                                    type = 'Calendário';
                                  } else if (valor.runtimeType == String) {
                                    type = 'Descrição';
                                  } else if (valor.runtimeType == int) {
                                    type = 'Número Inteiro';
                                  } else if (valor.runtimeType == double) {
                                    type = 'Número Decimal';
                                  } else {
                                    type = 'Money';
                                  }

                                  if (campo == "Nome") {
                                    return const SizedBox.shrink();
                                  }

                                  if (type == 'Descrição') {
                                    return ListTile(
                                      trailing: IconButton(
                                        onPressed: () => deletarCampo(
                                          widget.document.id,
                                          campo,
                                        ),
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                      ),
                                      title: Text(campo),
                                      subtitle: Text(valor.toString()),
                                      leading: IconButton(
                                        onPressed: () => editarCampo(
                                          campo,
                                          valor,
                                          widget.document.id,
                                          type,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    );
                                  }

                                  if (type == 'Número Inteiro') {
                                    return ListTile(
                                      trailing: IconButton(
                                        onPressed: () => deletarCampo(
                                          widget.document.id,
                                          campo,
                                        ),
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                      ),
                                      subtitle: Text(valor.toString()),
                                      title: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(campo),
                                          // IconButton(
                                          //   onPressed: () {
                                          //     setState(() {
                                          //       valor--;
                                          //     });
                                          //     FirebaseFirestore.instance
                                          //         .collection(widget.caminho)
                                          //         .doc(widget.document.id)
                                          //         .update({campo: valor});
                                          //   },
                                          //   icon: const Icon(Icons.remove),
                                          // ),
                                          // IconButton(
                                          //   onPressed: () {
                                          //     setState(() {
                                          //       valor++;
                                          //     });
                                          //     FirebaseFirestore.instance
                                          //         .collection(widget.caminho)
                                          //         .doc(widget.document.id)
                                          //         .update({campo: valor});
                                          //   },
                                          //   icon: const Icon(Icons.add),
                                          // ),
                                        ],
                                      ),
                                      leading: IconButton(
                                        onPressed: () => editarCampo(
                                          campo,
                                          valor,
                                          widget.document.id,
                                          type,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      // subtitle: Text(valor.toString()),
                                    );
                                  }

                                  if (type == 'Número Decimal') {
                                    return ListTile(
                                      trailing: IconButton(
                                        onPressed: () => deletarCampo(
                                          widget.document.id,
                                          campo,
                                        ),
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                      ),
                                      title: Text(campo),
                                      subtitle: Text(valor
                                          .toString()
                                          .replaceAll('.', ',')),
                                      leading: IconButton(
                                        onPressed: () => editarCampo(
                                          campo,
                                          valor,
                                          widget.document.id,
                                          type,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    );
                                  } else if (type == 'Calendário') {
                                    return ListTile(
                                      trailing: IconButton(
                                        onPressed: () => deletarCampo(
                                          widget.document.id,
                                          campo,
                                        ),
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                      ),
                                      title: Text(campo),
                                      subtitle: Text(DateFormat('dd/MM/yyyy')
                                          .format(valor.toDate())),
                                      leading: IconButton(
                                        onPressed: () => editarCampo(
                                          campo,
                                          valor,
                                          widget.document.id,
                                          type,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    );
                                  }

                                  return ListTile(
                                    trailing: IconButton(
                                      onPressed: () => deletarCampo(
                                        widget.document.id,
                                        campo,
                                      ),
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                    ),
                                    title: Text(campo),
                                    subtitle: Text(valor.toString()),
                                    leading: IconButton(
                                      onPressed: () => editarCampo(
                                        campo,
                                        valor,
                                        widget.document.id,
                                        type,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width -
                            40, //width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            String selectedType = 'Descrição';
                            TextEditingController novoCampoController =
                                TextEditingController(text: '');
                            showGeneralDialog(
                              context: context,
                              pageBuilder: (ctx, a1, a2) {
                                return Container();
                              },
                              transitionBuilder: (ctx, a1, a2, child) {
                                var curve =
                                    Curves.easeInOut.transform(a1.value);
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
                                          items: [
                                            'Descrição',
                                            'Número Inteiro',
                                            'Número Decimal',
                                            'Dinheiro',
                                            'Calendário'
                                          ].map((e) {
                                            return DropdownMenuItem<String>(
                                              value: e,
                                              child: Text(e),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            setState(() {
                                              selectedType = newValue!;
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
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            );
                          },
                          child: const Text("Adicionar"),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
