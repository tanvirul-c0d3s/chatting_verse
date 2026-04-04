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
    if (searchText.trim().isEmpty) return users;
    final query = searchText.toLowerCase().trim();

    return users.where((item) {
      final name = item.user.fullName.toLowerCase();
      final email = item.user.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<AppUser> getFilteredAllUsers(List<AppUser> users) {
    if (searchText.trim().isEmpty) return users;
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
    final isToday =
        now.year == dateTime.year &&
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
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'Group name'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        itemCount: friendUsers.length,
                        itemBuilder: (_, i) {
                          final user = friendUsers[i];
                          return CheckboxListTile(
                            value: selected.contains(user.uid),
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
                        final groupId = await controller.createGroup(
                          name: nameController.text,
                          selectedMemberIds: selected.toList(),
                        );
                        if (!mounted) return;

                        if (groupId == null || groupId.isEmpty) {
                          return;
                        }

                        Navigator.pop(context);
                        setState(() => bottomTabIndex = 2);
                      },
                      child: const Text('Create Group'),
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

  Widget buildRequestTopTabs(bool hasIncoming) {
    Widget buildTab({
      required int index,
      required String text,
      bool withRedDot = false,
    }) {
      final selected = requestTopTabIndex == index;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => requestTopTabIndex = index),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF5B5FEF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5B5FEF)
                    : Colors.grey.withOpacity(.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (withRedDot) ...[
                  const SizedBox(width: 6),
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
          text: 'Upcoming Requests',
          withRedDot: hasIncoming,
        ),
        const SizedBox(width: 10),
        buildTab(index: 1, text: 'All Users'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B5FEF), Color(0xFF8F94FB)],
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
                                  ? 'Unread chat stays highlighted until opened'
                                  : bottomTabIndex == 1
                                  ? 'Manage requests and send new request'
                                  : 'Create group and chat with members',
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
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.person_outline, color: Colors.white),
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
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF5B5FEF)),
                        suffixIcon: searchText.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchText = '');
                          },
                          icon: const Icon(Icons.close),
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
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (bottomTabIndex == 0) {
                  final chats = getFilteredChats(controller.users);

                  if (chats.isEmpty) {
                    return const Center(child: Text('No accepted chat yet'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final item = chats[index];
                      final user = item.user;
                      final hasUnread = item.unreadCount > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: hasUnread
                              ? const Color(0xFFF3F0FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: hasUnread
                              ? Border.all(
                            color: const Color(0xFF5B5FEF).withOpacity(.25),
                          )
                              : null,
                        ),
                        child: ListTile(
                          leading: UserAvatar(imageUrl: user.photoUrl, radius: 24),
                          title: Text(
                            user.fullName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            buildSubtitle(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(formatLastMessageTime(item.lastMessageAt?.toDate())),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5B5FEF),
                                    shape: BoxShape.circle,
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
                    },
                  );
                }

                if (bottomTabIndex == 1) {
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
                          const Card(
                            child: ListTile(
                              title: Text('No upcoming request'),
                              subtitle: Text('When someone sends request, it will show here.'),
                            ),
                          ),
                        ...incoming.map((request) {
                          final sender = controller.userById(request.senderId);
                          if (sender == null) return const SizedBox.shrink();

                          return Card(
                            child: ListTile(
                              leading: UserAvatar(imageUrl: sender.photoUrl, radius: 22),
                              title: Text(sender.fullName),
                              subtitle: Text(sender.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => controller.rejectRequest(request),
                                    child: const Text('Reject'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => controller.acceptRequest(request),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        ...allUsers.map((user) {
                          final status = controller.requestStatusFor(user.uid);

                          Widget trailing;
                          if (status == 'accepted') {
                            trailing = const Text('Accepted');
                          } else if (status == 'pending_sent') {
                            trailing = const Text('Pending');
                          } else if (status == 'pending_received') {
                            trailing = const Text('Check upcoming');
                          } else {
                            trailing = ElevatedButton(
                              onPressed: () => controller.sendRequest(user.uid),
                              child: const Text('Send Request'),
                            );
                          }

                          return Card(
                            child: ListTile(
                              leading: UserAvatar(imageUrl: user.photoUrl, radius: 22),
                              title: Text(user.fullName),
                              subtitle: Text(user.email),
                              trailing: trailing,
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                }

                final groups = controller.groups;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: showCreateGroupDialog,
                          icon: const Icon(Icons.group_add_outlined),
                          label: const Text('Create Group'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groups.length,
                        itemBuilder: (_, index) {
                          final group = groups[index];
                          final hasUnread = group.unreadCount > 0;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF5B5FEF).withOpacity(.12),
                                child: const Icon(Icons.groups_2_outlined),
                              ),
                              title: Text(group.name),
                              subtitle: Text(
                                group.lastMessage.isEmpty
                                    ? '${group.members.length} members'
                                    : group.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: hasUnread
                                  ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5B5FEF),
                                  shape: BoxShape.circle,
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
                                  : Text(formatLastMessageTime(group.lastMessageAt?.toDate())),
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
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomTabIndex,
        onTap: (value) => setState(() => bottomTabIndex = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_2_outlined),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
}