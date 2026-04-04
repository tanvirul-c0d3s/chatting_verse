import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/custom_text_field.dart'; // <-- adjust path if needed
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

  static const Color _primary = Color(0xFF0A84FF);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _textDark = Color(0xFF1C1C1E);

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
        (args['members'] as List?)?.map((e) => e.toString()).toSet() ??
            <String>{};

    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final list = eligible
                .where((u) => !currentMembers.contains(u.uid))
                .toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.group_add_rounded,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Members',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select people you want to add into this group',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (list.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'No more users available to add.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        SizedBox(
                          height: 360,
                          child: ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = list[index];
                              final checked = selected.contains(user.uid);

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  setStateModal(() {
                                    if (checked) {
                                      selected.remove(user.uid);
                                    } else {
                                      selected.add(user.uid);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: checked
                                        ? _primary.withOpacity(.08)
                                        : _bg,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: checked
                                          ? _primary.withOpacity(.35)
                                          : Colors.black.withOpacity(.05),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                        _primary.withOpacity(.12),
                                        child: Text(
                                          user.fullName.isNotEmpty
                                              ? user.fullName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: _primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                        const Duration(milliseconds: 180),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: checked
                                              ? _primary
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: checked
                                                ? _primary
                                                : Colors.black26,
                                            width: 1.6,
                                          ),
                                        ),
                                        child: checked
                                            ? const Icon(
                                          Icons.check,
                                          size: 15,
                                          color: Colors.white,
                                        )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: list.isEmpty
                              ? null
                              : () async {
                            final selectedIds = selected.toList();
                            if (selectedIds.isEmpty) return;

                            await controller.addMembers(selectedIds);

                            for (final uid in selectedIds) {
                              _memberIds.add(uid);
                              final found = eligible
                                  .where((e) => e.uid == uid)
                                  .toList();
                              if (found.isNotEmpty) {
                                _userNames[uid] = found.first.fullName;
                              }
                            }

                            if (mounted) setState(() {});
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.people_alt_outlined),
                          label: Text(
                            selected.isEmpty
                                ? 'Add Selected Members'
                                : 'Add ${selected.length} Member${selected.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Message Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 14),
                _ActionTile(
                  icon: Icons.edit_outlined,
                  iconColor: _primary,
                  title: 'Edit message',
                  subtitle: 'Update the text you sent',
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.red,
                  title: 'Delete message',
                  subtitle: 'Remove this message from the conversation',
                  danger: true,
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action == 'edit') {
      final editController = TextEditingController(text: msg.text);

      final newText = await showDialog<String>(
        context: context,
        builder: (_) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: _primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Edit Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make your changes below',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: editController,
                    autofocus: true,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type updated message',
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: Colors.black.withOpacity(.08),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(
                            context,
                            editController.text.trim(),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (newText != null && newText.trim().isNotEmpty) {
        await controller.editMyTextMessage(
          messageId: msg.id,
          text: newText.trim(),
        );
      }
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Delete Message?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: Colors.black.withOpacity(.08),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (confirmed == true) {
        await controller.deleteMyTextMessage(msg.id);
      }
    }
  }

  Widget _buildMembersSection() {
    if (_memberIds.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Members (${_memberIds.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _memberIds.map((uid) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _primary.withOpacity(.10),
                  ),
                ),
                child: Text(
                  memberLabel(uid),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(.05)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: textController,
                hint: 'Write a message...',
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _primary,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: handleSend,
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMessages() {
    return Expanded(
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
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            }
          });

          if (snapshot.connectionState == ConnectionState.waiting &&
              messages.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (messages.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(.05)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 42,
                      color: _primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Start the group conversation with your first message.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _textDark,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                color: _primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: _primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
              child: IconButton(
                onPressed: handleAddMembers,
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: _primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMembersSection(),
          _buildMessages(),
          _buildComposer(),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger ? Colors.red.withOpacity(.06) : const Color(0xFFF5F7FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: danger ? Colors.red : const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}