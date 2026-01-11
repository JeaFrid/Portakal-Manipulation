import 'package:flutter/material.dart';
import 'package:portakal/portakal.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PManagerScaffold(
      listenables: [],
      body: () {
        return Column();
      },
    );
  }
}
