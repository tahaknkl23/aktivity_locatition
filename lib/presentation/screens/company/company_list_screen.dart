import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/company/company_list_model.dart';
import '../../../data/services/api/company_api_service.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final CompanyApiService _companyApiService = CompanyApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<CompanyListItem> _companies = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  String _searchQuery = '';

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreCompanies();
    }
  }

  Future<void> _loadCompanies({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _companies.clear();
        _hasMoreData = true;
        _errorMessage = null;
      });
    }

    setState(() {
      _isLoading = isRefresh || _currentPage == 1;
    });

    try {
      debugPrint('[COMPANY_LIST] Loading companies - Page: $_currentPage, Search: $_searchQuery');

      final result = await _companyApiService.getCompanyList(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          if (isRefresh || _currentPage == 1) {
            _companies = result.data;
          } else {
            _companies.addAll(result.data);
          }

          _totalCount = result.total;
          _hasMoreData = _companies.length < _totalCount;
          _isLoading = false;
          _errorMessage = null;
        });

        debugPrint('[COMPANY_LIST] Loaded ${result.data.length} companies. Total: $_totalCount');
      }
    } catch (e) {
      debugPrint('[COMPANY_LIST] Load error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });

        if (isRefresh || _currentPage == 1) {
          SnackbarHelper.showError(
            context: context,
            message: 'Firmalar yüklenirken hata oluştu: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _loadMoreCompanies() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final result = await _companyApiService.getCompanyList(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _companies.addAll(result.data);
          _hasMoreData = _companies.length < result.total;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[COMPANY_LIST] Load more error: $e');

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
        _loadCompanies(isRefresh: true);
      }
    });
  }

  void _onCompanyTap(CompanyListItem company) {
    Navigator.pushNamed(
      context,
      AppRoutes.addCompany,
      arguments: {'companyId': company.id},
    ).then((result) {
      if (result == true) {
        _loadCompanies(isRefresh: true);
      }
    });
  }

  void _onAddCompany() {
    Navigator.pushNamed(context, AppRoutes.addCompany).then((result) {
      if (result == true) {
        _loadCompanies(isRefresh: true);
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
          'Firmalar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _onAddCompany,
            icon: const Icon(Icons.add),
            tooltip: 'Firma Ekle',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(size),
          _buildStatsBar(size),
          Expanded(child: _buildBody(size)),
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
          hintText: 'Firma ara...',
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
            Icons.business,
            size: size.smallIcon,
            color: AppColors.primary,
          ),
          SizedBox(width: size.smallSpacing),
          Text(
            '${_companies.length}${_totalCount > _companies.length ? '+' : ''} / $_totalCount Firma',
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
    if (_isLoading && _companies.isEmpty) {
      return _buildLoadingState(size);
    }

    if (_errorMessage != null && _companies.isEmpty) {
      return _buildErrorState(size);
    }

    if (_companies.isEmpty) {
      return _buildEmptyState(size);
    }

    return RefreshIndicator(
      onRefresh: () => _loadCompanies(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(size.cardPadding),
        itemCount: _companies.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _companies.length) {
            return _buildLoadingMoreIndicator(size);
          }

          final company = _companies[index];
          return _buildCompanyCard(company, size);
        },
      ),
    );
  }

  Widget _buildCompanyCard(CompanyListItem company, AppSizes size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        elevation: 2,
        child: InkWell(
          onTap: () => _onCompanyTap(company),
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: size.smallSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.firma,
                            style: TextStyle(
                              fontSize: size.textSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (company.sektor != '-') ...[
                            SizedBox(height: size.tinySpacing),
                            Text(
                              company.sektor,
                              style: TextStyle(
                                fontSize: size.smallText,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

                // Details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.phone,
                        label: 'Telefon',
                        value: company.telefon,
                        size: size,
                      ),
                    ),
                    SizedBox(width: size.mediumSpacing),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.email,
                        label: 'E-posta',
                        value: company.mail,
                        size: size,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.smallSpacing),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.language,
                        label: 'Web',
                        value: company.webAdres,
                        size: size,
                      ),
                    ),
                    SizedBox(width: size.mediumSpacing),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.person,
                        label: 'Temsilci',
                        value: company.temsilci,
                        size: size,
                      ),
                    ),
                  ],
                ),

                // Footer
                SizedBox(height: size.mediumSpacing),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(width: size.tinySpacing),
                    Text(
                      _formatDate(company.kayitTarihi),
                      style: TextStyle(
                        fontSize: size.smallText * 0.9,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${company.id}',
                        style: TextStyle(
                          fontSize: size.smallText * 0.8,
                          color: AppColors.success,
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
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required AppSizes size,
  }) {
    final displayValue = value == '-' ? 'Belirtilmemiş' : value;
    final isEmptyValue = value == '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isEmptyValue ? AppColors.textTertiary : AppColors.textSecondary,
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
          displayValue,
          style: TextStyle(
            fontSize: size.smallText,
            color: isEmptyValue ? AppColors.textTertiary : AppColors.textPrimary,
            fontStyle: isEmptyValue ? FontStyle.italic : FontStyle.normal,
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
            'Firmalar yükleniyor...',
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
              onPressed: () => _loadCompanies(isRefresh: true),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.business_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              _searchQuery.isNotEmpty ? 'Firma bulunamadı' : 'Henüz firma yok',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              _searchQuery.isNotEmpty ? '"$_searchQuery" aramasına uygun firma bulunamadı' : 'İlk firmanızı eklemek için + butonunu kullanın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: size.largeSpacing),
              ElevatedButton.icon(
                onPressed: _onAddCompany,
                icon: const Icon(Icons.add),
                label: const Text('Firma Ekle'),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
