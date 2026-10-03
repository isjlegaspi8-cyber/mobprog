import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();

  List<User> _users = const [];
  List<User> _filteredUsers = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _userService.getAllUsersForChat();
    if (!mounted) return;

    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _filterUsers(String query) {
    final text = query.trim().toLowerCase();

    setState(() {
      if (text.isEmpty) {
        _filteredUsers = _users;
        return;
      }

      _filteredUsers = _users.where((user) {
        final searchableText = [
          user.fullName,
          user.username,
          user.email,
        ].join(' ').toLowerCase();

        return searchableText.contains(text);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const CustomText(
          text: 'Messages',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18.h),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterUsers,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 48.sp,
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            ),
                            SizedBox(height: 10.h),
                            CustomText(
                              text: 'No users found',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (_, index) {
                          final user = _filteredUsers[index];
                          final initials = user.fullName.isNotEmpty
                              ? user.fullName.substring(0, 1).toUpperCase()
                              : user.username.substring(0, 1).toUpperCase();

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatDetailScreen(user: user),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20.r),
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28.r,
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.14),
                                        child: CustomText(
                                          text: initials,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(width: 14.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              text: user.fullName.isNotEmpty
                                                  ? user.fullName
                                                  : user.username,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            SizedBox(height: 4.h),
                                            CustomText(
                                              text: user.email,
                                              fontSize: 12.sp,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: CustomText(
                                          text: 'Online',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
