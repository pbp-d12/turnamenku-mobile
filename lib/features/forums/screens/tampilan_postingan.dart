import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_thread.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_post.dart';

class TampilanUnggahanPage extends StatefulWidget {
  final ForumThread thread;
  final int? rootPostId;

  const TampilanUnggahanPage({super.key, required this.thread, this.rootPostId});

  @override
  State<TampilanUnggahanPage> createState() => _TampilanUnggahanPageState();
}

class _TampilanUnggahanPageState extends State<TampilanUnggahanPage> {
  bool _isInitialLoading = true;
  bool _isSubmitting = false; 
  
  List<ForumPost> _visiblePosts = [];
  
  late String _displayBody;
  late String _displayImageUrl;

  final Map<int, List<int>> _hierarchyMap = {}; 

  int _baseDepth = 0;

  @override
  void initState() {
    super.initState();
    _displayBody = widget.thread.body ?? ""; 
    _displayImageUrl = widget.thread.imageUrl ?? "";
    
    _fetchPosts(firstLoad: true);
  }

  Future<void> _fetchPosts({bool firstLoad = false}) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.forumPosts(widget.thread.id);

    try {
      final response = await request.get(url);
      
      if (!mounted) return;

      if (response != null && response['posts'] != null) {
        final rawList = response['posts'] as List;
        final posts = rawList.map((d) {
          if (d is Map<String, dynamic>) {
            d['id'] ??= 0;
            d['reply_count'] ??= 0;
            d['depth'] ??= 0;
            d['author_username'] ??= "Unknown";
            d['body'] ??= "";
            d['created_at'] ??= "";
            d['can_edit'] ??= false; 
            d['can_delete'] ??= false;
          }
          return ForumPost.fromJson(d);
        }).toList();

        final fullTree = _sortPostsByHierarchy(posts);
        
        _buildHierarchyMap(fullTree);

        ForumPost? mainThreadPost;
        try {
          mainThreadPost = fullTree.firstWhere((p) => p.parentId == null || p.depth == 0);
          _displayBody = mainThreadPost.body;
          _displayImageUrl = mainThreadPost.imageUrl ?? "";

        } catch (e) {
          mainThreadPost = null;
        }

        List<ForumPost> finalView;

        if (widget.rootPostId != null) {
          final branch = _getBranch(fullTree, widget.rootPostId!);
          if (branch.isNotEmpty) {
            _baseDepth = branch.first.depth;
          }
          finalView = List.from(branch);
        } else {
          finalView = fullTree;
          _baseDepth = 0;
          
          if (mainThreadPost != null) {
            finalView.removeWhere((p) => p.id == mainThreadPost!.id);
          }
        }

        if (mounted) {
          setState(() {
            _visiblePosts = finalView;
            if (firstLoad) _isInitialLoading = false;
          });
        }
      }
    } catch (e) {
        print("Error: $e");
        if (mounted && firstLoad) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchPosts(firstLoad: false);
  }

  void _buildHierarchyMap(List<ForumPost> posts) {
    _hierarchyMap.clear();
    for (var post in posts) {
      if (post.parentId != null) {
        if (!_hierarchyMap.containsKey(post.parentId)) {
          _hierarchyMap[post.parentId!] = [];
        }
        _hierarchyMap[post.parentId!]!.add(post.id);
      }
    }
  }

  int _getRecursiveReplyCount(int postId) {
    int count = 0;
    
    if (_hierarchyMap.containsKey(postId)) {
      List<int> childrenIds = _hierarchyMap[postId]!;
      count += childrenIds.length;
      
      for (int childId in childrenIds) {
        count += _getRecursiveReplyCount(childId);
      }
    }
    
    return count;
  }

  List<ForumPost> _getBranch(List<ForumPost> sortedTree, int rootId) {
    List<ForumPost> branch = [];
    bool insideBranch = false;
    int rootDepth = -1;

    for (var post in sortedTree) {
      if (post.id == rootId) {
        insideBranch = true;
        rootDepth = post.depth;
        branch.add(post);
      } else if (insideBranch) {
        if (post.depth <= rootDepth) {
          insideBranch = false;
        } else {
          branch.add(post);
        }
      }
    }
    return branch;
  }

