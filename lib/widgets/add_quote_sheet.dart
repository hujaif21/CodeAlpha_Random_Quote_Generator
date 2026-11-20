import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quote.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';

class AddQuoteSheet extends StatefulWidget {
  final Quote? existingQuote;

  const AddQuoteSheet({super.key, this.existingQuote});

  @override
  State<AddQuoteSheet> createState() => _AddQuoteSheetState();
}

class _AddQuoteSheetState extends State<AddQuoteSheet> {
  late final TextEditingController _quoteController;
  late final TextEditingController _authorController;
  bool _saving = false;

  bool get _isEditing => widget.existingQuote != null;

  @override
  void initState() {
    super.initState();
    _quoteController =
        TextEditingController(text: widget.existingQuote?.text ?? '');
    _authorController = TextEditingController(
      text: widget.existingQuote?.author == 'You'
          ? ''
          : (widget.existingQuote?.author ?? ''),
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _saveQuote() async {
    final text = _quoteController.text.trim();
    if (text.isEmpty || _saving) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final Quote? result = _isEditing
        ? await CacheService.updateCustomQuote(
      quoteId: widget.existingQuote!.id,
      text: text,
      author: _authorController.text,
    )
        : await CacheService.addCustomQuote(
      text: text,
      author: _authorController.text,
    );

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkCard : AppColors.lightBg;
    final inputBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fgColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    _isEditing
                        ? Icons.edit_rounded
                        : Icons.edit_note_rounded,
                    color: isDark
                        ? const Color(0xFF8AB899)
                        : AppColors.forestGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Edit your quote' : 'Write your own quote',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isEditing
                    ? 'Update your personal mantra offline.'
                    : 'Saved offline to My Quotes & ready to share as an image.',
                style: TextStyle(fontSize: 13.5, color: subColor),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _quoteController,
                maxLines: 3,
                maxLength: 180,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15.5, color: fgColor),
                decoration: InputDecoration(
                  hintText: 'Write a personal mantra or favorite line...',
                  hintStyle: TextStyle(color: subColor),
                  filled: true,
                  fillColor: inputBg,
                  counterStyle: TextStyle(color: subColor, fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.forestGreen,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _authorController,
                maxLength: 45,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontSize: 15, color: fgColor),
                decoration: InputDecoration(
                  hintText: 'Author (optional — defaults to "You")',
                  hintStyle: TextStyle(color: subColor),
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.forestGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                  _quoteController.text.trim().isEmpty ? null : _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.lightTextPrimary,
                    disabledBackgroundColor:
                    AppColors.terracotta.withValues(alpha: 0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _isEditing ? 'Save Changes' : 'Add to Deck',
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}