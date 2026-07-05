class MusicSongModel {
  final String title;
  final String artist;

  const MusicSongModel({required this.title, required this.artist});

  factory MusicSongModel.fromJson(Map<String, dynamic> json) {
    return MusicSongModel(title: json['title'] as String, artist: json['artist'] as String);
  }

  String get searchTerm => '$title $artist';
}

class MusicCategoryModel {
  final String id;
  final String name;
  final List<MusicSongModel> songs;

  const MusicCategoryModel({required this.id, required this.name, required this.songs});

  factory MusicCategoryModel.fromJson(Map<String, dynamic> json) {
    return MusicCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List)
          .map((e) => MusicSongModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
