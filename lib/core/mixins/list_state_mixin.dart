// lib/core/mixins/list_state_mixin.dart
import 'package:flutter/material.dart';

mixin ListStateMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  String? errorMessage;
  String searchQuery = '';

  // Pagination
  int currentPage = 1;
  int get pageSize => 20;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void onScroll() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      loadMoreItems();
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery == query && mounted) {
        loadItems(isRefresh: true);
      }
    });
  }

  void onClearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  // Abstract methods to be implemented
  Future<void> loadItems({bool isRefresh = false});
  Future<void> loadMoreItems();

  // Utility methods
  void resetPagination() {
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      errorMessage = null;
    });
  }

  void showLoadingState({bool isRefresh = false}) {
    setState(() {
      isLoading = isRefresh || currentPage == 1;
    });
  }

  void hideLoadingState() {
    setState(() {
      isLoading = false;
    });
  }

  void showLoadingMoreState() {
    setState(() {
      isLoadingMore = true;
      currentPage++;
    });
  }

  void hideLoadingMoreState() {
    setState(() {
      isLoadingMore = false;
    });
  }

  void setError(String error) {
    setState(() {
      isLoading = false;
      errorMessage = error;
    });
  }

  void clearError() {
    setState(() {
      errorMessage = null;
    });
  }
}
