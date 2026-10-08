import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/app_state.dart';

import '../../widgets/sos/sos_pulsing_button.dart';

class SosHelpScreen extends StatelessWidget {
  const SosHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SOS Help', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(width: 6),
            Text('🚨', style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showHowItWorksDialog(context),
            icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'How it works',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Title & Reassurance
              Text(
                'You matter. We’re here for you.',
                style: AppTextStyles.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'If you’re feeling overwhelmed or in distress,\nreach out for support now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  SizedBox(width: 4),
                  Text('💜', style: TextStyle(fontSize: 14)),
                ],
              ),

              const SizedBox(height: 28),

              // Animated Pulsing Red "I Need Help Now" Trigger
              SosPulsingButton(
                onTap: () {
                  _triggerImmediateEmergencyHelp(context);
                },
              ),

              const SizedBox(height: 32),

              // "Talk to Someone Now" Card (Mockup 1.17.17 AM)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.chat_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Talk to Someone Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Connect with a mental health professional',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // 1. 24/7 Helpline
                    _buildHelplineRow(
                      context: context,
                      icon: Icons.headset_mic_rounded,
                      title: '24/7 Helpline: 988 / 14416',
                      subtitle: 'US/Intl: 988 • India: 14416 (Tele-MANAS)',
                      actionLabel: 'Call Now',
                      isCall: true,
                    ),

                    const Divider(height: 20, color: AppColors.cardBorder),

