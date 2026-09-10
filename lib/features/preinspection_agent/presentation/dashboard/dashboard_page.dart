import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/claim_list_card.dart';
import '../../data/demo_claims.dart';
import '../../domain/models/claim.dart';
import '../../state/session_provider.dart';

enum _DashboardView { total, completed, pending, search }

/// Port of `DashboardPage.jsx`.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  _DashboardView _view = _DashboardView.total;
  final _searchController = TextEditingController();
  String _query = '';

  int get _totalCount => demoClaims.length;
  int get _completedCount =>
      demoClaims.where((c) => c.status == 'Completed').length;
  int get _pendingCount =>
      demoClaims.where((c) => c.status == 'Pending').length;

  List<Claim> get _filteredClaims {
    switch (_view) {
      case _DashboardView.completed:
        return demoClaims.where((c) => c.status == 'Completed').toList();
      case _DashboardView.pending:
        return demoClaims.where((c) => c.status == 'Pending').toList();
      case _DashboardView.search:
        final q = _query.trim().toLowerCase();
        if (q.isEmpty) return demoClaims;
        return demoClaims.where((c) {
          return [
            c.claimNumber,
            c.registrationNumber,
            c.insuredName,
            c.vehicle,
            c.location,
            c.insurerName,
          ].any((f) => f.toLowerCase().contains(q));
        }).toList();
      case _DashboardView.total:
        return demoClaims;
    }
  }

  String get _listTitle {
    switch (_view) {
      case _DashboardView.total:
        return 'All Preinspections';
      case _DashboardView.completed:
        return 'Completed';
      case _DashboardView.pending:
        return 'Pending';
      case _DashboardView.search:
        final count = _filteredClaims.length;
        return _query.isEmpty
            ? 'All Preinspections'
            : '$count result${count != 1 ? 's' : ''} found';
    }
  }

  Color get _listBadgeColor {
    switch (_view) {
      case _DashboardView.total:
        return AppColors.primary;
      case _DashboardView.completed:
        return AppColors.statusCompleted;
      case _DashboardView.pending:
        return AppColors.statusPending;
      case _DashboardView.search:
        return AppColors.iconClaim;
    }
  }

  void _selectView(_DashboardView view) {
    setState(() {
      _view = view;
      if (view != _DashboardView.search) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claims = _filteredClaims;
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Container(
              color: AppColors.bgHeader,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Welcome ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    TextSpan(
                                      // The signed-in id, not a hardcoded
                                      // workshop name -- this portal is used
                                      // by agents and surveyors alike.
                                      text: session?.userId ?? 'Guest',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (session != null)
                                Text(
                                  session.role.displayName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (session != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              session.role.shortLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                // Fixed height, not an aspect ratio: the label
                                // can wrap to two lines and must still fit
                                // inside the card on any screen width.
                                mainAxisExtent: 88,
                              ),
                              children: [
                                _StatCard(
                                  icon: Icons.description_outlined,
                                  count: _totalCount.toString().padLeft(2, '0'),
                                  label: 'Total Preinspection',
                                  gradient: AppColors.cardTotalClaims,
                                  textColor: Colors.white,
                                  selected: _view == _DashboardView.total,
                                  onTap: () => _selectView(_DashboardView.total),
                                ),
                                _StatCard(
                                  icon: Icons.task_alt,
                                  count: _completedCount.toString().padLeft(2, '0'),
                                  label: 'Completed',
                                  gradient: AppColors.cardSurveyCompleted,
                                  textColor: const Color(0xFF009348),
                                  selected: _view == _DashboardView.completed,
                                  onTap: () => _selectView(_DashboardView.completed),
                                ),
                                _StatCard(
                                  icon: Icons.pending_actions,
                                  count: _pendingCount.toString().padLeft(2, '0'),
                                  label: 'Pending',
                                  color: AppColors.cardPendingSurvey,
                                  textColor: Colors.white,
                                  selected: _view == _DashboardView.pending,
                                  onTap: () => _selectView(_DashboardView.pending),
                                ),
                                _StatCard(
                                  icon: Icons.search,
                                  count: '',
                                  label: 'Search',
                                  gradient: AppColors.cardSearchClaim,
                                  textColor: Colors.white,
                                  selected: _view == _DashboardView.search,
                                  onTap: () => _selectView(_DashboardView.search),
                                ),
                              ],
                            ),
                            if (_view == _DashboardView.search) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgInput,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderInput),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (v) => setState(() => _query = v),
                                        decoration: const InputDecoration(
                                          hintText: 'Search PI ref. number, reg. no., name…',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    if (_query.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                                        onPressed: () => setState(() {
                                          _query = '';
                                          _searchController.clear();
                                        }),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_listTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _listBadgeColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    claims.length.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (claims.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No preinspections match your search.',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                              )
                            else
                              ...claims.map(
                                (claim) => ClaimListCard(
                                  insurerName: claim.insurerName,
                                  claimNumber: claim.claimNumber,
                                  registrationNumber: claim.registrationNumber,
                                  insuredName: claim.insuredName,
                                  status: claim.status,
                                  onViewDetails: () => context.go(AppRoutes.claimStart),
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
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    this.gradient,
    this.color,
    required this.textColor,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String count;
  final String label;
  final Gradient? gradient;
  final Color? color;
  final Color textColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: textColor),
              ),
              child: Icon(icon, color: textColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (count.isNotEmpty)
                    Text(count,
                        style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.bold, height: 1.1)),
                  Text(
                    label,
                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
