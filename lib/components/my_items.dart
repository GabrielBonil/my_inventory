import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/loading.dart';

class MyItems extends StatelessWidget {
  final DocumentSnapshot<Object?> document;
  const MyItems({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          // onTap: () => showModalBottomSheet(
          //   isScrollControlled: true,
          //   context: context,
          //   backgroundColor: Colors.transparent,
          //   shape: const RoundedRectangleBorder(
          //     borderRadius: BorderRadius.only(
          //         topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          //   ),
          //   builder: (context) => const SizedBox.shrink(),
          //   // PricesModal(context: context, productId: history.id),
          // ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      document['nome'], //.toCamelCase()
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
    );
  }
}