  List<ForumPost> _sortPostsByHierarchy(List<ForumPost> flatList) {
    Map<int, List<ForumPost>> childrenMap = {};
    List<ForumPost> rootPosts = [];

    for (var post in flatList) {
      if (post.parentId == null) {
        rootPosts.add(post);
      } else {
        if (!childrenMap.containsKey(post.parentId)) {
          childrenMap[post.parentId!] = [];
        }
        childrenMap[post.parentId!]!.add(post);
      }
    }

    List<ForumPost> result = [];

    void traverse(ForumPost post, int currentDepth) {
      ForumPost indentedPost = ForumPost(
        id: post.id,
        authorUsername: post.authorUsername,
        body: post.body,
        createdAt: post.createdAt,
        imageUrl: post.imageUrl,
        replyCount: post.replyCount,
        isThreadAuthor: post.isThreadAuthor,
        isEdited: post.isEdited,
        parentId: post.parentId,
        depth: currentDepth,
        canEdit: post.canEdit,     
        canDelete: post.canDelete, 
      );

      result.add(indentedPost);

      if (childrenMap.containsKey(post.id)) {
        childrenMap[post.id]!.sort((a, b) => a.id.compareTo(b.id));
        for (var child in childrenMap[post.id]!) {
          traverse(child, currentDepth + 1);
        }
      }
    }

    for (var root in rootPosts) {
      traverse(root, 0);
    }

    if (result.length < flatList.length) {
      Set<int> processedIds = result.map((p) => p.id).toSet();
      for (var p in flatList) {
        if (!processedIds.contains(p.id)) result.add(p);
      }
    }

    return result;
  }

  void _showReplyDialog({int? parentId, String? replyToUser, String? replyToBody}) {
    String body = "";
    String imageUrl = ""; 
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(16), 
              child: SingleChildScrollView( 
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          ElevatedButton(
                            onPressed: _isSubmitting 
                              ? null 
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setDialogState(() => _isSubmitting = true);
                                    bool success = await _submitReply(body, parentId, imageUrl);
                                    if (mounted) {
                                      setDialogState(() => _isSubmitting = false);
                                      if (success) Navigator.pop(ctx);
                                    }
                                  }
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue400, 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              minimumSize: const Size(0, 32), 
                            ),
                            child: _isSubmitting 
                               ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : const Text("Balas", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (replyToUser != null)
                        IntrinsicHeight( 
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[300],
                                    child: Text(
                                      replyToUser.isNotEmpty ? replyToUser[0].toUpperCase() : "?",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Colors.grey[300],
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      replyToUser, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                                    ),
                                    const SizedBox(height: 4),
                                    if (replyToBody != null && replyToBody.isNotEmpty)
                                      Text(
                                        replyToBody,
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        text: "Membalas ",
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        children: [
                                          TextSpan(
                                            text: "@$replyToUser",
                                            style: const TextStyle(color: AppColors.blue400),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12), 
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: Form(
                              key: formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: "Unggah balasan Anda...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.all(12),
                                      hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    style: const TextStyle(fontSize: 16),
                                    maxLines: 5,
                                    minLines: 3,
                                    enabled: !_isSubmitting,
                                    validator: (v) => v == null || v.isEmpty ? "Tidak boleh kosong!" : null,
                                    onChanged: (v) => body = v,
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  TextFormField(
                                    decoration: InputDecoration(
                                      hintText: "Image URL (Optional)",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      prefixIcon: const Icon(Icons.image_outlined, color: AppColors.blue400, size: 20),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    enabled: !_isSubmitting,
                                    onChanged: (v) => imageUrl = v,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitReply(String body, int? parentId, String imageUrl) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.replyToThread(widget.thread.id);

    try {
      final response = await request.post(url, {
        'body': body,
        'parent_id': parentId?.toString() ?? "",
        'image': imageUrl.trim(), 
      });

      if (!mounted) return false;

      if (response['success'] == true) {
        await _fetchPosts(firstLoad: false);
        if (mounted) {
          CustomSnackbar.show(context, "Balasan terkirim!", SnackbarStatus.success);
        }
        return true;
      } else {
        CustomSnackbar.show(context, "Gagal: ${response['error'] ?? response['message']}", SnackbarStatus.error);
        return false;
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
      }
      return false;
    }
  }


  void _showEditDialog(ForumPost post) {
    final bodyController = TextEditingController(text: post.body);
    final imageController = TextEditingController(text: post.imageUrl ?? "");
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit Unggahan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: bodyController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: "Edit konten...",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          enabled: !_isSubmitting,
                          validator: (v) => v == null || v.isEmpty ? "Tidak boleh kosong" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            hintText: "URL Gambar (Opsional)",
                            labelText: "URL Gambar",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.image),
                          ),
                          maxLines: 1,
                          enabled: !_isSubmitting,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(ctx),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting 
                          ? null 
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() => _isSubmitting = true);
                                bool success = await _submitEdit(post.id, bodyController.text, imageController.text);
                                if (mounted) {
                                  setDialogState(() => _isSubmitting = false);
                                  if (success) Navigator.pop(ctx);
                                }
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, 
                          foregroundColor: Colors.white
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Simpan"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<bool> _submitEdit(int postId, String newBody, String newImage) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.editPost(postId); 

    try {
      final response = await request.post(url, {
        'body': newBody,
        'image': newImage.trim(),
        'remove_image': newImage.trim().isEmpty ? 'on' : '', 
      });

      if (!mounted) return false;

      if (response['success'] == true) {
        await _fetchPosts(firstLoad: false);
        if (mounted) {
          CustomSnackbar.show(context, "Unggahan berhasil diedit!", SnackbarStatus.success);
        }
        return true;
      } else {
        CustomSnackbar.show(context, "Gagal: ${response['error'] ?? response['message']}", SnackbarStatus.error);
        return false;
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
      }
      return false;
    }
  }


  Future<void> _deletePost(int postId) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.deletePost(postId); 

    CustomSnackbar.show(context, "Menghapus Unggahan...", SnackbarStatus.info);

    try {
      final response = await request.post(url, {});

      if (!mounted) return;

      if (response['success'] == true) {
        CustomSnackbar.show(context, "Unggahan berhasil dihapus!", SnackbarStatus.success);
        await _fetchPosts(firstLoad: false);
      } else {
        CustomSnackbar.show(context, "Gagal menghapus: ${response['error'] ?? response['message']}", SnackbarStatus.error);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
      }
    }
  }

  void _confirmAndDelete(ForumPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Anda yakin ingin menghapus Unggahan dari ${post.authorUsername}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _deletePost(post.id);   
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadTitleHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: Text(
                  widget.thread.authorUsername.isNotEmpty
                      ? widget.thread.authorUsername[0].toUpperCase()
                      : "?",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.thread.authorUsername,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    widget.thread.createdAt,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            widget.thread.title,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w700, 
              letterSpacing: -0.5,
              height: 1.2,
              color: Colors.black87,
            ),
          ),
          
          if (_displayBody.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _displayBody,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
          ],

          if (_displayImageUrl.isNotEmpty) ...[
             const SizedBox(height: 16),
             ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _displayImageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain, 
                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                ),
             ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.rootPostId == null ? "Diskusi" : "Balasan",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue400))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.blue400,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    itemCount: _visiblePosts.length + 1, 
                    padding: const EdgeInsets.only(bottom: 120), 
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildThreadTitleHeader();
                      }

