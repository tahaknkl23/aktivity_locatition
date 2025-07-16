import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/services/api/activity_api_service.dart'; // ActivityFilter buradan gelecek

// enum ActivityFilter { open, closed, all } <-- SİLİNDİ! (ActivityApiService'de tanımlı)

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> with TickerProviderStateMixin {
  final ActivityApiService _activityApiService = ActivityApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<ActivityListItem> _activities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  String _searchQuery = '';
  ActivityFilter _currentFilter = ActivityFilter.open;

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentFilter = _tabController.index == 0 ? ActivityFilter.open : ActivityFilter.closed;
        _currentPage = 1;
        _activities.clear();
        _searchQuery = '';
        _searchController.clear();
      });
      _loadActivities(isRefresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreActivities();
    }
  }

  Future<void> _loadActivities({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _activities.clear();
        _hasMoreData = true;
        _errorMessage = null;
      });
    }

    setState(() {
      _isLoading = isRefresh || _currentPage == 1;
    });

    try {
      debugPrint('[ACTIVITY_LIST] Loading activities - Filter: $_currentFilter, Page: $_currentPage, Search: $_searchQuery');

      final result = await _activityApiService.getActivityList(
        filter: _currentFilter,
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          if (isRefresh || _currentPage == 1) {
            _activities = result.data;
          } else {
            _activities.addAll(result.data);
          }

          _totalCount = result.total;
          _hasMoreData = _activities.length < _totalCount;
          _isLoading = false;
          _errorMessage = null;
        });

        debugPrint('[ACTIVITY_LIST] Loaded ${result.data.length} activities. Total: $_totalCount');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_LIST] Load error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });

        if (isRefresh || _currentPage == 1) {
          SnackbarHelper.showError(
            context: context,
            message: 'Aktiviteler yüklenirken hata oluştu: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final result = await _activityApiService.getActivityList(
        filter: _currentFilter,
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _activities.addAll(result.data);
          _hasMoreData = _activities.length < result.total;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[ACTIVITY_LIST] Load more error: $e');

      if (mounted) {
        setState(() {
          _currentPage--; // Revert page increment
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query && mounted) {
        _loadActivities(isRefresh: true);
      }
    });
  }

  void _onActivityTap(ActivityListItem activity) {
    Navigator.pushNamed(
      context,
      AppRoutes.addActivity,
      arguments: {'activityId': activity.id},
    ).then((result) {
      if (result == true) {
        _loadActivities(isRefresh: true);
      }
    });
  }

  void _onAddActivity() {
    Navigator.pushNamed(context, AppRoutes.addActivity).then((result) {
      if (result == true) {
        _loadActivities(isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

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
          _buildSearchBar(size),
          _buildStatsBar(size),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBody(size),
                _buildBody(size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Aktivite ara...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.cardPadding,
            vertical: size.cardPadding * 0.7,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
        ),
        onChanged: _onSearchChanged,
        style: TextStyle(fontSize: size.textSize),
      ),
    );
  }

  Widget _buildStatsBar(AppSizes size) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.cardPadding,
        vertical: size.smallSpacing,
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment,
            size: size.smallIcon,
            color: _currentFilter == ActivityFilter.open ? AppColors.success : AppColors.error,
          ),
          SizedBox(width: size.smallSpacing),
          Text(
            '${_activities.length}${_totalCount > _activities.length ? '+' : ''} / $_totalCount ${_currentFilter == ActivityFilter.open ? 'Açık' : 'Kapalı'} Aktivite',
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_isLoading || _isLoadingMore)
            SizedBox(
              width: size.smallIcon,
              height: size.smallIcon,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AppSizes size) {
    if (_isLoading && _activities.isEmpty) {
      return _buildLoadingState(size);
    }

    if (_errorMessage != null && _activities.isEmpty) {
      return _buildErrorState(size);
    }

    if (_activities.isEmpty) {
      return _buildEmptyState(size);
    }

    return RefreshIndicator(
      onRefresh: () => _loadActivities(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(size.cardPadding),
        itemCount: _activities.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // GÜVENLİK KONTROLÜ - EKLENEN
          if (index >= _activities.length) {
            // Loading more indicator
            if (_isLoadingMore && index == _activities.length) {
              return _buildLoadingMoreIndicator(size);
            }
            // Geçersiz index - empty container döndür
            return const SizedBox.shrink();
          }

          // Normal aktivite kartı
          final activity = _activities[index];
          return _buildActivityCard(activity, size);
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityListItem activity, AppSizes size) {
    final isOpen = _currentFilter == ActivityFilter.open;

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        elevation: 2,
        child: InkWell(
          onTap: () => _onActivityTap(activity),
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.cardBorderRadius),
              border: Border(
                left: BorderSide(
                  color: isOpen ? AppColors.success : AppColors.error,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(size.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isOpen ? Icons.assignment_outlined : Icons.assignment_turned_in,
                          color: isOpen ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: size.smallSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activity.tipi != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  activity.tipi!,
                                  style: TextStyle(
                                    fontSize: size.smallText * 0.9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: size.tinySpacing),
                            ],
                            Text(
                              activity.konu ?? 'Konu belirtilmemiş',
                              style: TextStyle(
                                fontSize: size.textSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontStyle: activity.konu == null ? FontStyle.italic : FontStyle.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),

                  SizedBox(height: size.mediumSpacing),

                  // Company and Contact
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.business,
                          label: 'Firma',
                          value: activity.firma ?? 'Belirtilmemiş',
                          size: size,
                          isEmpty: activity.firma == null,
                        ),
                      ),
                      SizedBox(width: size.mediumSpacing),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.person,
                          label: 'Kişi',
                          value: activity.kisi ?? 'Belirtilmemiş',
                          size: size,
                          isEmpty: activity.kisi == null,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.smallSpacing),

                  // Date and Representative
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.access_time,
                          label: 'Başlangıç',
                          value: activity.baslangic ?? 'Belirtilmemiş',
                          size: size,
                          isEmpty: activity.baslangic == null,
                        ),
                      ),
                      SizedBox(width: size.mediumSpacing),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.account_circle,
                          label: 'Temsilci',
                          value: activity.temsilci ?? 'Belirtilmemiş',
                          size: size,
                          isEmpty: activity.temsilci == null,
                        ),
                      ),
                    ],
                  ),

                  // Detail if available
                  if (activity.detay != null && activity.detay!.isNotEmpty) ...[
                    SizedBox(height: size.smallSpacing),
                    Container(
                      padding: EdgeInsets.all(size.smallSpacing),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: AppColors.info,
                          ),
                          SizedBox(width: size.smallSpacing),
                          Expanded(
                            child: Text(
                              activity.detay!,
                              style: TextStyle(
                                fontSize: size.smallText,
                                color: AppColors.info,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Footer
                  SizedBox(height: size.mediumSpacing),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOpen ? 'AÇIK' : 'KAPALI',
                          style: TextStyle(
                            fontSize: size.smallText * 0.8,
                            color: isOpen ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: ${activity.id}',
                          style: TextStyle(
                            fontSize: size.smallText * 0.8,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required AppSizes size,
    bool isEmpty = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
            ),
            SizedBox(width: size.tinySpacing),
            Text(
              label,
              style: TextStyle(
                fontSize: size.smallText * 0.9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: size.tinySpacing),
        Text(
          value,
          style: TextStyle(
            fontSize: size.smallText,
            color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: size.largeSpacing),
          Text(
            'Aktiviteler yükleniyor...',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            ElevatedButton(
              onPressed: () => _loadActivities(isRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppSizes size) {
    final isOpen = _currentFilter == ActivityFilter.open;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : (isOpen ? Icons.assignment_outlined : Icons.assignment_turned_in),
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              _searchQuery.isNotEmpty ? 'Aktivite bulunamadı' : '${isOpen ? 'Açık' : 'Kapalı'} aktivite yok',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              _searchQuery.isNotEmpty
                  ? '"$_searchQuery" aramasına uygun aktivite bulunamadı'
                  : 'Henüz ${isOpen ? 'açık' : 'kapalı'} aktivite bulunmuyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isEmpty && isOpen) ...[
              SizedBox(height: size.largeSpacing),
              ElevatedButton.icon(
                onPressed: _onAddActivity,
                icon: const Icon(Icons.add),
                label: const Text('Aktivite Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
