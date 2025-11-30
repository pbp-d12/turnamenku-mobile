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
    int id;
    String title;
    String authorUsername;
    String createdAt;
    int replyCount;

    ForumThread({
        required this.id,
        required this.title,
        required this.authorUsername,
        required this.createdAt,
        required this.replyCount,
    });

    factory ForumThread.fromJson(Map<String, dynamic> json) => ForumThread(
        id: json["id"],
        title: json["title"],
        authorUsername: json["author_username"],
        createdAt: json["created_at"],           
        replyCount: json["reply_count"],         
    );
}