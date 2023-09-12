import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
