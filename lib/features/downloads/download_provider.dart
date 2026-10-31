import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/download_item.dart';
import '../../models/download_stat.dart';
import '../../repositories/download_repository.dart';
import '../../services/notifications/notification_service.dart';

enum DownloadFilterStatus {
  all,
  active,
  queued,
  completed,
  failed,
  scheduled,
}

enum DownloadSortBy {
  dateDesc,
  dateAsc,
  sizeDesc,
  sizeAsc,
  nameAsc,
  speedDesc,
}

class DownloadProvider extends ChangeNotifier {
  final DownloadRepository _repository;
  final NotificationService _notificationService;

  List<DownloadItem> _allDownloads = [];
  DownloadStat _currentStat = const DownloadStat();
  DownloadFilterStatus _filterStatus = DownloadFilterStatus.all;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DownloadSortBy _sortBy = DownloadSortBy.dateDesc;
  bool _isLoading = true;

  StreamSubscription? _downloadsSub;
  StreamSubscription? _statSub;

  DownloadProvider({
    required DownloadRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService {
    _init();
  }

  DownloadRepository get repository => _repository;
  List<DownloadItem> get allDownloads => _allDownloads;
  DownloadStat get currentStat => _currentStat;
  DownloadFilterStatus get filterStatus => _filterStatus;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  DownloadSortBy get sortBy => _sortBy;
  bool get isLoading => _isLoading;

  List<DownloadItem> get filteredDownloads {
    var list = _allDownloads.where((item) {
      // 1. Status Filter
      if (_filterStatus == DownloadFilterStatus.active) {
        if (item.status != DownloadStatus.active) return false;
      } else if (_filterStatus == DownloadFilterStatus.queued) {
        if (item.status != DownloadStatus.waiting && item.status != DownloadStatus.paused) return false;
      } else if (_filterStatus == DownloadFilterStatus.completed) {
        if (item.status != DownloadStatus.completed) return false;
      } else if (_filterStatus == DownloadFilterStatus.failed) {
        if (item.status != DownloadStatus.error) return false;
      } else if (_filterStatus == DownloadFilterStatus.scheduled) {
        if (!item.isScheduled) return false;
      }

      // 2. Category Filter
      if (_selectedCategory != 'All' && item.categoryId != _selectedCategory) {
        return false;
      }

      // 3. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = item.fileName.toLowerCase().contains(query);
        final matchUrl = item.url.toLowerCase().contains(query);
        if (!matchName && !matchUrl) return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case DownloadSortBy.dateDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DownloadSortBy.dateAsc:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DownloadSortBy.sizeDesc:
        list.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case DownloadSortBy.sizeAsc:
        list.sort((a, b) => a.fileSize.compareTo(b.fileSize));
        break;
      case DownloadSortBy.nameAsc:
        list.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
        break;
      case DownloadSortBy.speedDesc:
        list.sort((a, b) => b.downloadSpeed.compareTo(a.downloadSpeed));
        break;
    }

    return list;
  }

  List<DownloadItem> get activeDownloads =>
      _allDownloads.where((item) => item.status == DownloadStatus.active).toList();

  List<DownloadItem> get queuedDownloads =>
      _allDownloads.where((item) => item.status == DownloadStatus.waiting).toList();

  List<DownloadItem> get completedDownloads =>
      _allDownloads.where((item) => item.status == DownloadStatus.completed).toList();

  List<DownloadItem> get failedDownloads =>
      _allDownloads.where((item) => item.status == DownloadStatus.error).toList();

  List<DownloadItem> get scheduledDownloads =>
      _allDownloads.where((item) => item.isScheduled && item.status != DownloadStatus.completed).toList();

  void _init() {
    _downloadsSub = _repository.downloadsStream.listen((items) {
      _allDownloads = items;
      _isLoading = false;
      notifyListeners();
    });

    _statSub = _repository.statStream.listen((stat) {
      _currentStat = stat;
      notifyListeners();
    });
  }

  void setFilterStatus(DownloadFilterStatus status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(DownloadSortBy sort) {
    _sortBy = sort;
    notifyListeners();
  }

  Future<void> pause(String gid) async {
    await _repository.pauseDownload(gid);
  }

  Future<void> resume(String gid) async {
    await _repository.resumeDownload(gid);
  }

  Future<void> cancel(String gid, {bool deleteFile = false}) async {
    await _repository.cancelDownload(gid, deleteFile: deleteFile);
  }

  Future<void> restart(int downloadId) async {
    await _repository.restartDownload(downloadId);
  }

  Future<void> pauseAll() async {
    await _repository.pauseAll();
  }

  Future<void> resumeAll() async {
    await _repository.resumeAll();
  }

  Future<void> clearHistory() async {
    await _repository.dbService.clearHistory();
    _allDownloads = await _repository.dbService.getAllDownloads();
    notifyListeners();
  }

  Future<void> deleteDownload(int id) async {
    await _repository.dbService.deleteDownload(id);
    _allDownloads = await _repository.dbService.getAllDownloads();
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadsSub?.cancel();
    _statSub?.cancel();
    super.dispose();
  }
}

