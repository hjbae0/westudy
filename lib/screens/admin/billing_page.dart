import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

// ─── 1. 수납 관리 ───
class TuitionPage extends StatelessWidget {
  const TuitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showTuitionForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('수납 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 요약 카드
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tuitions').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              int total = 0, paid = 0, unpaid = 0;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final amount = (d['amount'] as num?) ?? 0;
                total += amount.toInt();
                if (d['status'] == '완납') paid += amount.toInt();
                else unpaid += amount.toInt();
              }
              return Row(
                children: [
                  _summaryCard('총 수강료', _formatWon(total), AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  _summaryCard('완납', _formatWon(paid), AppTheme.secondaryColor),
                  const SizedBox(width: 12),
                  _summaryCard('미납', _formatWon(unpaid), AppTheme.errorColor),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildTuitionTable(),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTuitionTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tuitions').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _empty('수납 내역이 없습니다.');

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _header(['학생', '월', '수강료', '상태', '관리'], [3, 2, 2, 2, 2]),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final isPaid = d['status'] == '완납';
                return _row([
                  d['studentName'] ?? '-',
                  d['month'] ?? '-',
                  _formatWon((d['amount'] as num?)?.toInt() ?? 0),
                ], [3, 2, 2], trailing: [
                  _statusBadge(d['status'] ?? '미납', isPaid ? AppTheme.secondaryColor : AppTheme.errorColor),
                  Row(children: [
                    _iconBtn(Icons.check_circle_outline, AppTheme.secondaryColor, () async {
                      await FirebaseFirestore.instance.collection('tuitions').doc(doc.id).update({'status': '완납'});
                    }),
                    _iconBtn(Icons.edit_outlined, AppTheme.primaryColor, () => _showTuitionForm(context, id: doc.id, data: d)),
                  ]),
                ]);
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTuitionForm(BuildContext context, {String? id, Map<String, dynamic>? data}) {
    final studentC = TextEditingController(text: data?['studentName'] ?? '');
    final monthC = TextEditingController(text: data?['month'] ?? DateFormat('yyyy-MM').format(DateTime.now()));
    final amountC = TextEditingController(text: data?['amount']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    String status = data?['status'] ?? '미납';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(id != null ? '수납 수정' : '수납 등록'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _formField(studentC, '학생 이름', required: true),
                const SizedBox(height: 12),
                _formField(monthC, '월 (예: 2026-03)', required: true),
                const SizedBox(height: 12),
                _formField(amountC, '수강료 (원)', required: true, number: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: _deco('상태'),
                  items: ['미납', '완납', '부분납'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => ss(() => status = v ?? '미납'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final doc = {
                  'studentName': studentC.text.trim(),
                  'month': monthC.text.trim(),
                  'amount': int.tryParse(amountC.text.trim()) ?? 0,
                  'status': status,
                  if (id == null) 'createdAt': FieldValue.serverTimestamp(),
                };
                final ref = FirebaseFirestore.instance.collection('tuitions');
                if (id != null) await ref.doc(id).update(doc);
                else await ref.add(doc);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: Text(id != null ? '수정' : '등록'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 2. 입금 관리 ───
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [const Spacer(), _addBtn(context, '입금 등록', () => _showPaymentForm(context))],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('payments').orderBy('date', descending: true).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _empty('입금 내역이 없습니다.');
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _header(['일자', '학생', '금액', '결제수단', '메모'], [2, 2, 2, 2, 3]),
                  ...docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final date = (d['date'] as Timestamp?)?.toDate();
                    return _row([
                      date != null ? DateFormat('M/d').format(date) : '-',
                      d['studentName'] ?? '-',
                      _formatWon((d['amount'] as num?)?.toInt() ?? 0),
                      d['method'] ?? '-',
                      d['memo'] ?? '-',
                    ], [2, 2, 2, 2, 3]);
                  }),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentForm(BuildContext context) {
    final studentC = TextEditingController();
    final amountC = TextEditingController();
    final memoC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String method = '카드';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('입금 등록'),
          content: SizedBox(
            width: 400,
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
              _formField(studentC, '학생 이름', required: true),
              const SizedBox(height: 12),
              _formField(amountC, '금액 (원)', required: true, number: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: _deco('결제수단'),
                items: ['카드', '계좌이체', '현금'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => ss(() => method = v ?? '카드'),
              ),
              const SizedBox(height: 12),
              _formField(memoC, '메모'),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await FirebaseFirestore.instance.collection('payments').add({
                  'studentName': studentC.text.trim(),
                  'amount': int.tryParse(amountC.text.trim()) ?? 0,
                  'method': method,
                  'memo': memoC.text.trim(),
                  'date': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. 월별 정산 ───
class MonthlySettlementPage extends StatefulWidget {
  const MonthlySettlementPage({super.key});

  @override
  State<MonthlySettlementPage> createState() => _MonthlySettlementPageState();
}

class _MonthlySettlementPageState extends State<MonthlySettlementPage> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월 선택
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Text(_selectedMonth, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
          const SizedBox(height: 16),
          // 수입/지출/순이익
          StreamBuilder<List<QuerySnapshot>>(
            stream: _getMonthlyData(),
            builder: (context, snap) {
              int income = 0, expense = 0;
              if (snap.hasData) {
                for (final doc in snap.data![0].docs) {
                  income += ((doc.data() as Map<String, dynamic>)['amount'] as num?)?.toInt() ?? 0;
                }
                for (final doc in snap.data![1].docs) {
                  expense += ((doc.data() as Map<String, dynamic>)['amount'] as num?)?.toInt() ?? 0;
                }
              }
              final profit = income - expense;

              return Row(children: [
                _summaryCard('수입', _formatWon(income), AppTheme.primaryColor),
                const SizedBox(width: 12),
                _summaryCard('지출 (선생님 급여 등)', _formatWon(expense), const Color(0xFFE17055)),
                const SizedBox(width: 12),
                _summaryCard('순이익', _formatWon(profit), profit >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor),
              ]);
            },
          ),
          const SizedBox(height: 24),
          const Text('선생님 급여 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildTeacherPayroll(),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Stream<List<QuerySnapshot>> _getMonthlyData() {
    final income = FirebaseFirestore.instance.collection('payments')
        .where('month', isEqualTo: _selectedMonth).snapshots();
    final expense = FirebaseFirestore.instance.collection('expenses')
        .where('month', isEqualTo: _selectedMonth).snapshots();
    return income.asyncMap((i) async => [i, await expense.first]);
  }

  Widget _buildTeacherPayroll() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teacher_payroll')
          .where('month', isEqualTo: _selectedMonth).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _empty('급여 내역이 없습니다.');
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _header(['선생님', '수업 횟수', '단가', '총 급여', '지급 상태'], [3, 2, 2, 2, 2]),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final count = (d['classCount'] as num?)?.toInt() ?? 0;
              final rate = (d['rate'] as num?)?.toInt() ?? 0;
              return _row([
                d['teacherName'] ?? '-',
                '${count}회',
                _formatWon(rate),
                _formatWon(count * rate),
                d['paid'] == true ? '지급완료' : '미지급',
              ], [3, 2, 2, 2, 2]);
            }),
          ]),
        );
      },
    );
  }

  void _changeMonth(int delta) {
    final parts = _selectedMonth.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta);
    setState(() => _selectedMonth = DateFormat('yyyy-MM').format(dt));
  }
}

// ─── 4. 부가세 ───
class VatPage extends StatelessWidget {
  const VatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${now.year}년 ${quarter}분기 부가세', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('payments').snapshots(),
            builder: (context, snap) {
              int totalSales = 0;
              for (final doc in snap.data?.docs ?? []) {
                totalSales += ((doc.data() as Map<String, dynamic>)['amount'] as num?)?.toInt() ?? 0;
              }
              final vat = (totalSales * 0.1).round();
              final supplyPrice = totalSales - vat;

              return Row(children: [
                _vatCard('총 매출', _formatWon(totalSales), AppTheme.primaryColor),
                const SizedBox(width: 12),
                _vatCard('공급가액', _formatWon(supplyPrice), AppTheme.secondaryColor),
                const SizedBox(width: 12),
                _vatCard('부가세 (10%)', _formatWon(vat), const Color(0xFFE17055)),
              ]);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              Expanded(child: Text(
                '부가세 신고 기한: ${now.year}년 ${quarter == 1 ? "4/25" : quarter == 2 ? "7/25" : quarter == 3 ? "10/25" : "1/25"}\n'
                '간이과세자는 1월, 7월 신고',
                style: TextStyle(fontSize: 13, color: Colors.orange.shade700, height: 1.5),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _vatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

// ─── 5. 카드 매출 ───
class CardSalesPage extends StatelessWidget {
  const CardSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Spacer(), _addBtn(context, '카드 매출 등록', () => _showCardForm(context))]),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('card_sales').orderBy('date', descending: true).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];

              // 카드사별 합계
              final byCard = <String, int>{};
              int totalFee = 0;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final card = d['cardCompany'] ?? '기타';
                final amount = (d['amount'] as num?)?.toInt() ?? 0;
                final fee = (d['fee'] as num?)?.toInt() ?? 0;
                byCard[card] = (byCard[card] ?? 0) + amount;
                totalFee += fee;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카드사별 요약
                  if (byCard.isNotEmpty)
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: [
                        ...byCard.entries.map((e) => _cardChip(e.key, _formatWon(e.value))),
                        _cardChip('총 수수료', _formatWon(totalFee), isWarning: true),
                      ],
                    ),
                  const SizedBox(height: 20),
                  if (docs.isEmpty) _empty('카드 매출 내역이 없습니다.')
                  else Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      _header(['일자', '카드사', '매출액', '수수료', '입금예정일', '상태'], [2, 2, 2, 2, 2, 2]),
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final date = (d['date'] as Timestamp?)?.toDate();
                        final depositDate = (d['depositDate'] as Timestamp?)?.toDate();
                        return _row([
                          date != null ? DateFormat('M/d').format(date) : '-',
                          d['cardCompany'] ?? '-',
                          _formatWon((d['amount'] as num?)?.toInt() ?? 0),
                          _formatWon((d['fee'] as num?)?.toInt() ?? 0),
                          depositDate != null ? DateFormat('M/d').format(depositDate) : '-',
                          d['deposited'] == true ? '입금완료' : '대기',
                        ], [2, 2, 2, 2, 2, 2]);
                      }),
                    ]),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cardChip(String label, String value, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isWarning ? Colors.orange.shade200 : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isWarning ? Colors.orange.shade700 : AppTheme.onSurfaceColor)),
      ]),
    );
  }

  void _showCardForm(BuildContext context) {
    final amountC = TextEditingController();
    final feeC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String card = '신한';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('카드 매출 등록'),
          content: SizedBox(
            width: 400,
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: card,
                decoration: _deco('카드사'),
                items: ['신한', '삼성', '현대', '국민', 'BC', '롯데', '하나', '농협'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => ss(() => card = v ?? '신한'),
              ),
              const SizedBox(height: 12),
              _formField(amountC, '매출액 (원)', required: true, number: true),
              const SizedBox(height: 12),
              _formField(feeC, '수수료 (원)', number: true),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await FirebaseFirestore.instance.collection('card_sales').add({
                  'cardCompany': card,
                  'amount': int.tryParse(amountC.text.trim()) ?? 0,
                  'fee': int.tryParse(feeC.text.trim()) ?? 0,
                  'date': FieldValue.serverTimestamp(),
                  'depositDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
                  'deposited': false,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 공통 헬퍼 ───
String _formatWon(int amount) {
  if (amount >= 10000) return '${(amount / 10000).toStringAsFixed(amount % 10000 == 0 ? 0 : 1)}만원';
  return NumberFormat('#,###').format(amount) + '원';
}

Widget _empty(String msg) => Container(
  padding: const EdgeInsets.all(40),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
  child: Center(child: Text(msg, style: TextStyle(color: Colors.grey.shade500))),
);

Widget _header(List<String> labels, List<int> flexes) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  decoration: BoxDecoration(
    color: AppTheme.primaryColor.withValues(alpha: 0.05),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
  ),
  child: Row(children: List.generate(labels.length, (i) => Expanded(
    flex: flexes[i],
    child: Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))),
  ))),
);

