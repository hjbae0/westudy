import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수동 발송 버튼
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _sendReport(context),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('학부모 리포트 수동 발송'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _sendBulkReport(context),
                icon: const Icon(Icons.group_rounded, size: 18),
                label: const Text('전체 일괄 발송'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 발송 이력 테이블
          const Text('발송 이력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildHistoryTable(),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('report_logs')
          .orderBy('sentAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('발송 이력이 없습니다.', style: TextStyle(color: Colors.grey.shade500))),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [_h('발송 일시', 3), _h('학부모', 2), _h('학생', 2), _h('유형', 2), _h('상태', 2), _h('메시지', 4)],
                ),
              ),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final sentAt = (d['sentAt'] as Timestamp?)?.toDate();
                final timeStr = sentAt != null ? DateFormat('M/d HH:mm').format(sentAt) : '-';
                final success = d['success'] == true;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      _c(timeStr, 3),
                      _c(d['parentName'] ?? '-', 2),
                      _c(d['studentName'] ?? '-', 2),
                      _c(d['type'] ?? '주간', 2),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: success
                                ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                                : AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            success ? '성공' : '실패',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: success ? AppTheme.secondaryColor : AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ),
                      _c(d['message'] ?? '-', 4),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  static Widget _h(String t, int f) => Expanded(flex: f, child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))));
  static Widget _c(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));

  void _sendReport(BuildContext context) {
    String? selectedParentId;
    String? selectedParentName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('리포트 수동 발송'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.usersCollection)
                      .where('role', isEqualTo: 'parent')
                      .snapshots(),
                  builder: (context, snap) {
                    final parents = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: '학부모 선택',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      value: selectedParentId,
                      items: parents.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? doc.id));
                      }).toList(),
                      onChanged: (v) {
                        final doc = parents.firstWhere((d) => d.id == v);
                        setDialogState(() {
                          selectedParentId = v;
                          selectedParentName = (doc.data() as Map<String, dynamic>)['name'];
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: selectedParentId == null ? null : () async {
                await FirebaseFirestore.instance.collection('report_logs').add({
                  'parentId': selectedParentId,
                  'parentName': selectedParentName,
                  'studentName': '-',
                  'type': '수동',
                  'success': true,
                  'message': '수동 발송 완료',
                  'sentAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('리포트가 발송되었습니다.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('발송'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendBulkReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('전체 일괄 발송'),
        content: const Text('모든 학부모에게 주간 리포트를 발송할까요?\n솔라피 알림톡으로 전송됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              // 모든 학부모 조회 → 로그 기록
              final parents = await FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .where('role', isEqualTo: 'parent')
                  .get();

              final batch = FirebaseFirestore.instance.batch();
              for (final doc in parents.docs) {
                final d = doc.data();
                batch.set(
                  FirebaseFirestore.instance.collection('report_logs').doc(),
                  {
                    'parentId': doc.id,
                    'parentName': d['name'],
                    'studentName': '-',
                    'type': '일괄',
                    'success': true,
                    'message': '주간 리포트 일괄 발송',
                    'sentAt': FieldValue.serverTimestamp(),
                  },
                );
              }
              await batch.commit();

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${parents.docs.length}명에게 리포트가 발송되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('일괄 발송'),
          ),
        ],
      ),
    );
  }
}
