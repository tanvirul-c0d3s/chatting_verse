import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  List<AppUser> getFilteredUsers(List<AppUser> users) {
    if (searchText.trim().isEmpty) return users;

    final query = searchText.toLowerCase().trim();

    return users.where((user) {
      final name = user.fullName.toLowerCase();
      final email = user.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
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
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Find friends and start chatting',
                              style: TextStyle(
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
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF5B5FEF),
                        ),
                        suffixIcon: searchText.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchText = '';
                            });
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final filteredUsers = getFilteredUsers(controller.users);

                if (controller.users.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 54,
                            color: Color(0xFF5B5FEF),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 54,
                            color: Color(0xFF5B5FEF),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No matching user found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Try searching with another name or email',
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
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final AppUser user = filteredUsers[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        leading: UserAvatar(
                          imageUrl: user.photoUrl,
                          radius: 26,
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: user.isOnline
                                ? Colors.green.withOpacity(.12)
                                : Colors.grey.withOpacity(.14),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color:
                                user.isOnline ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: user.isOnline
                                      ? Colors.green
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => Get.toNamed(
                          AppRoutes.chat,
                          arguments: user,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}