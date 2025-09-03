// lib/presentation/screens/company/company_list_screen_refactored.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/mixins/list_state_mixin.dart';
import '../../../core/widgets/common/loading_state_widget.dart';
import '../../../core/widgets/common/error_state_widget.dart';
import '../../../core/widgets/common/empty_state_widget.dart';
import '../../../core/widgets/common/search_bar_widget.dart';
import '../../../core/widgets/common/stats_bar_widget.dart';
import '../../../core/widgets/common/loading_more_widget.dart';
import '../../../data/models/company/company_list_model.dart';
import '../../../data/services/api/company_api_service.dart';
import '../../widgets/company/company_card_widget.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> with ListStateMixin {
  final CompanyApiService _companyApiService = CompanyApiService();

  List<CompanyListItem> _companies = [];
  List<CompanyListItem> _allCompanies = []; // TÜM FİRMALARI SAKLA
  int _apiTotalCount = 0; // API'den gelen toplam sayı

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  // FİLTRELEME İŞLEMİ
  void _applySearch() {
    List<CompanyListItem> filteredCompanies = _allCompanies;

    if (searchQuery.isNotEmpty) {
      filteredCompanies = _allCompanies.where((company) {
        final companyName = company.firma.toLowerCase();
        final searchLower = searchQuery.toLowerCase();
        return companyName.contains(searchLower);
      }).toList();

      debugPrint('[COMPANY_LIST] 🔍 Firma filter: "$searchQuery"');
      debugPrint('[COMPANY_LIST] 📊 Results: ${filteredCompanies.length}/${_allCompanies.length}');
      debugPrint('[COMPANY_LIST] 📊 Cache: ${_allCompanies.length} / API Total: $_apiTotalCount');
    }

    setState(() {
      _companies = filteredCompanies;

      if (searchQuery.isNotEmpty) {
        // Search'te gösterilen sonuç sayısı
        totalCount = filteredCompanies.length;
        // Eğer cache'deki veri API'nin toplam verisinden azsa, daha fazla yüklenebilir
        hasMoreData = _allCompanies.length < _apiTotalCount;
      } else {
        // Normal durumda
        totalCount = _apiTotalCount;
        hasMoreData = _allCompanies.length < _apiTotalCount;
      }
    });
  }

  // SEARCH DEĞİŞTİĞİNDE SADECE FİLTRELE, API ÇAĞIRMA
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
    if (isRefresh) {
      resetPagination();
      _allCompanies.clear();
    }

    showLoadingState(isRefresh: isRefresh);

    try {
      // ⬅️ ÇOK BÜYÜK pageSize KULLAN
      final result = await _companyApiService.getCompanyList(
        page: 1,
        pageSize: 999999, // ⬅️ ÇOK BÜYÜK SAYI = TÜM VERİLER
        searchQuery: null,
      );

      debugPrint('[COMPANY_API] 📥 BULK DATA LOADED: ${result.data.length} companies received, total: ${result.total}');

      if (mounted) {
        setState(() {
          _allCompanies = result.data;
          _apiTotalCount = result.total;
          hasMoreData = false;
          isLoading = false;
          errorMessage = null;
          currentPage = 1;
        });

        // Debug: Cache durumu
        debugPrint('📊 [COMPANY_CACHE] TOPLU YÜKLENDİ: ${_allCompanies.length}/$_apiTotalCount firma');

        _applySearch();
      }
    } catch (e) {
      if (mounted) {
        setError(e.toString());
        SnackbarHelper.showError(
          context: context,
          message: 'Firmalar yüklenirken hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  @override
  Future<void> loadMoreItems() async {
    // ⬅️ TÜM VERİ ZATEN YÜKLENDİ, PAGINATION YOK
    return;
  }

  void _onCompanyTap(CompanyListItem company) {
    Navigator.pushNamed(
      context,
      AppRoutes.addCompany,
      arguments: {'companyId': company.id},
    ).then((result) {
      if (result == true) {
        loadItems(isRefresh: true);
      }
    });
  }

  void _onAddCompany() {
    Navigator.pushNamed(context, AppRoutes.addCompany).then((result) {
      if (result == true) {
        loadItems(isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          SearchBarWidget(
            controller: searchController,
            hintText: 'Firma adına göre ara...',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
            hasValue: searchQuery.isNotEmpty,
          ),
          StatsBarWidget(
            icon: Icons.business,
            text: searchQuery.isNotEmpty
                ? '${_companies.length} sonuç (${_allCompanies.length}/$_apiTotalCount yüklendi)'
                : '${_companies.length}${totalCount > _companies.length ? '+' : ''} / $totalCount Firma',
            iconColor: AppColors.primary,
            isLoading: isLoading || isLoadingMore,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && _companies.isEmpty) {
      return const LoadingStateWidget(
        title: 'Firmalar yükleniyor...',
        subtitle: 'Lütfen bekleyin',
      );
    }

    if (errorMessage != null && _companies.isEmpty) {
      return ErrorStateWidget(
        title: 'Bir hata oluştu',
        message: errorMessage!,
        onRetry: () => loadItems(isRefresh: true),
      );
    }

    if (_companies.isEmpty) {
      return EmptyStateWidget(
        icon: searchQuery.isNotEmpty ? Icons.search_off : Icons.business_outlined,
        title: searchQuery.isNotEmpty ? 'Firma bulunamadı' : 'Henüz firma yok',
        message: searchQuery.isNotEmpty ? '"$searchQuery" aramasına uygun firma bulunamadı' : 'İlk firmanızı eklemek için + butonunu kullanın',
        actionButtonText: searchQuery.isEmpty ? 'Firma Ekle' : null,
        onActionPressed: searchQuery.isEmpty ? _onAddCompany : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => loadItems(isRefresh: true),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _companies.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _companies.length) {
            return isLoadingMore ? const LoadingMoreWidget() : const SizedBox.shrink();
          }

          final company = _companies[index];
          return CompanyCardWidget(
            company: company,
            onTap: () => _onCompanyTap(company),
          );
        },
      ),
    );
  }
}
