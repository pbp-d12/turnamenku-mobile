import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_tournament.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_thread.dart';
import 'package:turnamenku_mobile/features/forums/screens/tampilan_postingan.dart';
import 'package:turnamenku_mobile/features/forums/screens/create_thread_page.dart';

class DaftarThreadPage extends StatefulWidget {
  final ForumTournament tournament;

  const DaftarThreadPage({super.key, required this.tournament});

  @override
  State<DaftarThreadPage> createState() => _DaftarThreadPageState();
}

class _DaftarThreadPageState extends State<DaftarThreadPage> {
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  String _searchQuery = "";
  String _authorFilter = "";
  String _sortBy = "-created_at"; 

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  List<ForumThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _debouncer.run(() {
        setState(() {
          _searchQuery = _searchController.text;
          if (_searchQuery.isNotEmpty) {
             _currentPage = 1;
          }
        });
        _fetchThreads(isNewSearch: true);
      });
    });
    _fetchThreads(isNewSearch: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchThreads({int page = 1, bool isNewSearch = false}) async {
    if (!mounted) return;
    
    setState(() {
      if(isNewSearch) _isLoading = true; 
      if (isNewSearch) {
        _currentPage = 1;
        _threads = [];
      }
    });

    final request = context.read<CookieRequest>();

    try {
      final params = {
        'page': isNewSearch ? '1' : page.toString(),
        'q': _searchQuery,
        'author': _authorFilter,
        'sort': _sortBy,
      };
      
      params.removeWhere((key, value) => value.isEmpty);
      
      final queryString = Uri(queryParameters: params).query;
      final fullUrl = "${Endpoints.forumThreads(widget.tournament.id)}?$queryString";
      
      final response = await request.get(fullUrl);

      if (!mounted) return;
      
      if (response != null && response['threads'] != null) {
        final rawList = response['threads'] as List;
        
        final threads = rawList.map((d) {
          if (d is Map<String, dynamic>) {
            
            String? finalImage;
            String? finalBody;

            var initialPost = d['initial_post']; 
            
            initialPost ??= d['first_post'];

            if (initialPost != null && initialPost is Map) {
                finalImage = initialPost['image'] ?? initialPost['image_url']; 
                finalBody = initialPost['body'];
            } else {
                finalImage = d['image_url'] ?? d['image'];
                finalBody = d['body'];
            }

            if (finalImage != null && finalImage.isNotEmpty) {
               if (finalImage.startsWith('/')) {
                 finalImage = "http://10.0.2.2:8000$finalImage"; 
               }
            }

            d['image_url'] = finalImage;
            d['body'] = finalBody;

            d['id'] ??= 0;
            d['reply_count'] = d['reply_count_agg'] ?? d['reply_count'] ?? 0;
            d['title'] ??= "Tanpa Judul";
            d['author_username'] ??= "Unknown";
            d['created_at'] ??= "";
            d['can_delete'] ??= false;
          }
          return ForumThread.fromJson(d);
        }).toList();
      
        final pagination = response['pagination'] ?? {};
        
        if (mounted) {
          setState(() {
            _threads = threads;
            _currentPage = pagination['current_page'] ?? page;
            _totalPages = pagination['total_pages'] ?? 1;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("THREAD ERROR: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.show(context, "Gagal memuat data: $e", SnackbarStatus.error);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchThreads(isNewSearch: true);
  }

  Future<void> _deleteThread(int threadId) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.deleteThread(threadId); 

    CustomSnackbar.show(context, "Menghapus thread...", SnackbarStatus.info);

    try {
      final response = await request.post(url, {});

      if (!mounted) return;

      if (response['success'] == true) {
        CustomSnackbar.show(context, "Thread berhasil dihapus!", SnackbarStatus.success);
        _fetchThreads(isNewSearch: true); 
      } else {
        CustomSnackbar.show(context, "Gagal menghapus thread: ${response['error'] ?? response['message']}", SnackbarStatus.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
      }
    }
  }

  void _confirmDeleteThread(ForumThread thread) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus Thread"),
        content: Text("Anda yakin ingin menghapus thread: \"${thread.title}\"?\nSemua balasan akan ikut terhapus."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _deleteThread(thread.id); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Hapus Permanen"),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    String tempAuthor = _authorFilter;
    final authorController = TextEditingController(text: tempAuthor);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Filter Thread", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue400)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Filter Penulis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.blue400)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      hintText: "Username penulis...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) => tempAuthor = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    setState(() { 
                      _authorFilter = tempAuthor; 
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
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.tournament.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.blue400,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [], 
      ),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.blue50.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tentang Turnamen", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey[800], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(widget.tournament.description, style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                      
                      if (widget.tournament.banner != null && widget.tournament.banner!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.tournament.banner!,
                            width: double.infinity,
                            height: 180, 
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.blue400,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Cari topik diskusi...",
                        prefixIcon: const Icon(Icons.search, color: AppColors.blue400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue400)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.filter_list, size: 20, color: AppColors.blue400),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          "Filter",
                                          style: TextStyle(color: AppColors.blue400, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_authorFilter.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: AppColors.blue400, shape: BoxShape.circle),
                                          child: const Text("1", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.blue400),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.blue400),
                                  style: const TextStyle(color: AppColors.blue400, fontWeight: FontWeight.w500, fontSize: 13),
                                  items: const [
                                    DropdownMenuItem(value: "-created_at", child: Text("Terbaru")),
                                    DropdownMenuItem(value: "created_at", child: Text("Terlama")),
                                    DropdownMenuItem(value: "-popularity", child: Text("Populer")),
                                    DropdownMenuItem(value: "title", child: Text("Judul A-Z")),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _sortBy = value ?? "-created_at";
                                    });
                                    _fetchThreads(isNewSearch: true);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_authorFilter.isNotEmpty)
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildChip("Penulis: $_authorFilter", () {
                            setState(() {
                              _authorFilter = "";
                              _fetchThreads(isNewSearch: true);
                            });
                          }),
                          
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: const Text('Reset', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                 setState(() {
                                   _authorFilter = "";
                                   _sortBy = "-created_at";
                                   _searchController.clear();
                                   _searchQuery = "";
                                   _fetchThreads(isNewSearch: true);
                                 });
                              },
                              backgroundColor: Colors.red.shade50,
                              labelStyle: TextStyle(color: Colors.red.shade400),
                              side: BorderSide(color: Colors.red.shade400),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: _isLoading && _threads.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.blue400))
                        : _threads.isEmpty
                            ? const Center(child: Text("Belum ada thread."))
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _threads.length,
                                padding: const EdgeInsets.only(bottom: 120),
                                separatorBuilder: (context, index) => const SizedBox(height: 0),
                                itemBuilder: (_, index) {
                                  final thread = _threads[index];
                                  return _buildThreadCard(thread);
                                },
                              ),
                  ),
                  _buildPagination(),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 90, 
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateThreadPage(tournamentId: widget.tournament.id),
                  ),
                );

                if (!mounted) return;

                if (result == true) {
                  _fetchThreads(isNewSearch: true);
                }
              },
              backgroundColor: AppColors.blue400,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadCard(ForumThread thread) {
    bool canDeleteThread = thread.canDelete;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TampilanUnggahanPage(thread: thread)),
          );

          if (!mounted) return;
          _fetchThreads(isNewSearch: false);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      thread.authorUsername.isNotEmpty
                          ? thread.authorUsername[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.authorUsername,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          thread.createdAt,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (canDeleteThread)
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: _buildThreadMenu(thread),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),

              Text(
                thread.title,
                style: const TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w700),
              ),

              if (thread.imageUrl != null && thread.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.grey[100],
                    constraints: const BoxConstraints(maxHeight: 250),
                    width: double.infinity,
                    child: Image.network(
                      thread.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink(); 
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "${thread.replyCount} Balasan",
                          style: TextStyle(
                              color: Colors.grey[700], 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildThreadMenu(ForumThread thread) {
    return Builder(
      builder: (context) {
        return PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
          onSelected: (value) {
            if (value == 'delete') {
              Future.delayed(Duration.zero, () {
                _confirmDeleteThread(thread);
              });
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_forever, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Hapus Thread', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

Widget _buildChip(String label, VoidCallback onDelete) {
  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.blue400),
      ),
    ),
  );
}