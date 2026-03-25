import 'package:flutter/material.dart';
import 'package:westudy/screens/admin/students_page.dart';
import 'package:westudy/screens/admin/teachers_page.dart';
import 'package:westudy/screens/admin/teacher_schedule_page.dart';
import 'package:westudy/screens/admin/classes_page.dart';
import 'package:westudy/screens/admin/classes_import_page.dart';
import 'package:westudy/screens/admin/parents_page.dart';
import 'package:westudy/screens/admin/reports_page.dart';
import 'package:westudy/screens/admin/billing_page.dart';
import 'package:westudy/screens/admin/dashboard_page.dart';
import 'package:westudy/utils/theme.dart';

enum AdminPage { dashboard, students, teachers, classes, parents, billing, reports }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final isMedium = screenWidth > 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: !isMedium ? _buildDrawer() : null,
      body: Row(
        children: [
          if (isMedium)
            _buildSidebar(collapsed: !isWide),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(!isMedium),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool collapsed = false}) {
    return Container(
      width: collapsed ? 64 : 240,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 로고
          if (collapsed)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
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
          _sidebarItem(AdminPage.dashboard, Icons.dashboard_rounded, '대시보드', collapsed: collapsed),
          _sidebarItem(AdminPage.students, Icons.school_rounded, '학생 관리', collapsed: collapsed),
          _sidebarItem(AdminPage.teachers, Icons.person_rounded, '선생님 관리', collapsed: collapsed),
          _sidebarItem(AdminPage.classes, Icons.class_rounded, '수업 관리', collapsed: collapsed),
          _sidebarItem(AdminPage.parents, Icons.family_restroom_rounded, '학부모 관리', collapsed: collapsed),
          _sidebarItem(AdminPage.billing, Icons.receipt_long_rounded, '정산 관리', collapsed: collapsed),
          _sidebarItem(AdminPage.reports, Icons.assessment_rounded, '리포트 관리', collapsed: collapsed),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              collapsed ? 'v1' : 'v1.0.0',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(AdminPage page, IconData icon, String label, {bool collapsed = false}) {
    final isSelected = _currentPage == page;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: collapsed ? label : '',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _currentPage = page),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: collapsed
                  ? Center(child: Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 22))
                  : Row(
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
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: _buildSidebar(),
    );
  }

  Widget _buildTopBar(bool showMenu) {
    final titles = {
      AdminPage.dashboard: '대시보드',
      AdminPage.students: '학생 관리',
      AdminPage.teachers: '선생님 관리',
      AdminPage.classes: '수업 관리',
      AdminPage.parents: '학부모 관리',
      AdminPage.billing: '정산 관리',
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
          if (showMenu)
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
        return const DashboardPage();
      case AdminPage.students:
        return const StudentsPage();
      case AdminPage.teachers:
        return const _TeachersTabView();
      case AdminPage.classes:
        return const _ClassesTabView();
      case AdminPage.parents:
        return const ParentsPage();
      case AdminPage.billing:
        return const _BillingTabView();
      case AdminPage.reports:
        return const ReportsPage();
    }
  }
}

class _BillingTabView extends StatelessWidget {
  const _BillingTabView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              isScrollable: true,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: '수납 관리'),
                Tab(text: '입금 관리'),
                Tab(text: '월별 정산'),
                Tab(text: '부가세'),
                Tab(text: '카드 매출'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TuitionPage(),
                PaymentPage(),
                MonthlySettlementPage(),
                VatPage(),
                CardSalesPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassesTabView extends StatelessWidget {
  const _ClassesTabView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: [
                Tab(text: '캘린더'),
                Tab(text: '일괄관리 / 연동'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ClassesPage(),
                ClassesImportPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeachersTabView extends StatelessWidget {
  const _TeachersTabView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: [
                Tab(text: '선생님 목록'),
                Tab(text: '스케줄 관리'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TeachersPage(),
                TeacherSchedulePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

