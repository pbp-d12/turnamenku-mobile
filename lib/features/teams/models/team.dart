import 'dart:convert';

class Team {
  int id;
  String name;
  String logo;
  String captain;
  int membersCount;
  List<String> members;

  Team({
    required this.id,
    required this.name,
    required this.logo,
    required this.captain,
    required this.membersCount,
    required this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json["id"],
    name: json["name"],
    logo: json["logo"] ?? "", 
    captain: json["captain"] ?? "Unknown",
    membersCount: json["members_count"],
    members: json["members"] != null 
        ? List<String>.from(json["members"].map((x) => x))
        : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "logo": logo,
    "captain": captain,
    "members_count": membersCount,
    "members": List<dynamic>.from(members.map((x) => x)),
  };
}

// Fungsi helper untuk memparsing list data langsung dari JSON Django
List<Team> teamFromJson(String str) {
  final jsonData = json.decode(str);
  // Mengambil key "data" sesuai format JsonResponse view Django kamu
  return List<Team>.from(jsonData["data"].map((x) => Team.fromJson(x)));
}