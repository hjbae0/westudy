import 'package:flutter/material.dart';
import 'package:westudy/utils/theme.dart';

enum AdminPage { dashboard, students, teachers, classes, parents, reports }

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  AdminPage _currentPage = AdminPage.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void navigateTo(AdminPage page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: isWide ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 로고
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'WeStudy',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Text(
                  'Admin',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _sidebarItem(AdminPage.dashboard, Icons.dashboard_rounded, '대시보드'),
          _sidebarItem(AdminPage.students, Icons.school_rounded, '학생 관리'),
          _sidebarItem(AdminPage.teachers, Icons.person_rounded, '선생님 관리'),
          _sidebarItem(AdminPage.classes, Icons.class_rounded, '수업 관리'),
          _sidebarItem(AdminPage.parents, Icons.family_restroom_rounded, '학부모 관리'),
          _sidebarItem(AdminPage.reports, Icons.assessment_rounded, '리포트 관리'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(AdminPage page, IconData icon, String label) {
    final isSelected = _currentPage == page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _currentPage = page),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: _buildSidebar(),
    );
  }

  Widget _buildTopBar(bool isWide) {
    final titles = {
      AdminPage.dashboard: '대시보드',
      AdminPage.students: '학생 관리',
      AdminPage.teachers: '선생님 관리',
      AdminPage.classes: '수업 관리',
      AdminPage.parents: '학부모 관리',
      AdminPage.reports: '리포트 관리',
    };

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            titles[_currentPage] ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    // 각 페이지는 별도 파일에서 import하여 사용
    // 여기서는 placeholder, 각 커밋에서 실제 위젯으로 교체
    switch (_currentPage) {
      case AdminPage.dashboard:
        return const _Placeholder('대시보드');
      case AdminPage.students:
        return const _Placeholder('학생 관리');
      case AdminPage.teachers:
        return const _Placeholder('선생님 관리');
      case AdminPage.classes:
        return const _Placeholder('수업 관리');
      case AdminPage.parents:
        return const _Placeholder('학부모 관리');
      case AdminPage.reports:
        return const _Placeholder('리포트 관리');
    }
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 20)));
  }
}
