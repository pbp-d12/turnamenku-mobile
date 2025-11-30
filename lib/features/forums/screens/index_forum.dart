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
      setState(() {
        _searchQuery = _searchController.text;
      });
      _fetchTournaments(isNewSearch: true);
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

  List<String> _getActiveFilterFields() {
    List<String> activeFields = [];
    if (_organizerFilter.isNotEmpty) activeFields.add('organizer');
    if (_startDateAfter != null || _endDateBefore != null) activeFields.add('date');
    if (_participantsFilter.isNotEmpty) activeFields.add('participants');
    return activeFields;
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
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isNewSearch) {
        _currentPage = 1;
        _tournaments = [];
      }
    });

    final request = context.read<CookieRequest>();

    try {
      final activeFilters = _getActiveFilterFields();
      String sortParam;
      final sortPrefix = _sortDirection == 'desc' ? '-' : '';

      if (activeFilters.length > 1) {
        sortParam = '${sortPrefix}name';
      } else if (activeFilters.length == 1) {
        String activeFilterField = 'name';
        if (_organizerFilter.isNotEmpty) activeFilterField = 'organizer';
        else if (_startDateAfter != null || _endDateBefore != null) activeFilterField = 'start_date';
        else if (_participantsFilter.isNotEmpty) activeFilterField = 'participants';

        if (_primarySortField == activeFilterField) {
          sortParam = '$sortPrefix$_primarySortField';
        } else if (_primarySortField == 'name') {
          sortParam = '${sortPrefix}name';
        } else {
          sortParam = '${sortPrefix}name';
        }
      } else {
        sortParam = '${sortPrefix}name';
      }

      final params = {
        'page': page.toString(),
        'sort': sortParam,
        'primary_sort': _primarySortField ?? 'name',
        'q': _searchQuery,
        'organizer': _organizerFilter,
        'start_date_after': _startDateAfter?.toIso8601String().split('T')[0] ?? "",
        'end_date_before': _endDateBefore?.toIso8601String().split('T')[0] ?? "",
        'participants': _participantsFilter,
      };
      
      params.removeWhere((key, value) => value.isEmpty);
      
      final queryString = Uri(queryParameters: params).query;
      final response = await request.get("${Endpoints.forumSearch}?$queryString");
      final tournaments = (response['tournaments'] as List)
          .map((d) => ForumTournament.fromJson(d))
          .toList();
      
      final pagination = response['pagination'] ?? {};
      
      setState(() {
        _tournaments = tournaments;
        _currentPage = pagination['current_page'] ?? page;
        _totalPages = pagination['total_pages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _tournaments = [];
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
            List<String> tempActiveFilters = [];
            if (tempOrganizer.isNotEmpty) tempActiveFilters.add('organizer');
            if (tempStartDate != null || tempEndDate != null) tempActiveFilters.add('date');
            if (tempParticipants.isNotEmpty) tempActiveFilters.add('participants');
            
            bool showPrimarySort = tempActiveFilters.length > 1;

            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Filter Turnamen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue400,
                      ),
                    ),
                  ),
                  if (tempActiveFilters.isNotEmpty)
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
                        const Text("Filter Penyelenggara", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue400)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: organizerController,
                          decoration: const InputDecoration(
                            hintText: "Username penyelenggara...",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              tempOrganizer = value;
                            });
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
                                      : "Mulai Setelah Tanggal",
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
                                      : "Selesai Sebelum Tanggal",
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
                            setDialogState(() {
                              tempParticipants = value;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    if (showPrimarySort) ...[
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Sortir Utama", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue400)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: tempPrimarySort,
                            decoration: const InputDecoration(
                              hintText: "Pilih field sortir...",
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("Tidak ada")),
                              if (tempOrganizer.isNotEmpty)
                                const DropdownMenuItem(value: "organizer", child: Text("Penyelenggara")),
                              if (tempStartDate != null || tempEndDate != null)
                                const DropdownMenuItem(value: "start_date", child: Text("Tanggal Mulai")),
                              if (tempParticipants.isNotEmpty)
                                const DropdownMenuItem(value: "participants", child: Text("Jumlah Pemain")),
                              const DropdownMenuItem(value: "name", child: Text("Nama Turnamen")),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                tempPrimarySort = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
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
                  child: const Text("Terapkan Filter"),
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
            onPressed: page == _currentPage ? null : () => _fetchTournaments(page: page),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue50, 
      appBar: AppBar(
        title: const Text(
          "Forum Turnamen",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: LeftDrawer(userData: widget.userData),
      body: Column(
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.blue50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.emoji_events, color: AppColors.blue400, size: 24),
                              ),
                              title: Text(
                                tournament.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "${tournament.threadCount} Thread • ${tournament.postCount} Post",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DaftarThreadPage(tournament: tournament),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  _buildPagination(),
        ],
      ),
    );
  }
}