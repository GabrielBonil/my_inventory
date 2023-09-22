import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShowItemModal extends StatelessWidget {
  final BuildContext context;
  final DocumentSnapshot<Object?> document;

  const ShowItemModal({
    super.key,
    required this.context,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

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
                            document["nome"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (data != null)
                            ...data.entries.map((entry) {
                              String campo = entry.key;
                              dynamic valor = entry.value;

                              return ListTile(
                                title: Text('Campo: $campo'),
                                subtitle: Text(
                                    'Valor: $valor, Tipo: ${valor.runtimeType}'),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width -
                            40, //width: double.infinity,
                        child: const ElevatedButton(
                          onPressed: null,
                          child: Text("Salvar"),
                        ),
                      ),
                    ),
                  ],
                ),
                // FutureBuilder(
                //   future: ProductsService.get(documentId),
                //   builder: (context, snapshot) {
                //     if (!snapshot.hasData) {
                //       return const Loading();
                //     }

                //     var product = snapshot.data!.data()!;
                //     return Column(
                //       children: [
                //         Padding(
                //           padding: const EdgeInsets.only(top: 4, bottom: 8),
                //           child: Center(
                //             child: Container(
                //               decoration: BoxDecoration(
                //                 color: Theme.of(context).colorScheme.primary,
                //                 borderRadius: BorderRadius.circular(50),
                //               ),
                //               padding: const EdgeInsets.symmetric(
                //                   horizontal: 12, vertical: 4),
                //               child: Text(
                //                 product.name,
                //                 style: const TextStyle(
                //                   fontWeight: FontWeight.bold,
                //                   color: Colors.white,
                //                 ),
                //               ),
                //             ),
                //           ),
                //         ),
                //         Expanded(
                //           child: product.prices.isNotEmpty
                //               ? ListView.separated(
                //                   separatorBuilder: (context, index) =>
                //                       const Divider(),
                //                   itemCount: product.prices.length,
                //                   itemBuilder: (context, index) {
                //                     var currentPrice = product.prices[index];
                //                     var nextPrice = product.prices
                //                         .elementAtOrNull(index + 1);

                //                     Icon? icon;
                //                     if (nextPrice != null &&
                //                         currentPrice.value !=
                //                             nextPrice.value) {
                //                       icon = currentPrice.value >
                //                               nextPrice.value
                //                           ? const Icon(
                //                               Icons.arrow_circle_up_rounded,
                //                               color: Colors.red,
                //                             )
                //                           : const Icon(
                //                               Icons.arrow_circle_down_rounded,
                //                               color: Colors.green,
                //                             );
                //                     }
                //                     return ListTile(
                //                       title: Text(
                //                         NumberFormat.currency(
                //                           locale: 'pt_BR',
                //                           decimalDigits: 2,
                //                           symbol: 'R\$',
                //                         ).format(currentPrice.value),
                //                       ),
                //                       subtitle: Text(DateFormat("dd/MM/yyyy")
                //                           .format(
                //                               currentPrice.date.toDate())),
                //                       trailing: icon,
                //                     );
                //                   },
                //                 )
                //               : const Text("Sem preço"),
                //         ),
                //       ],
                //     );
                //   },
                // ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
