import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({this.width, this.height, this.radius = 4, super.key});
  final double? width, height, radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius!),
      ),
    );
  }
}