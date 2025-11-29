import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/features/tournaments/models/tournament.dart';
import 'package:turnamenku_mobile/features/tournaments/screens/tournament_form_page.dart';
import 'package:turnamenku_mobile/features/tournaments/widgets/tournament_card.dart';
import 'dart:async'; // Untuk Timer debounce

class TournamentListPage extends StatefulWidget {
  final Map<String, dynamic>? userData; 

  // 2. Update constructor untuk menerima userData
  const TournamentListPage({super.key, this.userData}); 

  @override
  State<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  // --- STATE VARIABLES ---
  final List<Tournament> _tournaments = [];
  
  // Pagination
  int _page = 1;
  bool _hasNextPage = true;
  bool _isFirstLoadRunning = false;
  bool _isLoadMoreRunning = false;
  
  // Search & Filter
  String _searchQuery = "";
  String? _statusFilter; // null (Semua), 'upcoming', 'ongoing', 'past'
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Delay pencarian agar tidak spam request

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMore);
    _firstLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMore);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Helper untuk membuat URL dengan parameter
  String _buildUrl(int page) {
    String url = "${Endpoints.tournaments}?page=$page";
    if (_searchQuery.isNotEmpty) {
      url += "&search=$_searchQuery";
    }
    if (_statusFilter != null) {
      url += "&status=$_statusFilter";
    }
    return url;
  }

  // 1. Load Awal (Reset list)
  void _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
      _page = 1;
      _hasNextPage = true;
      _tournaments.clear();
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(_buildUrl(_page));
      
      final List result = response['tournaments'];
      final bool hasNext = response['has_next_page'];

      if (mounted) {
        setState(() {
          _tournaments.addAll(result.map((data) => Tournament.fromJson(data)).toList());
          _hasNextPage = hasNext;
          _isFirstLoadRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFirstLoadRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat: $e")));
      }
    }
  }

  // 2. Load More (Pagination)
  void _loadMore() async {
    if (_hasNextPage && 
        !_isFirstLoadRunning && 
        !_isLoadMoreRunning && 
        _scrollController.position.extentAfter < 300) {
      
      setState(() => _isLoadMoreRunning = true);

      try {
        final request = context.read<CookieRequest>();
        _page += 1;
        final response = await request.get(_buildUrl(_page));

        final List result = response['tournaments'];
        final bool hasNext = response['has_next_page'];

        if (mounted) {
          setState(() {
            _tournaments.addAll(result.map((data) => Tournament.fromJson(data)).toList());
            _hasNextPage = hasNext;
            _isLoadMoreRunning = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadMoreRunning = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal load more: $e")));
        }
      }
    }
  }

  // Logic Pencarian dengan Debounce (Jeda sebentar setelah ngetik baru search)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _firstLoad();
    });
  }

  // Logic Filter
  void _onFilterChanged(String? newValue) {
    setState(() {
      _statusFilter = newValue;
    });
    _firstLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: LeftDrawer(userData: widget.userData),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TournamentFormPage()),
          );
          if (shouldRefresh == true) _firstLoad();
        },
        tooltip: 'Create Tournament',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // --- BAGIAN SEARCH & FILTER ---
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                // 1. Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari turnamen...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                
                // 2. Filter Chips (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Semua", null),
                      const SizedBox(width: 8),
                      _buildFilterChip("Akan Datang", "upcoming"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Sedang Berjalan", "ongoing"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Selesai", "past"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- DAFTAR TURNAMEN ---
          Expanded(
            child: _isFirstLoadRunning
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _firstLoad(),
                    child: _tournaments.isEmpty
                        ? ListView( // Pakai ListView biasa agar Pull-to-Refresh tetap jalan meski kosong
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada turnamen ditemukan.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _tournaments.length + (_isLoadMoreRunning ? 1 : 0),
                            itemBuilder: (_, index) {
                              if (index == _tournaments.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return TournamentCard(tournament: _tournaments[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final bool isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) _onFilterChanged(value);
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}