                      final post = _visiblePosts[index - 1];
                  
                      int relativeDepth = post.depth - _baseDepth;
                      
                      bool isMainContextPost = (widget.rootPostId != null &&
                                                _displayBody == post.body); 
                  
                      if (isMainContextPost) relativeDepth = 0;
                  
                      bool isHidden = false;
                      if (!isMainContextPost && relativeDepth > 3) {
                        isHidden = true;
                      }
                  
                      if (isHidden) return const SizedBox.shrink();
                  
                      bool hasHiddenChildren = _visiblePosts.any((p) =>
                          p.parentId == post.id && (p.depth - _baseDepth) > 3
                      );
                  
                      if (isMainContextPost) hasHiddenChildren = false;
                  
                      int totalReplies = _getRecursiveReplyCount(post.id);
                  
                      Widget postWidget = _buildTweetReply(
                        post, 
                        hasHiddenChildren, 
                        relativeDepth, 
                        isMainContextPost, 
                        totalReplies
                      );
                  
                      if (isMainContextPost && (index - 1) < _visiblePosts.length - 1) {
                        return Column(
                          children: [
                            postWidget,
                            Container(height: 8, color: Colors.grey[100]),
                          ],
                        );
                      }
                  
                      return postWidget;
                    },
                  ),
                ),

                Positioned(
                  bottom: 80, 
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showReplyDialog(
                      parentId: null, 
                      replyToUser: widget.thread.authorUsername,
                      replyToBody: _displayBody 
                    ),
                    backgroundColor: AppColors.blue400,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTweetReply(ForumPost post, bool showSeeMoreButton, int relativeDepth, bool isMainContext, int totalDescendants) {
    double indent = (relativeDepth * 16).toDouble();
    bool isReply = relativeDepth > 0 && !isMainContext;
    
    bool isOP = post.authorUsername == widget.thread.authorUsername;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
          left: isReply ? BorderSide(color: Colors.grey.shade300, width: 2) : BorderSide.none,
        ),
      ),
      margin: isReply ? EdgeInsets.only(left: indent) : EdgeInsets.zero,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    post.authorUsername.isNotEmpty ? post.authorUsername[0].toUpperCase() : "?",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.authorUsername,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                            color: isOP ? AppColors.blue400 : Colors.black87, 
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      if (isOP) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "OP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: 6),
                      Text(
                        post.createdAt,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (post.isEdited)
                        Text(
                          " (diedit)",
                          style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                if (post.canEdit || post.canDelete)
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(post);
                        } else if (value == 'delete') {
                          _confirmAndDelete(post);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (post.canEdit)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: Colors.black87),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (post.canDelete)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_forever, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Text(post.body, style: const TextStyle(fontSize: 15, height: 1.4)),

            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                InkWell(
                  onTap: () => _showReplyDialog(
                    parentId: post.id, 
                    replyToUser: post.authorUsername,
                    replyToBody: post.body 
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      if (totalDescendants > 0)
                        Text(
                          totalDescendants.toString(),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (showSeeMoreButton)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TampilanUnggahanPage(
                          thread: widget.thread,
                          rootPostId: post.id,
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "Lihat balasan lainnya...",
                      style: TextStyle(
                        color: AppColors.blue400,
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}