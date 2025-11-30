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
    int id;
    String authorUsername;
    String body;
    String createdAt;
    String? imageUrl;
    int? parentId;
    bool isThreadAuthor;
    int replyCount;
    bool isEdited;

    ForumPost({
        required this.id,
        required this.authorUsername,
        required this.body,
        required this.createdAt,
        required this.imageUrl,
        required this.parentId,
        required this.isThreadAuthor,
        required this.replyCount,
        required this.isEdited,
    });

    factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
        id: json["id"],
        authorUsername: json["author_username"],
        body: json["body"],
        createdAt: json["created_at"],
        imageUrl: json["image_url"],
        parentId: json["parent_id"],
        isThreadAuthor: json["is_thread_author"],
        replyCount: json["reply_count"],
        isEdited: json["is_edited"],
    );

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
    };
}