class CaptainStatus {
  final bool canRegister;
  final bool canDeregister;
  final bool isRegistrationOpen;


  CaptainStatus({
    required this.canRegister,
    required this.canDeregister,
    required this.isRegistrationOpen,
  });

  factory CaptainStatus.fromJson(Map<String, dynamic> json) {
    return CaptainStatus(
      canRegister: json['can_register'] ?? false,
      canDeregister: json['can_deregister'] ?? false,
      isRegistrationOpen: json['is_registration_open'] ?? false,
    );
  }
}