import 'dart:convert';

ForumSearchResponse forumSearchResponseFromJson(String str) => ForumSearchResponse.fromJson(json.decode(str));

class ForumSearchResponse {
    List<ForumTournament> tournaments;

    ForumSearchResponse({
        required this.tournaments,
    });

    factory ForumSearchResponse.fromJson(Map<String, dynamic> json) => ForumSearchResponse(
        tournaments: List<ForumTournament>.from(json["tournaments"].map((x) => ForumTournament.fromJson(x))),
    );
}

class ForumTournament {
    int id;
    String name;
    String description;
    int threadCount;
    int postCount;
    String organizerUsername;

    ForumTournament({
        required this.id,
        required this.name,
        required this.description,
        required this.threadCount,
        required this.postCount,
        required this.organizerUsername,
    });

    factory ForumTournament.fromJson(Map<String, dynamic> json) => ForumTournament(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        threadCount: json["thread_count"],
        postCount: json["post_count"],
        organizerUsername: json["organizer_username"],
    );
}