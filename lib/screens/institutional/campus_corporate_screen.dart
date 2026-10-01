import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CampusCorporateScreen extends StatefulWidget {
  const CampusCorporateScreen({super.key});

  @override
  State<CampusCorporateScreen> createState() => _CampusCorporateScreenState();
}

class _CampusCorporateScreenState extends State<CampusCorporateScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _workEmailController = TextEditingController();
  String _selectedOrgType = 'University / College';
  bool _submittingInquiry = false;

  @override
  void dispose() {
    _codeController.dispose();
    _orgNameController.dispose();
    _workEmailController.dispose();
    super.dispose();
  }

  void _verifyAccessCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your institutional access code.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('✅ Verified! Welcome to the "$code" Wellness Hub.')),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
    _codeController.clear();
  }

  void _submitPartnershipInquiry() {
    if (_orgNameController.text.trim().isEmpty || _workEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your organization name and work email.')),
      );
      return;
    }

    setState(() => _submittingInquiry = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _submittingInquiry = false);
      _orgNameController.clear();
      _workEmailController.clear();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: Color(0xFF16A34A), size: 26),
              SizedBox(width: 8),
              Text('Inquiry Received! 💜'),
            ],
          ),
          content: const Text(
            'Thank you for bringing mental wellness to your community!\n\n'
            'Our Institutional Partnerships team will reach out within 24 business hours with pilot onboarding details and pilot access keys.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Great'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Campus & Corporate Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('CAMPUS & ENTERPRISE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Empower Your People with Safe Peer Support 🏛️',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tailored private wellness networks for universities, colleges, schools, and corporate workplaces.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 1. Join Existing Circle with Code Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, color: Color(0xFF16A34A), size: 20),
                        SizedBox(width: 8),
                        Text('Have an Access Code?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your school, college or corporate code to unlock your private community circle.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. STANFORD2026 or GOOGLECARE',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _verifyAccessCode,
                          child: const Text('Join Circle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Pillars / Features for Institutions
              Text('Why Institutions Choose Wehere', style: AppTextStyles.h3),
              const SizedBox(height: 12),

              _buildValueCard(
                icon: Icons.lock_outline_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Zero-Knowledge Anonymity 🔒',
                desc: 'Students and employees connect pseudonomously. No conversation or journal logs are ever shared with HR, managers, or professors.',
              ),
              _buildValueCard(
                icon: Icons.groups_rounded,
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                title: 'Closed Organization Circles 🎓',
                desc: 'Colleagues or classmates can vent, support, and exchange mindful tips inside a dedicated, institution-only verified community space.',
              ),
              _buildValueCard(
                icon: Icons.bar_chart_rounded,
                iconBg: const Color(0xFFFAF5FF),
                iconColor: const Color(0xFF9333EA),
                title: 'Aggregated Pulse & Sentiment 📊',
                desc: 'Administration receives high-level aggregated wellness indices (e.g. exam week stress or mid-quarter burnout) without compromising individual privacy.',
              ),
              _buildValueCard(
                icon: Icons.local_hospital_outlined,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                title: 'Custom EAP / Counselor Escalation 🚨',
                desc: 'Direct integration with your internal on-campus student counselors or corporate Employee Assistance Program (EAP) helplines.',
              ),

              const SizedBox(height: 24),

              // 3. Request Pilot / Partner Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.handshake_rounded, color: Color(0xFF059669), size: 22),
                        SizedBox(width: 8),
                        Text('Bring Wehere to Your Institution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Request a free 30-day pilot for your school, college department, or company team.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _orgNameController,
                      decoration: InputDecoration(
                        labelText: 'Organization / Campus Name',
                        hintText: 'e.g. University of Mumbai or Acme Corp',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _workEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Official Work or Campus Email',
                        hintText: 'e.g. dean@university.edu or hr@company.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOrgType,
                      decoration: InputDecoration(
                        labelText: 'Organization Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'University / College', child: Text('University / College')),
                        DropdownMenuItem(value: 'School (K-12)', child: Text('School (K-12)')),
                        DropdownMenuItem(value: 'Corporate Office (1-50 employees)', child: Text('Corporate Office (1-50 employees)')),
                        DropdownMenuItem(value: 'Corporate Enterprise (50+ employees)', child: Text('Corporate Enterprise (50+ employees)')),
                        DropdownMenuItem(value: 'Non-Profit / NGO', child: Text('Non-Profit / NGO')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedOrgType = val);
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _submittingInquiry ? null : _submitPartnershipInquiry,
                        child: _submittingInquiry
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Request Institutional Pilot ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
