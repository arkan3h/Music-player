import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

Future settings(BuildContext context) {
  return (showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12))
    ),
    barrierColor: const Color(0xff09101D).withOpacity(0.7),
    builder: (context) => Container(
      height: 160,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Theme'
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Light'),
              const SizedBox(width: 10),
              Switch(
                value: AdaptiveTheme.of(context).mode.isDark,
                onChanged: (value) {
                  if (value) {
                    AdaptiveTheme.of(context).setDark();
                  } else {
                    AdaptiveTheme.of(context).setLight();
                  }
                },
              ),
              const SizedBox(width: 10),
              const Text('Dark'),
            ],
          ),
        ],
      ),
    )
  ));
}