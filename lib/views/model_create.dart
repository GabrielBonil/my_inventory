// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class ModelCreate extends StatefulWidget {
//   const ModelCreate({super.key});

//   @override
//   State<ModelCreate> createState() => _ModelCreateState();
// }

// class _ModelCreateState extends State<ModelCreate> {
//   var formKey = GlobalKey<FormState>();

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;

//   String nomeModelo = '';
//   List<String> keyList = ["Nome"];
//   List<String> valueList = ["Descrição"];

//   void salvar(BuildContext context) {
//     if (formKey.currentState!.validate()) {
//       formKey.currentState!.save();

//       //salvar os dados no banco de dados...
//       // Map<String, dynamic> data = {};

//       // for (int i = 0; i < fieldList.length; i++) {
//       //   data[fieldList[i]] = valueList[i];
//       // }
//       // firestore.collection(widget.caminho).add(data);

//       Navigator.of(context).pop();
//     }
//   }

//   String? validarItem(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Campo obrigatório. 😠';
//     }

//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("Novo Modelo"),
//         ),
//         body: Form(
//           key: formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Expanded(
//                 child: ListView(
//                   shrinkWrap: true,
//                   children: [
//                     TextFormField(
//                       autovalidateMode: AutovalidateMode.onUserInteraction,
//                       decoration: const InputDecoration(
//                         labelText: "Nome do Modelo",
//                         hintText: "Nome do Modelo",
//                       ),
//                       onSaved: (newValue) => nomeModelo = newValue!,
//                       validator: validarItem,
//                     ),

//                     SizedBox(
//                       width: MediaQuery.of(context).size.width - 40,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           selectedType = 'Descrição';
//                           showGeneralDialog(
//                             context: context,
//                             pageBuilder: (ctx, a1, a2) {
//                               return Container();
//                             },
//                             transitionBuilder: (ctx, a1, a2, child) {
//                               var curve = Curves.easeInOut.transform(a1.value);
//                               return Transform.scale(
//                                 scale: curve,
//                                 child: AlertDialog(
//                                   title: Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       const Text("Criar campo"),
//                                       IconButton(
//                                         onPressed: () {
//                                           Navigator.of(context).pop();
//                                         },
//                                         icon: const Icon(Icons.close),
//                                       ),
//                                     ],
//                                   ),
//                                   content: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       TextField(
//                                         controller: novoCampoController,
//                                         decoration: const InputDecoration(
//                                           labelText: 'Nome do campo',
//                                         ),
//                                       ),
//                                       DropdownButtonFormField<String>(
//                                         value: selectedType,
//                                         items: [
//                                           'Descrição',
//                                           'Número Inteiro',
//                                           'Número Decimal',
//                                           'Dinheiro',
//                                           'Calendário'
//                                         ].map((e) {
//                                           return DropdownMenuItem<String>(
//                                             value: e,
//                                             child: Text(e),
//                                           );
//                                         }).toList(),
//                                         onChanged: (newValue) {
//                                           setState(() {
//                                             selectedType = newValue;
//                                           });
//                                         },
//                                         decoration: const InputDecoration(
//                                           labelText: 'Tipo do campo',
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   actions: <Widget>[
//                                     TextButton(
//                                       onPressed: () {
//                                         String novoCampo =
//                                             novoCampoController.text;
//                                         if (novoCampo.isNotEmpty) {
//                                           Navigator.pop(context);
//                                           onNovoCampoCreated(
//                                               novoCampo, selectedType);
//                                         }
//                                         novoCampoController.clear();
//                                       },
//                                       child: const Text(
//                                         "Criar",
//                                         style: TextStyle(
//                                           color: Colors.red,
//                                           fontSize: 17,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                             transitionDuration:
//                                 const Duration(milliseconds: 300),
//                           );
//                         },
//                         child: const Text("Novo Campo"),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                   ],
//                 ),
//               ),
//               // Botão salvar
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: SizedBox(
//                   width: MediaQuery.of(context).size.width -
//                       40, //width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => salvar(context),
//                     child: const Text("Salvar"),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
