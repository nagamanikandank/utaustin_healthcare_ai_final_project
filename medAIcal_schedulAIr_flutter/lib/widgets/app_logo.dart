import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule,
            size: size, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'medAIcal schedulAIr',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
