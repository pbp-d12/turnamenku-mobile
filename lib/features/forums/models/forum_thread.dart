import 'dart:convert';

ForumThreadResponse forumThreadResponseFromJson(String str) => ForumThreadResponse.fromJson(json.decode(str));

class ForumThreadResponse {
    List<ForumThread> threads;

    ForumThreadResponse({
        required this.threads,
    });

    factory ForumThreadResponse.fromJson(Map<String, dynamic> json) => ForumThreadResponse(
        threads: List<ForumThread>.from(json["threads"].map((x) => ForumThread.fromJson(x))),
    );
}

class ForumThread {
  final int id;
  final String title;
  final String authorUsername;
  final String createdAt;
  final int replyCount;
  final String? body; 
  final String? imageUrl; 
  
  final bool canEdit;
  final bool canDelete; 

  ForumThread({
    required this.id,
    required this.title,
    required this.authorUsername,
    required this.createdAt,
    this.replyCount = 0,
    this.body,
    this.imageUrl,
    
    this.canEdit = false, 
    this.canDelete = false, 
  });

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    return ForumThread(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Tanpa Judul',
      authorUsername: json['author_username'] ?? 'Unknown',
      createdAt: json['created_at'] ?? '',
      replyCount: json['reply_count'] ?? 0,
      body: json['body'],
      imageUrl: json['image_url'] ?? json['image'], 
      
      canEdit: json['can_edit'] ?? false,
      canDelete: json['can_delete'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author_username': authorUsername,
    'created_at': createdAt,
    'reply_count': replyCount,
    'can_edit': canEdit,
    'can_delete': canDelete,
  };
}