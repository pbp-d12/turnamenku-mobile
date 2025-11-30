import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_tournament.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_thread.dart';
import 'package:turnamenku_mobile/features/forums/screens/tampilan_postingan.dart';

class DaftarThreadPage extends StatefulWidget {
  final ForumTournament tournament;

  const DaftarThreadPage({super.key, required this.tournament});

  @override
  State<DaftarThreadPage> createState() => _DaftarThreadPageState();
}

class _DaftarThreadPageState extends State<DaftarThreadPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _authorFilter = "";
  String _sortBy = "-created_at";

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  List<ForumThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _fetchThreads(isNewSearch: true);
    });
    _fetchThreads(isNewSearch: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchThreads({int page = 1, bool isNewSearch = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isNewSearch) {
        _currentPage = 1;
        _threads = [];
      }
    });

    final request = context.read<CookieRequest>();

    try {
      final params = {
        'page': page.toString(),
        'q': _searchQuery,
        'author': _authorFilter,
        'sort': _sortBy,
      };
      
      params.removeWhere((key, value) => value.isEmpty);
      
      final queryString = Uri(queryParameters: params).query;
      final response = await request.get("${Endpoints.forumThreads(widget.tournament.id)}?$queryString");
      
      final threads = (response['threads'] as List)
          .map((d) => ForumThread.fromJson(d))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      
      setState(() {
        _threads = threads;
        _currentPage = pagination['current_page'] ?? page;
        _totalPages = pagination['total_pages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _threads = [];
      });
      if (mounted) {
        CustomSnackbar.show(
          context,
          "Gagal memuat data: $e",
          SnackbarStatus.error,
        );
      }
    }
  }

  void _showFilterDialog() {
    String tempAuthor = _authorFilter;
    String tempSort = _sortBy;

    final authorController = TextEditingController(text: tempAuthor);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Filter Thread",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue400,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Author Filter
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: "Filter Penulis",
                      hintText: "Username...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        tempAuthor = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sort Dropdown
                  DropdownButtonFormField<String>(
                    value: tempSort,
                    decoration: const InputDecoration(
                      labelText: "Urutkan Berdasarkan",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "-created_at", child: Text("Terbaru")),
                      DropdownMenuItem(value: "created_at", child: Text("Terlama")),
                      DropdownMenuItem(value: "-popularity", child: Text("Paling Populer (Balasan)")),
                      DropdownMenuItem(value: "popularity", child: Text("Kurang Populer (Balasan)")),
                      DropdownMenuItem(value: "title", child: Text("Judul (A-Z)")),
                      DropdownMenuItem(value: "-title", child: Text("Judul (Z-A)")),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempSort = value ?? "-created_at";
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      authorController.clear();
                      tempAuthor = "";
                      tempSort = "-created_at";
                    });
                    setState(() {
                      _authorFilter = "";
                      _sortBy = "-created_at";
                    });
                    Navigator.of(dialogContext).pop();
                    
                    Future.delayed(Duration.zero, () {
                      authorController.dispose();
                    });
                    
                    _fetchThreads(isNewSearch: true);
                  },
                  child: const Text("Reset"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _authorFilter = tempAuthor;
                      _sortBy = tempSort;
                    });
                    Navigator.of(dialogContext).pop();
                    
                    Future.delayed(Duration.zero, () {
                      authorController.dispose();
                    });
                    
                    _fetchThreads(isNewSearch: true);
                  },
                  child: const Text("Terapkan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    pageButtons.add(
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _currentPage > 1 ? () => _fetchThreads(page: _currentPage - 1) : null,
        color: _currentPage > 1 ? AppColors.blue400 : Colors.grey,
      ),
    );

    Set<int> pagesToShow = {1, _totalPages, _currentPage};
    for (int i = -2; i <= 2; i++) {
      final page = _currentPage + i;
      if (page > 1 && page < _totalPages) {
        pagesToShow.add(page);
      }
    }

    final sortedPages = pagesToShow.toList()..sort();
    int lastPage = 0;

    for (final page in sortedPages) {
      if (lastPage != 0 && page > lastPage + 1) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.textSecondary)),
        ));
      }

      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            onPressed: page == _currentPage ? null : () => _fetchThreads(page: page),
            style: ElevatedButton.styleFrom(
              backgroundColor: page == _currentPage ? AppColors.blue400 : Colors.white,
              foregroundColor: page == _currentPage ? Colors.white : AppColors.blue400,
              minimumSize: const Size(40, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(page.toString()),
          ),
        ),
      );

      lastPage = page;
    }

    pageButtons.add(
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: _currentPage < _totalPages ? () => _fetchThreads(page: _currentPage + 1) : null,
        color: _currentPage < _totalPages ? AppColors.blue400 : Colors.grey,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageButtons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue50, 
      appBar: AppBar(
        title: Text(
          widget.tournament.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Tournament Info Section
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tentang Turnamen",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    color: AppColors.blue400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tournament.description,
                  style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      "Organizer: ${widget.tournament.organizerUsername}",
                      style: const TextStyle(
                        fontStyle: FontStyle.italic, 
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.blue50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Cari judul thread...",
                    prefixIcon: Icon(Icons.search, color: AppColors.blue400),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.blue400),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showFilterDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list, size: 20, color: AppColors.blue400),
                            SizedBox(width: 8),
                            Text(
                              "Filter Thread",
                              style: TextStyle(
                                color: AppColors.blue400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Thread List
          Expanded(
            child: _isLoading && _threads.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.blue400))
                : _threads.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.forum_outlined, size: 64, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _authorFilter.isNotEmpty
                                    ? "Tidak ada thread yang sesuai dengan kriteria filter/pencarian."
                                    : "Belum ada diskusi.\nJadilah yang pertama membuat thread!",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              if (_searchQuery.isNotEmpty || _authorFilter.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = "";
                                      _authorFilter = "";
                                      _sortBy = "-created_at";
                                      _searchController.clear();
                                    });
                                    _fetchThreads(isNewSearch: true);
                                  },
                                  child: const Text("Reset Filter"),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _threads.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final thread = _threads[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TampilanPostinganPage(thread: thread),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    thread.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.blue50,
                                        child: Text(
                                          thread.authorUsername.isNotEmpty ? thread.authorUsername[0].toUpperCase() : "?",
                                          style: const TextStyle(fontSize: 10, color: AppColors.blue400),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        thread.authorUsername,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.comment_outlined, size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${thread.replyCount}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        thread.createdAt,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Pagination
          _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CustomSnackbar.show(
            context,
            "Fitur buat Thread baru akan segera hadir!",
            SnackbarStatus.info,
          );
        },
        backgroundColor: AppColors.blue400,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}