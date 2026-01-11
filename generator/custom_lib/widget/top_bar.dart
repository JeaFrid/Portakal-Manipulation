
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:portakal/portakal.dart';

class PortakalTopWindow extends StatelessWidget {
  const PortakalTopWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          bold(context, "Portakal App🍊"),
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                appWindow.startDragging();
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.transparent),
                width: double.infinity,
                height: 20,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(5),
              border: Border(
                right: BorderSide(color: PortakalTheme.secondCardColor()),
              ),
            ),
            width: 26,
            height: 16,
          ),
          SizedBox(width: 7),
          Container(
            decoration: BoxDecoration(
              color: Colors.amber[700],
              borderRadius: BorderRadius.circular(5),
              border: Border(
                right: BorderSide(color: PortakalTheme.secondCardColor()),
                left: BorderSide(color: PortakalTheme.secondCardColor()),
              ),
            ),
            width: 26,
            height: 16,
          ),
          SizedBox(width: 7),
          Container(
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(5),
              border: Border(
                left: BorderSide(color: PortakalTheme.secondCardColor()),
              ),
            ),
            width: 26,
            height: 16,
          ),
        ],
      ),
    );
  }
}
