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
  final int id;
  final String name;
  final String description;
  final String organizer;
  final String startDate;
  final String endDate;
  final int threadCount;
  final int postCount;
  final int participantCount;
  final List<String> relatedImages;
  
  final String? banner; 

  ForumTournament({
    required this.id,
    required this.name,
    required this.description,
    required this.organizer,
    required this.startDate,
    required this.endDate,
    required this.threadCount,
    required this.postCount,
    required this.participantCount,
    required this.relatedImages,
    
    this.banner, 
  });

  factory ForumTournament.fromJson(Map<String, dynamic> json) {
    return ForumTournament(
      id: json['id'],
      name: json['name'] ?? "Unnamed Tournament",
      description: json['description'] ?? "",
      organizer: json['organizer_username'] ?? "Unknown",
      startDate: json['start_date'] ?? "",
      endDate: json['end_date'] ?? "",
      threadCount: int.tryParse(json['thread_count']?.toString() ?? "0") ?? 0,
      postCount: int.tryParse(json['post_count']?.toString() ?? "0") ?? 0,
      participantCount: int.tryParse(json['participant_count']?.toString() ?? "0") ?? 0,
      
      relatedImages: json['related_images'] != null
          ? List<String>.from(json['related_images'].map((x) => x.toString()))
          : [],
      
      banner: json['banner'], 
    );
  }
}