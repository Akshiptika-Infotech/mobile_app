import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/admin/domain/student_model.dart';
import 'package:mobile_app/features/admin/providers/student_provider.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _tabController.index == 0 ? 'active' : 'transferred';
    ref.read(studentsListProvider.notifier).setStatus(status);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(studentsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(studentsListProvider.notifier).setSearch(query);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentsListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(studentsListProvider.notifier).load(refresh: true),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 0,
              title: const Text('Students'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(112),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SearchBar(
                        controller: _searchController,
                        hintText: 'Search by name, roll or admission no.',
                        leading: const Icon(Icons.search),
                        trailing: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                        ],
                        onChanged: _onSearchChanged,
                        elevation: const WidgetStatePropertyAll(1),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Active'),
                        Tab(text: 'Transferred / Left'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: _buildBody(state, colorScheme),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/students/new'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildBody(StudentsListState state, ColorScheme colorScheme) {
    if (state.isLoading) {
      return _StudentListSkeleton();
    }

    if (state.error != null && state.students.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(studentsListProvider.notifier).load(),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: state.students.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.students.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _StudentCard(
          student: state.students[index],
          onTap: () =>
              context.push('/admin/students/${state.students[index].id}'),
        );
      },
    );
  }
}

// ── Student Card ──────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onTap});
  final StudentModel student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: CachedNetworkImageProvider(student.photoUrl!),
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    student.initials,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.className} - ${student.section}  •  Roll: ${student.rollNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adm: ${student.admissionNumber}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _StudentListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: 8,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load students',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