                    // 2. Chat Support
                    _buildHelplineRow(
                      context: context,
                      icon: Icons.chat_bubble_rounded,
                      title: 'Crisis Chat: 741741',
                      subtitle: 'SMS "HOME" to 741741 • Vandrevala: +91 9999 666 555',
                      actionLabel: 'Chat Now',
                      isCall: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // "Instant Calming Tools" Row
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Instant Calming Tools 🌿', style: AppTextStyles.h3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCalmingToolCard(
                      icon: Icons.air_rounded,
                      iconColor: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      title: '4-7-8 Deep\nBreathing',
                      subtitle: 'Slow down heart rate',
                      onTap: () => _showBreathingExercise(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCalmingToolCard(
                      icon: Icons.accessibility_new_rounded,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFD1FAE5),
                      title: '5-4-3-2-1\nGrounding',
                      subtitle: 'Reconnect with senses',
                      onTap: () => _showGroundingTechnique(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // "More Support Options" Grid
              Align(
                alignment: Alignment.centerLeft,
                child: Text('More Support Options', style: AppTextStyles.h3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [

                  Expanded(
                    child: _buildSupportOptionCard(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.primary,
                      title: 'Crisis\nResources',
                      subtitle: 'Helplines for 988, Trevor, Veterans',
                      onTap: () => _showCrisisResourcesSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSupportOptionCard(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'Trusted\nContacts',
                      subtitle: '${appState.emergencyContacts.length} people added',
                      onTap: () => _showTrustedContactsManager(context, appState),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Affirmation Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F1FE), Color(0xFFECE7FD)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'It’s okay to ask for help.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You are not alone. Your feelings are valid. Better days are ahead. 💜',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Disclaimer
              Text(
                AppConstants.therapyDisclaimer,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.35),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalmingToolCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required bool isCall,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Icon(Icons.circle, size: 6, color: AppColors.onlineGreen),
                  SizedBox(width: 4),
                  Text('Available Now', style: TextStyle(fontSize: 10, color: AppColors.onlineGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(90, 36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () {
            _simulateCallOrChat(context, isCall ? 'Connecting you to 24/7 Helpline (988)...' : 'Connecting you to Confidential Crisis Chat (741741)...');
          },
          child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSupportOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.2)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_rounded, size: 14, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerImmediateEmergencyHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: AppColors.sosRed, size: 28),
            SizedBox(width: 8),
            Text('Immediate Support 🚨'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reach a confidential, free 24/7 crisis counselor right now:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('• 988: Suicide & Crisis Lifeline (US & International)\n'
                '• 14416: Tele-MANAS (Govt of India Toll-Free 24/7)\n'
                '• +91 9999 666 555: Vandrevala Foundation\n'
                '• SMS 741741: Crisis Text Line',
                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _simulateCallOrChat(context, 'Dialing Tele-MANAS (14416 Toll-Free)... 🇮🇳');
            },
            child: const Text('Call 14416 (India)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
            onPressed: () {
              Navigator.pop(ctx);
              _simulateCallOrChat(context, 'Calling 24/7 Lifeline (988)... Free & Confidential.');
            },
            child: const Text('Call 988 (Intl)'),
          ),
        ],
      ),
    );
  }

  void _simulateCallOrChat(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showCrisisResourcesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Crisis Resources & Helplines 🛡️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Free, confidential support available 24/7 for you or loved ones.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...AppConstants.crisisHelplines.map((item) {
              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.support_agent_rounded, color: AppColors.primary)),
                title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${item['number']} • ${item['hours']}'),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.call, size: 14),
                  label: const Text('Call', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _simulateCallOrChat(context, 'Dialing ${item['name']} (${item['number']})...');
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showTrustedContactsManager(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final contacts = appState.emergencyContacts;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trusted Contacts 🤝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('These contacts will receive a gentle check-in alert when you need reassurance.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Supportive Alert to All', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Supportive check-in alert sent to your ${contacts.length} trusted contacts! 💜')),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Saved Contacts (${contacts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          _showAddContactDialog(context, appState, () => setModalState(() {}));
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, i) {
                        final c = contacts[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFFFFEDD5), child: Icon(Icons.person, color: Color(0xFFF97316))),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${c.relationship} • ${c.phone}', style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                appState.removeEmergencyContact(c.id);
                                setModalState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, AppState appState, VoidCallback onAdded) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Add Trusted Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Sarah')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+91 98000 00000')),
            const SizedBox(height: 8),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship', hintText: 'e.g. Best Friend, Sibling')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), ''); // Strip non-digits for validation
              
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(dCtx).showSnackBar(const SnackBar(content: Text('Please fill required fields.')));
                return;
              }

              final isRepeated = RegExp(r'^(\d)\1{9}$').hasMatch(phone);
              final isSeries = RegExp(r'^(0123456789|1234567890|9876543210)$').hasMatch(phone);

              if (phone.length != 10 || isRepeated || isSeries) {
                ScaffoldMessenger.of(dCtx).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit phone number.')));
                return;
              }

              appState.addEmergencyContact(name, phone, relCtrl.text.trim().isEmpty ? 'Friend' : relCtrl.text.trim());
              Navigator.pop(dCtx);
              onAdded();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBreathingExercise(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _BreathingExerciseSheet(),
    );
  }

  void _showGroundingTechnique(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _GroundingExerciseSheet(),
    );
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('How SOS Help Works'),
        content: const Text(
          '1. Confidential: Your identity is 100% protected.\n\n'
          '2. Immediate: Connect via direct call or instant private chat.\n\n'
          '3. Free: Available round-the-clock at zero cost.\n\n'
          '4. Always Accessible: Reachable from the home screen, chat room, or dedicated SOS tab.',
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }
}

class _BreathingExerciseSheet extends StatefulWidget {
  const _BreathingExerciseSheet();

  @override
  State<_BreathingExerciseSheet> createState() => _BreathingExerciseSheetState();
}

class _BreathingExerciseSheetState extends State<_BreathingExerciseSheet> {
  int _secondsLeft = 4;
  String _phase = 'Inhale';
  String _instruction = 'Tap Play to begin breathing...';
  Timer? _timer;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    // Do not start automatically
  }

  void _startCycle() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          if (_phase == 'Inhale') {
            _phase = 'Hold';
            _secondsLeft = 7;
            _instruction = 'Hold your breath gently...';
          } else if (_phase == 'Hold') {
            _phase = 'Exhale';
            _secondsLeft = 8;
            _instruction = 'Exhale completely through your mouth...';
          } else {
            _phase = 'Inhale';
            _secondsLeft = 4;
            _instruction = 'Breathe in slowly through your nose...';
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _phase == 'Inhale' ? 1.3 : (_phase == 'Hold' ? 1.3 : 0.85);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('4-7-8 Mindful Breathing 🌬️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_instruction, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          // Animated breathing circle
          GestureDetector(
            onTap: () {
              setState(() {
                _isActive = !_isActive;
                if (_isActive) {
                  _startCycle();
                } else {
                  _timer?.cancel();
                }
              });
            },
            child: AnimatedScale(
              scale: scale,
              duration: Duration(seconds: _secondsLeft > 0 ? _secondsLeft : 1),
              curve: Curves.easeInOut,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFBAE6FD), Color(0xFF0284C7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isActive ? _phase : 'Play', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    if (_isActive) const SizedBox(height: 4),
                    if (_isActive) Text('$_secondsLeft s', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GroundingExerciseSheet extends StatefulWidget {
  const _GroundingExerciseSheet();

  @override
  State<_GroundingExerciseSheet> createState() => _GroundingExerciseSheetState();
}

class _GroundingExerciseSheetState extends State<_GroundingExerciseSheet> {
  final Map<int, bool> _checked = {};

  final steps = const [
    {'title': '5 Things You Can SEE', 'desc': 'Look around and notice 5 distinct objects near you (a plant, a clock, shadows).', 'emoji': '👀'},
    {'title': '4 Things You Can TOUCH', 'desc': 'Notice 4 physical textures (your clothes, chair, phone surface, cool air).', 'emoji': '✋'},
    {'title': '3 Things You Can HEAR', 'desc': 'Listen carefully for 3 sounds (fan hum, birds, distance traffic, breath).', 'emoji': '👂'},
    {'title': '2 Things You Can SMELL', 'desc': 'Notice 2 scents (soap, tea, room scent, or fresh air).', 'emoji': '🌸'},
    {'title': '1 Thing You Can TASTE', 'desc': 'Notice 1 taste in your mouth, or take a sip of cool water.', 'emoji': '🍵'},
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount = _checked.values.where((v) => v).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('5-4-3-2-1 Sensory Grounding 🧘', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Completed $completedCount of 5 steps to anchor yourself into the present moment.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedCount / 5,
              minHeight: 6,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: steps.length,
              itemBuilder: (context, i) {
                final s = steps[i];
                final isChecked = _checked[i] ?? false;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _checked[i] = !isChecked;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isChecked ? const Color(0xFFECFDF5) : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isChecked ? const Color(0xFF10B981) : Colors.transparent),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['emoji']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isChecked ? const Color(0xFF047857) : AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(s['desc']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(
                          isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isChecked ? const Color(0xFF10B981) : AppColors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (completedCount == 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grounding complete! You are grounded and safe. 🌿')),
                    );
                  },
                  child: const Text('I Feel Grounded 🌿', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
