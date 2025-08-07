import 'package:flutter/material.dart';

class DevPanel extends StatefulWidget {
  const DevPanel({super.key});

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Dev Panel - 待实现'),
      ),
    );
  }
}