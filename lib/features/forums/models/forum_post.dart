import 'dart:convert';

ForumPostResponse forumPostResponseFromJson(String str) => ForumPostResponse.fromJson(json.decode(str));

String forumPostResponseToJson(ForumPostResponse data) => json.encode(data.toJson());

class ForumPostResponse {
    List<ForumPost> posts;

    ForumPostResponse({
        required this.posts,
    });

    factory ForumPostResponse.fromJson(Map<String, dynamic> json) => ForumPostResponse(
        posts: List<ForumPost>.from(json["posts"].map((x) => ForumPost.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "posts": List<dynamic>.from(posts.map((x) => x.toJson())),
    };
}

class ForumPost {
  final int id;
  final String authorUsername;
  final String body;
  final String createdAt;
  final String? imageUrl;
  final int replyCount;
  final bool isThreadAuthor;
  final bool isEdited;
  final int? parentId;
  final int depth;
  
  final bool canEdit;
  final bool canDelete;

  ForumPost({
    required this.id,
    required this.authorUsername,
    required this.body,
    required this.createdAt,
    this.imageUrl,
    this.replyCount = 0,
    this.isThreadAuthor = false,
    this.isEdited = false,
    this.parentId,
    this.depth = 0,
    
    this.canEdit = false,
    this.canDelete = false,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] ?? 0,
      authorUsername: json['author_username'] ?? "Unknown",
      body: json['body'] ?? "",
      createdAt: json['created_at'] ?? "",
      imageUrl: json['image_url'], 
      replyCount: json['reply_count'] ?? 0,
      isThreadAuthor: json['is_thread_author'] ?? false,
      isEdited: json['is_edited'] ?? false,
      parentId: json['parent_id'],
      depth: json['depth'] ?? 0,
      
      canEdit: json['can_edit'] ?? false,
      canDelete: json['can_delete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "author_username": authorUsername,
        "body": body,
        "created_at": createdAt,
        "image_url": imageUrl,
        "parent_id": parentId,
        "is_thread_author": isThreadAuthor,
        "reply_count": replyCount,
        "is_edited": isEdited,
        "depth": depth,
        "can_edit": canEdit,
        "can_delete": canDelete,
    };
}