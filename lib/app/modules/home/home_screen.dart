import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';
import '../../widgets/user_avatar.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  int bottomTabIndex = 0;
  int requestTopTabIndex = 0;

  static const Color _primary = Color(0xFF0A84FF);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _textDark = Color(0xFF1C1C1E);


  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = bottomTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => bottomTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _primary.withOpacity(.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : Colors.black54,
                  size: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? _primary : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUsers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<HomeUserItem> getFilteredChats(List<HomeUserItem> users) {
    if (searchText
        .trim()
        .isEmpty) return users;
    final query = searchText.toLowerCase().trim();

    return users.where((item) {
      final name = item.user.fullName.toLowerCase();
      final email = item.user.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<AppUser> getFilteredAllUsers(List<AppUser> users) {
    if (searchText
        .trim()
        .isEmpty) return users;
    final query = searchText.toLowerCase().trim();

    return users.where((item) {
      final name = item.fullName.toLowerCase();
      final email = item.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  String formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    if (isToday) return DateFormat('h:mm a').format(dateTime);
    if (now.year == dateTime.year) return DateFormat('dd MMM').format(dateTime);

    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String buildSubtitle(HomeUserItem item) {
    if (item.lastMessage.isEmpty) {
      return 'Now you can start conversation';
    }

    return item.lastMessage;
  }

  Future<void> showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final selected = <String>{};
    final friendUsers = controller.users.map((e) => e.user).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
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
                    bottom: MediaQuery
                        .of(context)
                        .viewInsets
                        .bottom + 20,
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
                                  'Create Group',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Create a clean group chat with selected members',
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
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter group name',
                          prefixIcon: const Icon(
                            Icons.edit_outlined,
                            color: _primary,
                          ),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Members',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark.withOpacity(.92),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 300,
                        child: ListView.separated(
                          itemCount: friendUsers.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final user = friendUsers[i];
                            final isSelected = selected.contains(user.uid);

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                setStateModal(() {
                                  if (isSelected) {
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
                                  color: isSelected
                                      ? _primary.withOpacity(.08)
                                      : _bg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? _primary.withOpacity(.35)
                                        : Colors.black.withOpacity(.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      imageUrl: user.photoUrl,
                                      radius: 22,
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
                                        color: isSelected
                                            ? _primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? _primary
                                              : Colors.black26,
                                          width: 1.6,
                                        ),
                                      ),
                                      child: isSelected
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final groupId = await controller.createGroup(
                              name: nameController.text,
                              selectedMemberIds: selected.toList(),
                            );

                            if (!mounted) return;
                            if (groupId == null || groupId.isEmpty) return;

                            Navigator.pop(context);
                            setState(() => bottomTabIndex = 2);
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
                          icon: const Icon(Icons.groups_2_outlined),
                          label: const Text(
                            'Create Group',
                            style: TextStyle(
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

  Widget buildRequestTopTabs(bool hasIncoming) {
    Widget buildTab({
      required int index,
      required String text,
      bool withRedDot = false,
    }) {
      final selected = requestTopTabIndex == index;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => requestTopTabIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              color: selected ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? _primary
                    : Colors.black.withOpacity(.06),
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: _primary.withOpacity(.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: selected ? Colors.white : _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (withRedDot) ...[
                  const SizedBox(width: 7),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildTab(
          index: 0,
          text: 'Requests',
          withRedDot: hasIncoming,
        ),
        const SizedBox(width: 10),
        buildTab(
          index: 1,
          text: 'All Users',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF56B2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bottomTabIndex == 0
                          ? 'Stay connected with your recent conversations'
                          : bottomTabIndex == 1
                          ? 'Manage requests and connect with people'
                          : 'Create groups and chat with multiple members',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.profile),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchText = value),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _primary,
                ),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(HomeUserItem item) {
    final user = item.user;
    final hasUnread = item.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? _primary.withOpacity(.06) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasUnread
              ? _primary.withOpacity(.18)
              : Colors.black.withOpacity(.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        leading: UserAvatar(imageUrl: user.photoUrl, radius: 26),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
            color: _textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            buildSubtitle(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread ? _textDark : Colors.black54,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatLastMessageTime(item.lastMessageAt?.toDate()),
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  item.unreadCount > 99
                      ? '99+'
                      : item.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => Get.toNamed(AppRoutes.chat, arguments: user),
      ),
    );
  }

  Widget _buildIncomingRequestCard(dynamic request) {
    final sender = controller.userById(request.senderId);
    if (sender == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: UserAvatar(imageUrl: sender.photoUrl, radius: 24),
        title: Text(
          sender.fullName,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        subtitle: Text(
          sender.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.red.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => controller.rejectRequest(request),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.green,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => controller.acceptRequest(request),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final status = controller.requestStatusFor(user.uid);

    Widget trailing;
    if (status == 'accepted') {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
            SizedBox(width: 6),
            Text(
              'Accepted',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'pending_sent') {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: Colors.orange),
            SizedBox(width: 6),
            Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'pending_received') {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_outlined,
                size: 18, color: Colors.purple),
            SizedBox(width: 6),
            Text(
              'Check',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      trailing = ElevatedButton.icon(
        onPressed: () => controller.sendRequest(user.uid),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text(
          'Send Req',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: UserAvatar(imageUrl: user.photoUrl, radius: 24),
        title: Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    final hasUnread = group.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasUnread ? _primary.withOpacity(.06) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasUnread
              ? _primary.withOpacity(.18)
              : Colors.black.withOpacity(.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.groups_2_outlined,
            color: _primary,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            group.lastMessage.isEmpty
                ? '${group.members.length} members'
                : group.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: hasUnread
            ? Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            group.unreadCount > 99
                ? '99+'
                : group.unreadCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
            : Text(
          formatLastMessageTime(group.lastMessageAt?.toDate()),
          style: const TextStyle(
            fontSize: 11.5,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          final eligible = controller.users.map((e) => e.user).toList();
          Get.toNamed(
            AppRoutes.groupChat,
            arguments: {
              'groupId': group.groupId,
              'name': group.name,
              'members': group.members,
              'eligibleUsers': eligible,
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyBox({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: _primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChats() {
    final chats = getFilteredChats(controller.users);

    if (chats.isEmpty) {
      return _buildEmptyBox(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No accepted chat yet',
        subtitle: 'Once you connect with someone, your chats will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      itemBuilder: (context, index) => _buildChatTile(chats[index]),
    );
  }

  Widget _buildRequests() {
    final incoming = controller.incomingRequests;
    final hasIncoming = incoming.isNotEmpty;
    final allUsers = getFilteredAllUsers(controller.allUsers);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildRequestTopTabs(hasIncoming),
        const SizedBox(height: 14),
        if (requestTopTabIndex == 0) ...[
          if (incoming.isEmpty)
            _buildEmptyBox(
              icon: Icons.mark_email_unread_outlined,
              title: 'No request available',
              subtitle: 'When someone sends you a request, it will show here.',
            ),
          ...incoming.map((request) => _buildIncomingRequestCard(request)),
        ] else
          ...[
            if (allUsers.isEmpty)
              _buildEmptyBox(
                icon: Icons.people_alt_outlined,
                title: 'No users found',
                subtitle: 'Try another search or wait for more users to join.',
              ),
            ...allUsers.map((user) => _buildUserCard(user)),
          ],
      ],
    );
  }

  Widget _buildGroups() {
    final groups = controller.groups;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A84FF), Color(0xFF56B2FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: showCreateGroupDialog,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.group_add_rounded),
              label: const Text(
                'Create New Group',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? _buildEmptyBox(
            icon: Icons.groups_2_outlined,
            title: 'No groups yet',
            subtitle: 'Create your first group and start chatting together.',
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (_, index) => _buildGroupCard(groups[index]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (bottomTabIndex == 0) {
                  return _buildChats();
                }

                if (bottomTabIndex == 1) {
                  return _buildRequests();
                }

                return _buildGroups();
              }),
            ),
          ],
        ),
      ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.black.withOpacity(.04),
              ),
            ),
            child: Row(
              children: [
                _buildBottomNavItem(
                  index: 0,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                ),
                _buildBottomNavItem(
                  index: 1,
                  icon: Icons.person_add_alt_outlined,
                  activeIcon: Icons.person_add_alt_1_rounded,
                  label: 'Requests',
                ),
                _buildBottomNavItem(
                  index: 2,
                  icon: Icons.groups_2_outlined,
                  activeIcon: Icons.groups_rounded,
                  label: 'Groups',
                ),
              ],
            ),
          ),
        ),
    );
  }
}