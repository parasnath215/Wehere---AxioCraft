import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class MockBannerAd extends StatelessWidget {
  const MockBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    // Hide ads for subscribed users
    if (appState.isSubscribed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on_rounded, color: Colors.black26, size: 20),
              SizedBox(width: 8),
              Text(
                'Advertisement / Reward Ad',
                style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
              child: const Text('AD', style: TextStyle(fontSize: 8, color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