Widget _row(List<String> cells, List<int> flexes, {List<Widget>? trailing}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
    child: Row(children: [
      ...List.generate(cells.length, (i) => Expanded(
        flex: flexes[i],
        child: Text(cells[i], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
      )),
      if (trailing != null) ...trailing.map((w) => Expanded(flex: 2, child: w)),
    ]),
  );
}

Widget _statusBadge(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
  child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
);

Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
  onTap: onTap, borderRadius: BorderRadius.circular(6),
  child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color)),
);

Widget _addBtn(BuildContext context, String label, VoidCallback onTap) => ElevatedButton.icon(
  onPressed: onTap, icon: const Icon(Icons.add, size: 18), label: Text(label),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);

InputDecoration _deco(String label) => InputDecoration(
  labelText: label, filled: true, fillColor: AppTheme.backgroundColor,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

Widget _formField(TextEditingController c, String label, {bool required = false, bool number = false}) {
  return TextFormField(
    controller: c,
    keyboardType: number ? TextInputType.number : null,
    validator: (v) {
      if (required && (v == null || v.trim().isEmpty)) return '필수 입력입니다.';
      if (number && v != null && v.isNotEmpty && int.tryParse(v.trim()) == null) return '숫자를 입력하세요.';
      return null;
    },
    decoration: _deco(label),
  );
}
