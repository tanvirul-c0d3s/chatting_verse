import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/message_bubble.dart';
import 'group_chat_controller.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late GroupChatController controller;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final Map<String, String> _userNames = {};
  final Set<String> _memberIds = <String>{};

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<GroupChatController>()
        ? Get.find<GroupChatController>()
        : Get.put(GroupChatController());
    preloadUserNames();
  }

  Future<void> preloadUserNames() async {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final eligible = (args['eligibleUsers'] as List?)?.cast<AppUser>() ?? [];
    final members =
        (args['members'] as List?)?.map((e) => e.toString()).toSet() ??
            <String>{};
    final authService = Get.find<AuthService>();
    _memberIds
      ..clear()
      ..addAll(members);

    for (final user in eligible) {
      _userNames[user.uid] = user.fullName;
    }

    if (mounted) setState(() {});

    for (final memberId in members) {
      if (_userNames.containsKey(memberId)) continue;

      final user = await authService.getUserById(memberId);
      if (user == null) continue;

      _userNames[user.uid] = user.fullName;
      if (mounted) setState(() {});
    }
  }

  String memberLabel(String uid) {
    if (uid == controller.myUid) return 'You';
    return _userNames[uid] ?? 'Member';
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();

    if (Get.isRegistered<GroupChatController>()) {
      Get.delete<GroupChatController>();
    }

    super.dispose();
  }

  Future<void> handleSend() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    await controller.sendText(text);
    textController.clear();
  }

  Future<void> handleAddMembers() async {
    final args = Get.arguments as Map<String, dynamic>;
    final eligible = (args['eligibleUsers'] as List?)?.cast<AppUser>() ?? [];
    final currentMembers =
        (args['members'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};

    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final list = eligible.where((u) => !currentMembers.contains(u.uid)).toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Add members', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final user = list[index];
                          final checked = selected.contains(user.uid);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) {
                              setStateModal(() {
                                if (v == true) {
                                  selected.add(user.uid);
                                } else {
                                  selected.remove(user.uid);
                                }
                              });
                            },
                            title: Text(user.fullName),
                            subtitle: Text(user.email),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final selectedIds = selected.toList();
                        await controller.addMembers(selectedIds);

                        for (final uid in selectedIds) {
                          _memberIds.add(uid);
                          final found = eligible.where((e) => e.uid == uid).toList();
                          if (found.isNotEmpty) {
                            _userNames[uid] = found.first.fullName;
                          }
                        }

                        if (mounted) setState(() {});
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Add Selected Members'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> onLongPressMessage(ChatMessage msg) async {
    final uid = controller.myUid;
    if (uid == null) return;

    final isMyText = msg.senderId == uid && msg.type == 'text' && !msg.isDeleted;
    if (!isMyText) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit message'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete message', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      final editController = TextEditingController(text: msg.text);
      final newText = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Type updated message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, editController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (newText != null && newText.trim().isNotEmpty) {
        await controller.editMyTextMessage(messageId: msg.id, text: newText.trim());
      }
      return;
    }

    if (action == 'delete') {
      await controller.deleteMyTextMessage(msg.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.groupName),
        actions: [
          IconButton(
            onPressed: handleAddMembers,
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_memberIds.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members (${_memberIds.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B5FEF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _memberIds
                          .map(
                            (uid) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            memberLabel(uid),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: controller.messagesStream(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final messages =
                docs.map((doc) => ChatMessage.fromMap(doc.data())).toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.markRead();
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    return GestureDetector(
                      onLongPress: () => onLongPressMessage(msg),
                      child: MessageBubble(
                        message: msg,
                        isMe: msg.senderId == controller.myUid,
                        senderName: msg.senderId == controller.myUid
                            ? null
                            : (_userNames[msg.senderId] ?? 'Member'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Color(0xFFF1F3F8),
                      ),
                      onSubmitted: (_) => handleSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: handleSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}