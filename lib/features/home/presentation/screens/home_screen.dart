import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/group_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/countdown_timer_widget.dart';
import '../../../../shared/widgets/group_progress_widget.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/connectivity_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../features/orders/presentation/screens/orders_screen.dart';
import '../../../../features/auth/presentation/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    _GroupsTab(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(productsProvider);
    final activeGroupsAsync = ref.watch(activeGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.businessName.split(' ').first ?? 'Buyer'}!',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Find deals & save more',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Consumer(
                          builder: (ctx, ref, _) {
                            final unread =
                                ref.watch(unreadCountProvider);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white),
                                  onPressed: () => ctx
                                      .push(AppRoutes.notifications),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unread > 9
                                              ? '9+'
                                              : '$unread',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.search),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Search products...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats banner
                _StatsBanner(),
                const SizedBox(height: 8),

                // Active Deals
                _SectionHeader(
                  title: 'Active Group Deals',
                  onViewAll: () {},
                ),
                activeGroupsAsync.when(
                  data: (groups) => groups.isEmpty
                      ? _EmptyState(
                          icon: Icons.groups_outlined,
                          message: 'No active deals right now.\nCheck back soon!',
                        )
                      : SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: groups.length,
                            itemBuilder: (ctx, i) =>
                                _DealCard(group: groups[i]),
                          ),
                        ),
                  loading: () => const _LoadingShimmer(height: 220),                  error: (e, _) => _ErrorWidget(message: e.toString()),
                ),
                const SizedBox(height: 8),

                // Categories
                _SectionHeader(title: 'Browse Categories', onViewAll: null),
                _CategoriesRow(),
                const SizedBox(height: 8),

                // Products
                _SectionHeader(
                  title: 'All Products',
                  onViewAll: () {},
                ),
                productsAsync.when(
                  data: (products) => products.isEmpty
                      ? _EmptyState(
                          icon: Icons.inventory_2_outlined,
                          message: 'No products available yet.',
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: products.length,
                          itemBuilder: (ctx, i) =>
                              _ProductListCard(product: products[i]),
                        ),
                  loading: () => const _LoadingShimmer(height: 300),
                  error: (e, _) => _ErrorWidget(message: e.toString()),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '500+',
              label: 'Active Buyers',
              icon: Icons.people_outline,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _StatItem(
              value: '₹2Cr+',
              label: 'Savings Generated',
              icon: Icons.savings_outlined,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _StatItem(
              value: '50+',
              label: 'Suppliers',
              icon: Icons.store_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _DealCard extends ConsumerWidget {
  final GroupModel group;

  const _DealCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/group/${group.id}'),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: AppColors.dealCardGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.memberCount} buyers',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                group.supplierName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Price',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(group.currentPricePerUnit),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'per unit',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  CountdownTimerWidget(
                    deadline: group.deadline,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.progressToTarget,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${group.totalQuantity} / ${group.targetQuantity ?? group.minimumQuantity} units',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListCard extends ConsumerWidget {
  final ProductModel product;

  const _ProductListCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.surfaceVariant,
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textHint,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textHint,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.supplierName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'From ${Formatters.formatCurrency(product.lowestPrice)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (product.highestPrice > product.lowestPrice)
                        Text(
                          Formatters.formatDiscount(
                              product.highestPrice, product.lowestPrice),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Min. ${product.minimumOrderQuantity} ${product.unit}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<Map<String, dynamic>> _categories = const [
    {'icon': Icons.agriculture, 'label': 'Agriculture'},
    {'icon': Icons.electrical_services, 'label': 'Electronics'},
    {'icon': Icons.construction, 'label': 'Building'},
    {'icon': Icons.checkroom, 'label': 'Textiles'},
    {'icon': Icons.local_dining, 'label': 'Food'},
    {'icon': Icons.more_horiz, 'label': 'More'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(cat['icon'] as IconData,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  cat['label'] as String,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGroupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: myGroupsAsync.when(
        data: (groups) => groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups_outlined,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text(
                      "You haven't joined any groups yet.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Browse products and join a group deal!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      // Navigate to home tab (index 0) via the parent HomeScreen
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Browse Deals'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myGroupsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (ctx, i) => _GroupListCard(group: groups[i]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _GroupListCard extends StatelessWidget {
  final GroupModel group;

  const _GroupListCard({required this.group});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;

    switch (group.status) {
      case 'active':
        statusColor = AppColors.groupActive;
        statusLabel = 'Active';
        break;
      case 'completed':
        statusColor = AppColors.groupCompleted;
        statusLabel = 'Completed';
        break;
      case 'expired':
        statusColor = AppColors.groupExpired;
        statusLabel = 'Expired';
        break;
      default:
        statusColor = AppColors.groupPending;
        statusLabel = 'Pending';
    }

    return GestureDetector(
      onTap: () => context.push('/group/${group.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.productName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              group.supplierName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GroupProgressWidget(group: group, showTiers: false, compact: true),
            if (group.status == 'active') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CountdownTimerWidget(deadline: group.deadline, compact: true),
                  Text(
                    Formatters.formatCurrency(group.currentPricePerUnit) +
                        '/unit',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  final double height;

  const _LoadingShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Error: $message',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
