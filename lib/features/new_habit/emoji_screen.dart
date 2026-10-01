import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class EmojiScreen extends StatelessWidget {
  const EmojiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const Text('Choose emoji', style: TextStyle(fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) =>
                    Navigator.pop(context, emoji.emoji),
                config: Config(
                  height: null,
                  viewOrderConfig: const ViewOrderConfig(
                    top: EmojiPickerItem.searchBar,
                    middle: EmojiPickerItem.emojiView,
                    bottom: EmojiPickerItem.categoryBar,
                  ),
                  emojiViewConfig: EmojiViewConfig(
                    columns: 8,
                    emojiSizeMax: 32,
                    backgroundColor: AppColors.background,
                    gridPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  skinToneConfig: SkinToneConfig(
                    dialogBackgroundColor: AppColors.card,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.SMILEYS,
                    backgroundColor: AppColors.background,
                    indicatorColor: AppColors.accent,
                    iconColor: Colors.white54,
                    iconColorSelected: Colors.white,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: AppColors.card,
                    buttonIconColor: Colors.white,
                    showBackspaceButton: false,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: AppColors.background,
                    buttonIconColor: Colors.white70,
                    hintText: 'Search emoji',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}