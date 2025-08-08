// lib/presentation/screens/activity/activity_list_screen_refactored.dart - DEBUG VERSİON
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
  List<ActivityListItem> _allActivities = [];
  ActivityFilter _currentFilter = ActivityFilter.open;
  int _apiTotalCount = 0;

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
      _allActivities.clear();
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

  void _applySearch() {
    List<ActivityListItem> filteredActivities = _allActivities;

    if (searchQuery.isNotEmpty) {
      filteredActivities = _allActivities.where((activity) {
        final firmaName = activity.firma?.toLowerCase() ?? '';
        final searchLower = searchQuery.toLowerCase();
        return firmaName.contains(searchLower);
      }).toList();

      debugPrint('[ACTIVITY_LIST] 🔍 Firma filter: "$searchQuery"');
      debugPrint('[ACTIVITY_LIST] 📊 Results: ${filteredActivities.length}/${_allActivities.length}');
      debugPrint('[ACTIVITY_LIST] 📊 Cache: ${_allActivities.length} / API Total: $_apiTotalCount');
    }

    setState(() {
      _activities = filteredActivities;

      if (searchQuery.isNotEmpty) {
        totalCount = filteredActivities.length;
        hasMoreData = _allActivities.length < _apiTotalCount;
      } else {
        totalCount = _apiTotalCount;
        hasMoreData = _allActivities.length < _apiTotalCount;
      }
    });
  }

  @override
  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _applySearch();
  }

  @override
  void onClearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = '';
    });
    _applySearch();
  }

  @override
  Future<void> loadItems({bool isRefresh = false}) async {
    // 🔍 DEBUG 1: Fonksiyon başlangıcı
    debugPrint('🟡 [DEBUG] ===== LOAD ITEMS STARTED =====');
    debugPrint('🟡 [DEBUG] Filter: $_currentFilter');
    debugPrint('🟡 [DEBUG] isRefresh: $isRefresh');
    debugPrint('🟡 [DEBUG] Current activities count: ${_activities.length}');

    if (isRefresh) {
      resetPagination();
      _allActivities.clear();
      debugPrint('🟡 [DEBUG] Cleared all activities for refresh');
    }

    showLoadingState(isRefresh: isRefresh);

    try {
      // 🔍 DEBUG 2: API çağrısı öncesi
      debugPrint('🟡 [DEBUG] ===== CALLING API =====');
      debugPrint('🟡 [DEBUG] API Endpoint: getActivityList');
      debugPrint('🟡 [DEBUG] Parameters: filter=$_currentFilter, page=1, pageSize=999999');

      final result = await _activityApiService.getActivityList(
        filter: _currentFilter,
        page: 1,
        pageSize: 999999,
        searchQuery: null,
      );

      // 🔍 DEBUG 3: API yanıtı
      debugPrint('🟢 [DEBUG] ===== API SUCCESS =====');
      debugPrint('🟢 [DEBUG] Response data length: ${result.data.length}');
      debugPrint('🟢 [DEBUG] Response total: ${result.total}');

      if (result.data.isNotEmpty) {
        debugPrint('🟢 [DEBUG] First activity: ${result.data.first.firma} - ${result.data.first.konu}');
        debugPrint('🟢 [DEBUG] Last activity: ${result.data.last.firma} - ${result.data.last.konu}');

        // Firma çeşitliliği
        final firmaNames = result.data.map((a) => a.firma).where((f) => f != null).toSet();
        debugPrint('🟢 [DEBUG] Unique company count: ${firmaNames.length}');
        debugPrint('🟢 [DEBUG] Sample companies: ${firmaNames.take(5).toList()}');
      }

      if (!mounted) {
        debugPrint('🔴 [DEBUG] Widget not mounted, returning');
        return;
      }

      // 🔍 DEBUG 4: Enrichment işlemi
      debugPrint('🟡 [DEBUG] ===== STARTING ENRICHMENT =====');
      final finalActivities = await _enrichActivitiesIfNeeded(result.data);
      debugPrint('🟢 [DEBUG] Enrichment completed: ${finalActivities.length} activities');

      setState(() {
        _allActivities = finalActivities;
        _apiTotalCount = result.total;
        hasMoreData = false;
        isLoading = false;
        errorMessage = null;
        currentPage = 1;
      });

      // 🔍 DEBUG 5: State güncellendikten sonra
      debugPrint('🟢 [DEBUG] ===== STATE UPDATED =====');
      debugPrint('🟢 [DEBUG] _allActivities: ${_allActivities.length}');
      debugPrint('🟢 [DEBUG] _apiTotalCount: $_apiTotalCount');
      debugPrint('🟢 [DEBUG] hasMoreData: $hasMoreData');
      debugPrint('🟢 [DEBUG] isLoading: $isLoading');

      _applySearch();

      // 🔍 DEBUG 6: Search uygulandıktan sonra
      debugPrint('🟢 [DEBUG] ===== AFTER SEARCH APPLIED =====');
      debugPrint('🟢 [DEBUG] _activities (displayed): ${_activities.length}');
      debugPrint('🟢 [DEBUG] totalCount: $totalCount');
    } catch (e, stackTrace) {
      // 🔍 DEBUG 7: Hata durumu
      debugPrint('🔴 [DEBUG] ===== API ERROR =====');
      debugPrint('🔴 [DEBUG] Error type: ${e.runtimeType}');
      debugPrint('🔴 [DEBUG] Error message: $e');
      debugPrint('🔴 [DEBUG] Stack trace: $stackTrace');

      if (mounted) {
        setError(e.toString());
        SnackbarHelper.showError(
          context: context,
          message: 'Aktiviteler yüklenirken hata oluştu: ${e.toString()}',
        );
      }
    }

    debugPrint('🟡 [DEBUG] ===== LOAD ITEMS COMPLETED =====');
  }

  @override
  Future<void> loadMoreItems() async {
    debugPrint('🟡 [DEBUG] loadMoreItems called - but disabled for bulk loading');
    return;
  }

  Future<List<ActivityListItem>> _enrichActivitiesIfNeeded(List<ActivityListItem> activities) async {
    debugPrint('🟡 [DEBUG] _enrichActivitiesIfNeeded called with ${activities.length} activities');

    if (currentPage == 1 && _currentFilter == ActivityFilter.open && activities.isNotEmpty) {
      debugPrint('🟡 [DEBUG] Starting enrichment for first 2 activities');
      final activitiesToEnrich = activities.take(2).toList();

      try {
        final enrichedActivities = await _activityApiService.enrichActivitiesWithAddressesByName(activitiesToEnrich);
        debugPrint('🟢 [DEBUG] Enrichment successful');

        return [
          ...enrichedActivities,
          ...activities.skip(2),
        ];
      } catch (e) {
        debugPrint('🔴 [DEBUG] Enrichment failed: $e');
        return activities;
      }
    }

    debugPrint('🟡 [DEBUG] No enrichment needed');
    return activities;
  }

  void _onActivityTap(ActivityListItem activity) {
    debugPrint('🟡 [DEBUG] Activity tapped: ${activity.id} - ${activity.firma}');
    Navigator.pushNamed(
      context,
      AppRoutes.addActivity,
      arguments: {'activityId': activity.id},
    ).then((result) {
      if (result == true) {
        debugPrint('🟡 [DEBUG] Activity updated, refreshing list');
        loadItems(isRefresh: true);
      }
    });
  }

  void _onAddActivity() {
    debugPrint('🟡 [DEBUG] Add activity button pressed');
    Navigator.pushNamed(context, AppRoutes.addActivity).then((result) {
      if (result == true) {
        debugPrint('🟡 [DEBUG] New activity added, refreshing list');
        loadItems(isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG 8: UI Render
    debugPrint('🟡 [DEBUG] ===== BUILDING UI =====');
    debugPrint('🟡 [DEBUG] isLoading: $isLoading');
    debugPrint('🟡 [DEBUG] errorMessage: $errorMessage');
    debugPrint('🟡 [DEBUG] _activities.length: ${_activities.length}');
    debugPrint('🟡 [DEBUG] searchQuery: "$searchQuery"');

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
            hintText: 'Firma adına göre ara...',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
            hasValue: searchQuery.isNotEmpty,
          ),
          StatsBarWidget(
            icon: Icons.assignment,
            text: searchQuery.isNotEmpty
                ? '${_activities.length} sonuç (${_allActivities.length}/$_apiTotalCount yüklendi)'
                : '${_activities.length}${totalCount > _activities.length ? '+' : ''} / $totalCount ${_currentFilter == ActivityFilter.open ? 'Açık' : 'Kapalı'} Aktivite',
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
    debugPrint('🟡 [DEBUG] _buildBody called - isLoading: $isLoading, activities: ${_activities.length}, error: $errorMessage');

    if (isLoading && _activities.isEmpty) {
      debugPrint('🟡 [DEBUG] Showing loading state');
      return const LoadingStateWidget(
        title: 'Aktiviteler yükleniyor...',
        subtitle: 'Lütfen bekleyin',
      );
    }

    if (errorMessage != null && _activities.isEmpty) {
      debugPrint('🔴 [DEBUG] Showing error state: $errorMessage');
      return ErrorStateWidget(
        title: 'Bir hata oluştu',
        message: errorMessage!,
        onRetry: () => loadItems(isRefresh: true),
      );
    }

    if (_activities.isEmpty) {
      debugPrint('🟡 [DEBUG] Showing empty state');
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

    debugPrint('🟢 [DEBUG] Showing activities list with ${_activities.length} items');
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
