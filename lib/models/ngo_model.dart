class Ngo {
  final int id;
  final String title;
  final String charityName;
  final String category;
  final int qtyNeeded;
  final int qtyPledged;
  final int urgency;
  final String deadline;
  final String status;
  final String image;
  final String about;
  final String distance;
  final String urgentText;
  final String location;

  Ngo({
    required this.id,
    required this.title,
    required this.charityName,
    required this.category,
    required this.qtyNeeded,
    required this.qtyPledged,
    required this.urgency,
    required this.deadline,
    required this.status,
    this.image = '',
    required this.about,
    required this.distance,
    required this.urgentText,
    required this.location,
  });

  factory Ngo.fromJson(Map<String, dynamic> json) {
    return Ngo(
      id: json['id'],
      title: json['title'],
      charityName: json['charity']?.toString() ?? 'Unknown',
      category: json['category'],
      qtyNeeded: json['qty_needed'],
      qtyPledged: json['qty_pledged'],
      urgency: json['urgency'],
      deadline: json['deadline'],
      status: json['status'],
      image: json['image'] ?? '',
      about: json['title'],
      distance: '2 km away',
      location: json['location'] ?? 'Unknown',
      urgentText: json['urgent_text'] ?? 'No urgent text available',
    );
  }
}
