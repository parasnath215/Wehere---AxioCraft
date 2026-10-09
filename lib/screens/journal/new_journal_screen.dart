import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_routes.dart';
import '../../models/journal_entry.dart';
import '../../state/app_state.dart';
import '../../widgets/common/mood_chip.dart';
import '../../core/network/api_client.dart';

class NewJournalScreen extends StatefulWidget {
  final JournalEntry? editEntry;
  const NewJournalScreen({super.key, this.editEntry});

  @override
  State<NewJournalScreen> createState() => _NewJournalScreenState();
}

class _NewJournalScreenState extends State<NewJournalScreen> {
  String _selectedMood = 'Amazing';
  final TextEditingController _thoughtController = TextEditingController();
  final TextEditingController _gratitudeController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isPrivateOnly = true;
  bool _setReminder = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Failed to pick image: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.editEntry != null) {
      _selectedMood = _mapScoreToMood(widget.editEntry!.mood);
      _thoughtController.text = widget.editEntry!.thought;
      _gratitudeController.text = widget.editEntry!.gratitude;
      _selectedCategory = widget.editEntry!.category;
      _isPrivateOnly = widget.editEntry!.isPrivate;
    }
  }

  String _mapScoreToMood(String scoreOrMood) {
     if (['Amazing', 'Good', 'Okay', 'Tired', 'Stressed'].contains(scoreOrMood)) return scoreOrMood;
     switch (scoreOrMood) {
        case '5': return 'Amazing';
        case '4': return 'Good';
        case '3': return 'Okay';
        case '2': return 'Tired';
        case '1': return 'Stressed';
        default: return 'Okay';
     }
  }

  final List<String> _categories = [
    'General',
    'Gratitude',
    'Goal / Progress',
    'Reflection',
    'Dream / Idea',
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showBeforeYouGoSheet(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => _showBeforeYouGoSheet(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(70, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _saveAndNavigate(),
                child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('New Journal Entry', style: AppTextStyles.h1.copyWith(fontSize: 22)),
                          const SizedBox(width: 6),
                          const Text('✨', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Capture your thoughts and make them count.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          SizedBox(width: 4),
                          Text('💜', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Privacy & Visibility Selector Card (Addresses Private vs Public confusion)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isPrivateOnly ? const Color(0xFFF3F1FD) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isPrivateOnly ? AppColors.primaryBorder : const Color(0xFF93C5FD),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isPrivateOnly ? AppColors.primarySoft : const Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPrivateOnly ? Icons.lock_outline_rounded : Icons.public_rounded,
                          size: 20,
                          color: _isPrivateOnly ? AppColors.primary : const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _isPrivateOnly ? 'Private to You (Default)' : 'Share Anonymously to Circles',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isPrivateOnly ? AppColors.primaryDark : const Color(0xFF1E40AF),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(_isPrivateOnly ? '🔒' : '👥', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPrivateOnly
                                  ? '100% encrypted & only visible to you on this device.'
                                  : 'Shared as "Kind Peer" to Community Circles without your name.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isPrivateOnly ? AppColors.textSecondary : const Color(0xFF1E3A8A),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !_isPrivateOnly,
                        activeThumbColor: const Color(0xFF2563EB),
                        onChanged: (sharePublicly) {
                          setState(() {
                            _isPrivateOnly = !sharePublicly;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. "How are you feeling today?" (Mockup 1.17.19 AM (1))
                Text('How are you feeling today?', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MoodChip(
                      label: 'Amazing',
                      emoji: '😄',
                      tintColor: const Color(0xFF8B5CF6),
                      isSelected: _selectedMood == 'Amazing',
                      onTap: () => setState(() => _selectedMood = 'Amazing'),
                    ),
                    MoodChip(
                      label: 'Good',
                      emoji: '🙂',
                      tintColor: const Color(0xFF22C55E),
                      isSelected: _selectedMood == 'Good',
                      onTap: () => setState(() => _selectedMood = 'Good'),
                    ),
                    MoodChip(
                      label: 'Okay',
                      emoji: '😐',
                      tintColor: const Color(0xFFF59E0B),
                      isSelected: _selectedMood == 'Okay',
                      onTap: () => setState(() => _selectedMood = 'Okay'),
                    ),
                    MoodChip(
                      label: 'Tired',
                      emoji: '🥱',
                      tintColor: const Color(0xFFF97316),
                      isSelected: _selectedMood == 'Tired',
                      onTap: () => setState(() => _selectedMood = 'Tired'),
                    ),
                    MoodChip(
                      label: 'Stressed',
                      emoji: '😫',
                      tintColor: const Color(0xFFEF4444),
                      isSelected: _selectedMood == 'Stressed',
                      onTap: () => setState(() => _selectedMood = 'Stressed'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. "What's on your mind?"
                Text('What’s on your mind?', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _thoughtController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Start writing your thoughts...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          counterText: '', // Hide default counter
                        ),
                      ),
                      const Divider(color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            animation: _thoughtController,
                            builder: (context, child) {
                              final words = _thoughtController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                              return Text(
                                '$words / 1000',
                                style: AppTextStyles.caption.copyWith(
                                  color: words > 1000 ? Colors.red : AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. "What are you grateful for today?"
                Text('What are you grateful for today?', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _gratitudeController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'List things you’re grateful for...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const Divider(color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            animation: _gratitudeController,
                            builder: (context, child) {
                              final words = _gratitudeController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                              return Text(
                                '$words / 100',
                                style: AppTextStyles.caption.copyWith(
                                  color: words > 100 ? Colors.red : AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Entry Type (optional) & Add Photo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Entry Type selector
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Entry Type (optional)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._categories.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () => setState(() => _selectedCategory = cat),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primarySoft : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.bookmark_outline_rounded, size: 14, color: isSel ? AppColors.primary : AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                          color: isSel ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Add Photo Card
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add a Photo (optional)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.primaryBorder),
                                image: _selectedImage != null 
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              ),
                              child: _selectedImage == null 
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.primarySoft,
                                          child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 20),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap to add a photo',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                                        ),
                                        SizedBox(height: 2),
                                        Text('JPG, PNG up to 10MB', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedImage = null),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.close, size: 14, color: AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Set a reminder toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Set a reminder (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('We’ll remind you to keep journaling.', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Switch(
                        value: _setReminder,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _setReminder = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Entry CTA
                ElevatedButton(
                  onPressed: () => _saveAndNavigate(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 6),
                      Text('• Your thoughts matter.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Save & Add to Daily Log (Outlined)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () => _saveAndNavigate(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Save & Add to Daily Log',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _saveAndNavigate() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final thought = _thoughtController.text.trim();
    final gratitude = _gratitudeController.text.trim();

    if (gratitude.isNotEmpty) {
      final words = gratitude.split(RegExp(r'\s+'));
      if (words.length > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gratitude must be 100 words or less.')),
        );
        return;
      }
    }

    final entry = JournalEntry(
      id: widget.editEntry?.id ?? 'j_${DateTime.now().millisecondsSinceEpoch}',
      date: widget.editEntry?.date ?? DateTime.now(),
      mood: _selectedMood,
      thought: thought.isNotEmpty ? thought : 'Mindful reflection for today.',
      gratitude: gratitude,
      category: _selectedCategory,
      isPrivate: _isPrivateOnly,
    );

    if (widget.editEntry != null) {
      try {
        await apiClient.put('/journal/${entry.id}', data: {
          'content': entry.thought,
          'moodScore': _moodToScore(entry.mood),
          'category': entry.category,
          'isPrivate': entry.isPrivate,
        });
        appState.fetchBackendData();
      } catch(e) {}
      Navigator.pop(context);
    } else {
      appState.addJournalEntry(_selectedMood, entry.thought, gratitude, _selectedCategory, isPrivate: _isPrivateOnly);
      // Community post is automatically created by backend if !isPrivateOnly

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.journalSuccess,
        arguments: entry,
      );
    }
  }

  int _moodToScore(String mood) {
    switch(mood) {
      case 'Amazing': return 5;
      case 'Good': return 4;
      case 'Okay': return 3;
      case 'Tired': return 2;
      case 'Stressed': return 1;
      default: return 3;
    }
  }

  void _showBeforeYouGoSheet(BuildContext context) {
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
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Before you go ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('What would you like to do with your entry?', style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.save_outlined, color: AppColors.primary)),
              title: const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Save your entry and continue later.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _saveAndNavigate();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF3E8FF), child: Icon(Icons.calendar_month_outlined, color: Color(0xFF8B5CF6))),
              title: const Text('Save & Add to Daily Log', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Save and add this entry to your daily log.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _saveAndNavigate();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFEECEE), child: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444))),
              title: const Text('Discard Entry', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              subtitle: const Text('Delete this entry. You can’t undo this.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text('Your thoughts are private and secure.', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
