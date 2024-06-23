import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/show_item_modal.dart';

class MyItems extends StatelessWidget {
  final DocumentSnapshot<Object?> document;
  final String caminho;
  final String user;
  final bool longPress;
  final Function(String) longPressActive;
  final Function(String) incrementSelecionado;
  final Function(String) decrementSelecionado;
  final Function() handleSelected;
  final List<String> selected;
  final bool isSelected;
  const MyItems({
    super.key,
    required this.document,
    required this.caminho,
    required this.user,
    required this.longPress,
    required this.longPressActive,
    required this.incrementSelecionado,
    required this.decrementSelecionado,
    required this.handleSelected,
    required this.selected,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          if (longPress)
            Icon(
              isSelected
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank_sharp,
              color: Colors.blue,
            ),
          Expanded(
            child: Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                onLongPress: () {
                  handleSelected();
                  if (selected.contains(document.id)) {
                    decrementSelecionado(document.id);
                  } else {
                    longPressActive(document.id);
                  }
                },
                onTap: () {
                  handleSelected();

                  if (selected.contains(document.id)) {
                    decrementSelecionado(document.id);
                    return;
                  }

                  if (longPress) {
                    incrementSelecionado(document.id);
                    return;
                  }

                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16)),
                    ),
                    builder: (context) => ShowItemModal(
                      context: context,
                      document: document,
                      caminho: caminho,
                      user: user,
                    ),
                    // const SizedBox.shrink(),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        direction: Axis.vertical,
                        children: [
                          Text(
                            document['Nome'], //.toCamelCase()
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Text(
                          //   NumberFormat.currency(
                          //     locale: 'pt_BR',
                          //     decimalDigits: 2,
                          //     symbol: 'R\$',
                          //   ).format(history.price),
                          // )
                        ],
                      ),
                      // GestureDetector(
                      //   onTap: onTap,
                      //   child: history.isFavourite
                      //       ? const Icon(
                      //           Icons.favorite,
                      //           color: Colors.red,
                      //         )
                      //       : const Icon(
                      //           Icons.favorite_border,
                      //           color: Colors.red,
                      //         ),
                      // )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
