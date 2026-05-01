import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/utils/responsive_utils.dart';
import 'package:mobile_app/core/widgets/dashboard_avatar.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';
import 'package:mobile_app/features/web_admin/providers/web_admin_provider.dart';

class WebAdminDashboardScreen extends ConsumerWidget {
  const WebAdminDashboardScreen({super.key});

  static const _accent = Color(0xFF7C3AED);
  static const _accentDark = Color(0xFF5B21B6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(webDashboardProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(webDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: ResponsiveUtils.getHeaderHeight(context),
              pinned: true,
              backgroundColor: _accent,
              elevation: 0,
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.logout_outlined, color: Colors.white),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_accent, _accentDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          DashboardAvatar(
                            imageUrl: user?.image,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            onTap: () => context.go('/web-admin/profile'),
                            fallback: const Icon(Icons.web_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello, ${user?.name.split(' ').first ?? 'Web Admin'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: dashAsync.when(
                  loading: () => const _DashboardSkeleton(),
                  error: (e, _) => _ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.refresh(webDashboardProvider.future),
                  ),
                  data: (stats) => _DashboardContent(stats: stats),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats});
  final WebDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              label: 'News Articles',
              value: '${stats.newsCount}',
              subtitle: '${stats.publishedNews} published',
              icon: Icons.newspaper_rounded,
              color: const Color(0xFF3B82F6),
            ),
            _StatCard(
              label: 'Events',
              value: '${stats.eventsCount}',
              subtitle: '${stats.publishedEvents} published',
              icon: Icons.event_rounded,
              color: const Color(0xFF10B981),
            ),
            _StatCard(
              label: 'Gallery Albums',
              value: '${stats.albumCount}',
              subtitle: 'photo collections',
              icon: Icons.photo_library_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _StatCard(
              label: 'Web Pages',
              value: '${stats.pagesCount}',
              subtitle: 'custom pages',
              icon: Icons.web_rounded,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
        if (stats.recentNews.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Recent News',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...stats.recentNews.map((article) => _NewsListTile(article: article)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsListTile extends StatelessWidget {
  const _NewsListTile({required this.article});
  final WebNewsArticle article;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('d MMM yyyy').format(article.createdAt),
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: article.published
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              article.published ? 'Published' : 'Draft',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: article.published
                    ? const Color(0xFF10B981)
                    : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shimmer = cs.surfaceContainerHighest;
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 52,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
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
