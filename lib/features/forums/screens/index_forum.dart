import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_tournament.dart';
import 'package:turnamenku_mobile/features/forums/screens/daftar_thread.dart';

class ForumHomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ForumHomePage({super.key, this.userData});

  @override
  State<ForumHomePage> createState() => _ForumHomePageState();
}

class _ForumHomePageState extends State<ForumHomePage> {
  final TextEditingController _searchController = TextEditingController();
  
  final _debouncer = Debouncer(milliseconds: 500);

  String _searchQuery = "";
  String _sortDirection = "desc";
  String _organizerFilter = "";
  DateTime? _startDateAfter;
  DateTime? _endDateBefore;
  String _participantsFilter = "";
  String? _primarySortField;
  
  int _activeFilterCount = 0;
  String? _dateError;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  List<ForumTournament> _tournaments = [];

@override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _debouncer.run(() {
        setState(() {
          _searchQuery = _searchController.text;
          
          if (_searchQuery.isNotEmpty) {
             _organizerFilter = "";
             _startDateAfter = null;
             _endDateBefore = null;
             _participantsFilter = "";
             _activeFilterCount = 0;
          }
        });
        
        _fetchTournaments(isNewSearch: true);
      });
    });
    _fetchTournaments(isNewSearch: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilterCount() {
    int count = 0;
    if (_organizerFilter.isNotEmpty) count++;
    if (_startDateAfter != null || _endDateBefore != null) count++;
    if (_participantsFilter.isNotEmpty) count++;
    
    setState(() {
      _activeFilterCount = count;
    });
  }

  bool _validateDates() {
    if (_startDateAfter != null && _endDateBefore != null) {
      if (_startDateAfter!.isAfter(_endDateBefore!)) {
        setState(() {
          _dateError = "Tanggal mulai harus sebelum tanggal selesai";
        });
        return false;
      }
    }
    setState(() {
      _dateError = null;
    });
    return true;
  }

  Future<void> _fetchTournaments({int page = 1, bool isNewSearch = false}) async {
    setState(() {
      if (isNewSearch) _isLoading = true;
      if (isNewSearch) {
        _currentPage = 1;
        _tournaments = []; 
      }
    });

    final request = context.read<CookieRequest>();

    try {
      final sortPrefix = _sortDirection == 'desc' ? '-' : '';
      String sortField = _primarySortField ?? 'name';
      final sortParam = '$sortPrefix$sortField';

      final params = {
        'page': isNewSearch ? '1' : page.toString(), 
        'sort': sortParam,
        'q': _searchQuery,
        'organizer': _organizerFilter,
        'start_date_after': _startDateAfter?.toIso8601String().split('T')[0] ?? "",
        'end_date_before': _endDateBefore?.toIso8601String().split('T')[0] ?? "",
        'participants': _participantsFilter,
      };
      
      params.removeWhere((key, value) => value.isEmpty);
      final queryString = Uri(queryParameters: params).query;
      final fullUrl = "${Endpoints.forumSearch}?$queryString";

      final response = await request.get(fullUrl);
      
      if (!mounted) return;

      if (response != null && response['tournaments'] != null) {
        final rawList = response['tournaments'] as List;
        
        final tournaments = rawList.map((d) {
          if (d is Map<String, dynamic>) {
            d['thread_count'] ??= 0;
            d['post_count'] ??= 0;
            d['participant_count'] ??= 0;
            d['name'] ??= "Unnamed Tournament";
            d['description'] ??= "Tidak ada deskripsi";
            d['organizer_username'] ??= "Unknown";
            d['start_date'] ??= ""; 
            d['end_date'] ??= "";
            d['url'] ??= "";
          }
          return ForumTournament.fromJson(d);
        }).toList();
        
        final pagination = response['pagination'] ?? {};
        
        setState(() {
          _tournaments = tournaments;
          _currentPage = pagination['current_page'] ?? page;
          _totalPages = pagination['total_pages'] ?? 1;
          _isLoading = false;
        });
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.show(context, "Gagal memuat data: $e", SnackbarStatus.error);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchTournaments(isNewSearch: true);
  }

  void _showFilterDialog() {
    String tempOrganizer = _organizerFilter;
    DateTime? tempStartDate = _startDateAfter;
    DateTime? tempEndDate = _endDateBefore;
    String tempParticipants = _participantsFilter;
    String? tempPrimarySort = _primarySortField;
    String? tempDateError = _dateError;

    final organizerController = TextEditingController(text: tempOrganizer);
    final participantsController = TextEditingController(text: tempParticipants);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool hasActiveFilters = tempOrganizer.isNotEmpty || 
                                    tempStartDate != null || 
                                    tempEndDate != null || 
                                    tempParticipants.isNotEmpty || 
                                    tempPrimarySort != null;

            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Filter & Urutkan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue400,
                      ),
                    ),
                  ),
                  if (hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          organizerController.clear();
                          participantsController.clear();
                          tempOrganizer = "";
                          tempStartDate = null;
                          tempEndDate = null;
                          tempParticipants = "";
                          tempPrimarySort = null;
                          tempDateError = null;
                        });
                      },
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Urutkan Berdasarkan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue400)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: tempPrimarySort,
                          decoration: const InputDecoration(
                            hintText: "Default (Nama)",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text("Nama Turnamen (Default)")),
                            DropdownMenuItem(value: "organizer", child: Text("Penyelenggara")),
                            DropdownMenuItem(value: "start_date", child: Text("Tanggal Mulai")),
                            DropdownMenuItem(value: "participants", child: Text("Jumlah Pemain")),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              tempPrimarySort = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Filter Penyelenggara", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue400)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: organizerController,
                          decoration: const InputDecoration(
                            hintText: "Username penyelenggara...",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            tempOrganizer = value; 
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
          
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Filter Tanggal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue400)),
                        const SizedBox(height: 8),
                        
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                tempStartDate = picked;
                                if (tempEndDate != null && picked.isAfter(tempEndDate!)) {
                                  tempDateError = "Tanggal mulai harus sebelum tanggal selesai";
                                } else {
                                  tempDateError = null;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.blue400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.blue400),
                                const SizedBox(width: 12),
                                Text(
                                  tempStartDate != null 
                                      ? "${tempStartDate!.day}/${tempStartDate!.month}/${tempStartDate!.year}"
                                      : "Mulai Setelah",
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempEndDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                tempEndDate = picked;
                                if (tempStartDate != null && tempStartDate!.isAfter(picked)) {
                                  tempDateError = "Tanggal mulai harus sebelum tanggal selesai";
                                } else {
                                  tempDateError = null;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.blue400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.blue400),
                                const SizedBox(width: 12),
                                Text(
                                  tempEndDate != null 
                                      ? "${tempEndDate!.day}/${tempEndDate!.month}/${tempEndDate!.year}"
                                      : "Selesai Sebelum",
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        if (tempDateError != null) ...[
                          const SizedBox(height: 8),
                          Text(tempDateError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Filter Jumlah Pemain", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue400)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: participantsController,
                          decoration: const InputDecoration(
                            hintText: "Jumlah pemain...",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            tempParticipants = value; 
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Future.delayed(Duration.zero, () {
                      organizerController.dispose();
                      participantsController.dispose();
                    });
                  },
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    if (tempDateError != null) return;

                    setState(() {
                      _organizerFilter = tempOrganizer;
                      _startDateAfter = tempStartDate;
                      _endDateBefore = tempEndDate;
                      _participantsFilter = tempParticipants;
                      _primarySortField = tempPrimarySort;
                      _dateError = tempDateError;
                      
                    });
                    
                    if (!_validateDates()) {
                      CustomSnackbar.show(
                        context,
                        "Tanggal mulai harus sebelum tanggal selesai!",
                        SnackbarStatus.error,
                      );
                      return;
                    }
                    
                    _updateFilterCount();

                    Navigator.of(dialogContext).pop();
              
                    Future.delayed(Duration.zero, () {
                      organizerController.dispose();
                      participantsController.dispose();
                    });
                    
                    _fetchTournaments(isNewSearch: true);
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
        onPressed: _currentPage > 1 ? () => _fetchTournaments(page: _currentPage - 1) : null,
        color: _currentPage > 1 ? AppColors.blue400 : Colors.grey,
      ),
    );

    Set<int> pagesToShow = {1, _totalPages, _currentPage};
    
    for (int i = -1; i <= 1; i++) {
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
            onPressed: page == _currentPage ? null : () => _fetchTournaments(page: page),
            style: ElevatedButton.styleFrom(
              backgroundColor: page == _currentPage ? AppColors.blue400 : Colors.white,
              foregroundColor: page == _currentPage ? Colors.white : AppColors.blue400,
              minimumSize: const Size(36, 36), 
              padding: const EdgeInsets.symmetric(horizontal: 8), 
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
        onPressed: _currentPage < _totalPages ? () => _fetchTournaments(page: _currentPage + 1) : null,
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


  Widget _buildDefaultTournamentIcon() {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.emoji_events, color: AppColors.blue400, size: 28),
    );
  }

  Widget _buildStatIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue50,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Forum Turnamen",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: LeftDrawer(userData: widget.userData),
      
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
                  hintText: "Cari turnamen...",
                  prefixIcon: const Icon(Icons.search, color: AppColors.blue400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.blue400),
                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.filter_list, size: 20, color: AppColors.blue400),
                                const SizedBox(width: 8),
                                const Text(
                                  "Filter",
                                  style: TextStyle(
                                    color: AppColors.blue400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_activeFilterCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.blue400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _activeFilterCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                            value: _sortDirection,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.blue400),
                            style: const TextStyle(
                              color: AppColors.blue400,
                              fontWeight: FontWeight.w500,
                            ),
                            items: const [
                              DropdownMenuItem(value: "asc", child: Text("A-Z / Lama")),
                              DropdownMenuItem(value: "desc", child: Text("Z-A / Baru")),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _sortDirection = value ?? "desc";
                              });
                              _fetchTournaments(isNewSearch: true);
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

            if (_organizerFilter.isNotEmpty || _startDateAfter != null || _endDateBefore != null || _participantsFilter.isNotEmpty)
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_organizerFilter.isNotEmpty)
                      _buildChip("Org: $_organizerFilter", () {
                        setState(() {
                          _organizerFilter = "";
                          _updateFilterCount();
                          _fetchTournaments(isNewSearch: true);
                        });
                      }),

                    if (_startDateAfter != null)
                      _buildChip("Mulai > ${_startDateAfter!.day}/${_startDateAfter!.month}", () {
                        setState(() {
                          _startDateAfter = null;
                          _updateFilterCount();
                          _fetchTournaments(isNewSearch: true);
                        });
                      }),

                    if (_endDateBefore != null)
                      _buildChip("Selesai < ${_endDateBefore!.day}/${_endDateBefore!.month}", () {
                        setState(() {
                          _endDateBefore = null;
                          _updateFilterCount();
                          _fetchTournaments(isNewSearch: true);
                        });
                      }),

                    if (_participantsFilter.isNotEmpty)
                      _buildChip("Pemain: $_participantsFilter", () {
                        setState(() {
                          _participantsFilter = "";
                          _updateFilterCount();
                          _fetchTournaments(isNewSearch: true);
                        });
                      }),
                      
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                           setState(() {
                             _organizerFilter = "";
                             _startDateAfter = null;
                             _endDateBefore = null;
                             _participantsFilter = "";
                             _activeFilterCount = 0;
                             _fetchTournaments(isNewSearch: true);
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
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _isLoading && _tournaments.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blue400))
                  : _tournaments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                "Tidak ada turnamen ditemukan.",
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(), 
                          itemCount: _tournaments.length,
                          itemBuilder: (_, index) {
                            final tournament = _tournaments[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DaftarThreadPage(tournament: tournament),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: (tournament.banner != null && tournament.banner!.isNotEmpty)
                                                ? Image.network(
                                                    tournament.banner!,
                                                    width: 50, 
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx, err, stack) => _buildDefaultTournamentIcon(),
                                                  )
                                                : _buildDefaultTournamentIcon(),
                                          ),
                                          
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tournament.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "By @${tournament.organizer}",
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                        ],
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                                        child: Row(
                                          children: [
                                            _buildStatIcon(Icons.forum_outlined, "${tournament.threadCount} Thread"),
                                            const SizedBox(width: 12),
                                            _buildStatIcon(Icons.comment_outlined, "${tournament.postCount} Post"),
                                            const SizedBox(width: 12),
                                            _buildStatIcon(Icons.people, "${tournament.participantCount} User"),
                                          ],
                                        ),
                                      ),

                                      if (tournament.relatedImages.isNotEmpty) ...[
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Tim yang berpartisipasi: ",
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 40, 
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: tournament.relatedImages.length,
                                            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                                            itemBuilder: (context, imgIndex) {
                                              final String? imgUrl = tournament.relatedImages[imgIndex];
                                              bool hasImage = imgUrl != null && imgUrl.isNotEmpty;

                                              return Container(
                                                width: 40,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade200),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: hasImage 
                                                    ? Image.network(
                                                        imgUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, stack) => Container(
                                                          color: Colors.grey[100],
                                                          child: const Center(child: Icon(Icons.group, size: 20, color: Colors.grey)),
                                                        ),
                                                      )
                                                    : Container( 
                                                        color: Colors.grey[100],
                                                        child: const Center(child: Icon(Icons.group, size: 20, color: Colors.grey)),
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            _buildPagination(),
          ],
        ),
      ),
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