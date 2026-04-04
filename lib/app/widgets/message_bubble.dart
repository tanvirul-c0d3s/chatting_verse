import 'package:flutter/material.dart';

import '../data/models/chat_message.dart';
import 'media_preview_widget.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = isMe
        ? const LinearGradient(
      colors: [Color(0xFF5B5FEF), Color(0xFF7B61FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isMe ? null : Colors.white,
          gradient: bgGradient,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: isMe
              ? null
              : Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: message.type == 'text'
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
                fontStyle:
                message.isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            if (message.isEdited && !message.isDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'edited',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        )
            : MediaPreviewWidget(
          type: message.type,
          url: message.fileUrl,
        ),
      ),
    );
  }
}