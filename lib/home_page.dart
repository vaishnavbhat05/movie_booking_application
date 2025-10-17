import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:dual_screen/dual_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    const url = 'https://jsonfakery.com/movies/random/20';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          movies = data is List ? data : [data];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hinge = MediaQuery.of(context).hinge;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: hinge != null && hinge.bounds.width < hinge.bounds.height
            ? const Align(
                alignment: Alignment.topCenter, child: Text('Movie Booking'))
            : const Text('Movie Booking'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : movies.isEmpty
              ? const Center(child: Text('No movies found.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;

                    if (hinge != null) {
                      // Foldable device
                      if (hinge.bounds.width > hinge.bounds.height) {
                        // Horizontal hinge → top/bottom
                        crossAxisCount = 2;
                      } else {
                        // Vertical hinge → left/right
                        crossAxisCount = 1;
                      }

                      // Use TwoPane on foldable devices
                      return TwoPane(
                        startPane: GridView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: movies.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),
                          itemBuilder: (context, index) =>
                              buildMovieCard(context, movies[index]),
                        ),
                        endPane: const SizedBox.shrink(),
                        panePriority: TwoPanePriority.start,
                        paneProportion: 0.5,
                      );
                    } else {
                      // Normal phone
                      crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: movies.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.5,
                        ),
                        itemBuilder: (context, index) =>
                            buildMovieCard(context, movies[index]),
                      );
                    }
                  },
                ),
    );
  }

  Widget buildMovieCard(BuildContext context, dynamic movie) {
    final title = movie['original_title'] ?? 'Unknown Title';
    final popularity = movie['vote_average']?.toString() ?? 'N/A';
    final posterPath = movie['poster_path'];
    final imageUrl =
        (posterPath != null && posterPath.toString().startsWith('http'))
            ? posterPath
            : 'assets/images/dog1.png';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 4,
      child: Row(
        children: [
          Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              image: DecorationImage(
                image: imageUrl.startsWith('http')
                    ? NetworkImage(imageUrl)
                    : AssetImage(imageUrl) as ImageProvider<Object>,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text(popularity, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        const imdbHomeUrl = 'https://www.imdb.com/';
                        await launchURL(imdbHomeUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        'View on IMDb',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open IMDb link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening IMDb: $e')),
      );
    }
  }
}
