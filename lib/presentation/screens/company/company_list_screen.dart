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

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  Future<void> loadItems({bool isRefresh = false}) async {
    if (isRefresh) resetPagination();
    showLoadingState(isRefresh: isRefresh);

    try {
      final result = await _companyApiService.getCompanyList(
        page: currentPage,
        pageSize: pageSize,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (mounted) {
        setState(() {
          if (isRefresh || currentPage == 1) {
            _companies = result.data;
          } else {
            _companies.addAll(result.data);
          }

          totalCount = result.total;
          hasMoreData = _companies.length < totalCount;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setError(e.toString());
        if (isRefresh || currentPage == 1) {
          SnackbarHelper.showError(
            context: context,
            message: 'Firmalar yüklenirken hata oluştu: ${e.toString()}',
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
      final result = await _companyApiService.getCompanyList(
        page: currentPage,
        pageSize: pageSize,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _companies.addAll(result.data);
          hasMoreData = _companies.length < result.total;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentPage--;
          isLoadingMore = false;
        });
      }
    }
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
            hintText: 'Firma ara...',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
            hasValue: searchQuery.isNotEmpty,
          ),
          StatsBarWidget(
            icon: Icons.business,
            text: '${_companies.length}${totalCount > _companies.length ? '+' : ''} / $totalCount Firma',
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
