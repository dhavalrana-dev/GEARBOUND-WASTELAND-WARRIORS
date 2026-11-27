import 'package:flutter/material.dart';

import '../design_system/tokens.dart';
import '../features/campaign/campaign_hub_screen.dart';

export '../features/campaign/campaign_hub_screen.dart' show CampaignHubScreen;
export '../features/workshop/workshop_screen.dart'
    show GearboundGameWidget, WorkshopScreen;

class GearboundApp extends StatelessWidget {
  const GearboundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gearbound: Wasteland Warriors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: GbColors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: GbColors.ink,
        useMaterial3: true,
      ),
      home: const CampaignHubScreen(),
    );
  }
}
