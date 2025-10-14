import 'package:flutter/material.dart';
import 'vista_principal_items.dart';

class HeroListItemPage extends StatelessWidget {
  final int index;
  const HeroListItemPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero List Item Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Hero(
              tag: "hero_list_item_$index",
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: items[index].color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(
                    items[index].icon,
                    color: items[index].color,
                    size: 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              items[index].title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
