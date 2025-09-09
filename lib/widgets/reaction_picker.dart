import 'package:flutter/material.dart';
import '../constants.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  final VoidCallback? onClose;

  const ReactionPicker({
    Key? key,
    required this.onReactionSelected,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'React to message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),

          // Reactions grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  ReactionConstants.availableReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        onReactionSelected(emoji);
                        onClose?.call();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: onClose,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReactionBubble extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const ReactionBubble({
    Key? key,
    required this.emoji,
    required this.count,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.accentBlue.withOpacity(0.2)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.accentBlue : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReactionDetailSheet extends StatelessWidget {
  final Map<String, List<dynamic>> reactionsByEmoji;
  final Function(String) onReactionSelected;

  const ReactionDetailSheet({
    Key? key,
    required this.reactionsByEmoji,
    required this.onReactionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Reactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),

          // Reactions list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reactionsByEmoji.length,
              itemBuilder: (context, index) {
                final emoji = reactionsByEmoji.keys.elementAt(index);
                final reactions = reactionsByEmoji[emoji]!;

                return ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    '${reactions.length} ${reactions.length == 1 ? 'reaction' : 'reactions'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Text(
                    reactions.map((r) => r['userName'] ?? 'Unknown').join(', '),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onReactionSelected(emoji),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
