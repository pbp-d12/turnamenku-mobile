import 'dart:convert';

class Tournament {
  final int id;
  final String name;
  final String description;
  final String organizer;
  final String startDate;
  final String endDate;
  final String? bannerUrl;
  final String detailPageUrl;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.organizer,
    required this.startDate,
    required this.endDate,
    this.bannerUrl,
    required this.detailPageUrl,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      organizer: json['organizer'], 
      startDate: json['start_date'],
      endDate: json['end_date'],
      bannerUrl: json['banner_url'],
      detailPageUrl: json['detail_page_url'],
    );
  }
}