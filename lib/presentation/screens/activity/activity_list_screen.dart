// lib/presentation/screens/activity/activity_list_screen_refactored.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/mixins/list_state_mixin.dart';
import '../../../core/widgets/common/loading_state_widget.dart';
import '../../../core/widgets/common/error_state_widget.dart';
import '../../../core/widgets/common/empty_state_widget.dart';
import '../../../core/widgets/common/search_bar_widget.dart';
import '../../../core/widgets/common/stats_bar_widget.dart';
import '../../../core/widgets/common/loading_more_widget.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/services/api/activity_api_service.dart';
import '../../widgets/activity/activity_card_widget.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> with TickerProviderStateMixin, ListStateMixin {
  final ActivityApiService _activityApiService = ActivityApiService();
  late TabController _tabController;

  List<ActivityListItem> _activities = [];
  ActivityFilter _currentFilter = ActivityFilter.open;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final oldFilter = _currentFilter;
    final newFilter = _tabController.index == 0 ? ActivityFilter.open : ActivityFilter.closed;

    if (oldFilter != newFilter) {
      _clearActivitiesAndReload(newFilter);
    }
  }

  void _clearActivitiesAndReload(ActivityFilter newFilter) {
    setState(() {
      isLoading = true;
      _activities.clear();
      errorMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentFilter = newFilter;
          currentPage = 1;
          hasMoreData = true;
          searchQuery = '';
          searchController.clear();
        });
        loadItems(isRefresh: true);
      }
    });
  }

  @override
  Future<void> loadItems({bool isRefresh = false}) async {
    if (isRefresh) resetPagination();
    showLoadingState(isRefresh: isRefresh);

    try {
      final result = await _activityApiService.getActivityList(
        filter: _currentFilter,
        page: currentPage,
        pageSize: pageSize,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (!mounted) return;

      final finalActivities = await _enrichActivitiesIfNeeded(result.data);

      setState(() {
        if (isRefresh || currentPage == 1) {
          _activities = finalActivities;
        } else {
          _activities.addAll(result.data);
        }

        totalCount = result.total;
        hasMoreData = _activities.length < totalCount;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setError(e.toString());
        if (isRefresh || currentPage == 1) {
          SnackbarHelper.showError(
            context: context,
            message: 'Aktiviteler yüklenirken hata oluştu: ${e.toString()}',
          );
        }
      }
    }
  }

  @override
  Future<void> loadMoreItems() async {
    if (isLoadingMore || !hasMoreData) return;

    showLoadingMoreState();

    try {
      final result = await _activityApiService.getActivityList(
        filter: _currentFilter,
        page: currentPage,
        pageSize: pageSize,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _activities.addAll(result.data);
          hasMoreData = _activities.length < result.total;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentPage--; // Revert page increment
          isLoadingMore = false;
        });
      }
    }
  }

  Future<List<ActivityListItem>> _enrichActivitiesIfNeeded(List<ActivityListItem> activities) async {
    // Only enrich first page open activities
    if (currentPage == 1 && _currentFilter == ActivityFilter.open && activities.isNotEmpty) {
      final activitiesToEnrich = activities.take(2).toList();
      final enrichedActivities = await _activityApiService.enrichActivitiesWithAddressesByName(activitiesToEnrich);

      return [
        ...enrichedActivities,
        ...activities.skip(2),
      ];
    }
    return activities;
  }

  void _onActivityTap(ActivityListItem activity) {
    Navigator.pushNamed(
      context,
      AppRoutes.addActivity,
      arguments: {'activityId': activity.id},
    ).then((result) {
      if (result == true) {
        loadItems(isRefresh: true);
      }
    });
  }

  void _onAddActivity() {
    Navigator.pushNamed(context, AppRoutes.addActivity).then((result) {
      if (result == true) {
        loadItems(isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //final size = AppSizes.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Aktiviteler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _onAddActivity,
            icon: const Icon(Icons.add),
            tooltip: 'Aktivite Ekle',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Açık Aktiviteler'),
            Tab(text: 'Kapalı Aktiviteler'),
          ],
        ),
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: searchController,
            hintText: 'Aktivite ara...',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
            hasValue: searchQuery.isNotEmpty,
          ),
          StatsBarWidget(
            icon: Icons.assignment,
            text:
                '${_activities.length}${totalCount > _activities.length ? '+' : ''} / $totalCount ${_currentFilter == ActivityFilter.open ? 'Açık' : 'Kapalı'} Aktivite',
            iconColor: _currentFilter == ActivityFilter.open ? AppColors.success : AppColors.error,
            isLoading: isLoading || isLoadingMore,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBody(),
                _buildBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && _activities.isEmpty) {
      return const LoadingStateWidget(
        title: 'Aktiviteler yükleniyor...',
        subtitle: 'Lütfen bekleyin',
      );
    }

    if (errorMessage != null && _activities.isEmpty) {
      return ErrorStateWidget(
        title: 'Bir hata oluştu',
        message: errorMessage!,
        onRetry: () => loadItems(isRefresh: true),
      );
    }

    if (_activities.isEmpty) {
      return EmptyStateWidget(
        icon: searchQuery.isNotEmpty
            ? Icons.search_off
            : (_currentFilter == ActivityFilter.open ? Icons.assignment_outlined : Icons.assignment_turned_in),
        title: searchQuery.isNotEmpty ? 'Aktivite bulunamadı' : '${_currentFilter == ActivityFilter.open ? 'Açık' : 'Kapalı'} aktivite yok',
        message: searchQuery.isNotEmpty
            ? '"$searchQuery" aramasına uygun aktivite bulunamadı'
            : 'Henüz ${_currentFilter == ActivityFilter.open ? 'açık' : 'kapalı'} aktivite bulunmuyor',
        actionButtonText: searchQuery.isEmpty && _currentFilter == ActivityFilter.open ? 'Aktivite Ekle' : null,
        onActionPressed: searchQuery.isEmpty && _currentFilter == ActivityFilter.open ? _onAddActivity : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => loadItems(isRefresh: true),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(AppSizes.of(context).cardPadding),
        itemCount: _activities.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _activities.length) {
            return isLoadingMore ? const LoadingMoreWidget() : const SizedBox.shrink();
          }

          final activity = _activities[index];
          return ActivityCardWidget(
            activity: activity,
            isOpen: _currentFilter == ActivityFilter.open,
            onTap: () => _onActivityTap(activity),
          );
        },
      ),
    );
  }
}
