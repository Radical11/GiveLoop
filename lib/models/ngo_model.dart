class Ngo {
  final int id;
  final String title;
  final String charityName;
  final String location;
  final String distance;
  final String category;
  final String image;
  final String about;
  final String urgentText;
  final int qtyNeeded;
  final int qtyPledged;
  final int urgency;

  Ngo.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      title = json['title'],
      charityName = json['charity']['name'],
      location = json['location'],
      distance = '${json['distance'] ?? 0} km away',
      category = json['category'],
      image = json['image'] ?? 'assets/images/placeholder.png',
      about = json['description'],
      urgentText = json['urgent_text'],
      qtyNeeded = json['qty_needed'],
      qtyPledged = json['qty_pledged'],
      urgency = json['urgency'];

  String get tag => category;
}
