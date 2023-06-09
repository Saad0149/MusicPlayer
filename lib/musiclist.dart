import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class MusicList extends StatefulWidget {
  const MusicList({super.key});

  @override
  State<MusicList> createState() => _MusicListState();
}

class _MusicListState extends State<MusicList> {
  late Map<String, dynamic> data;
  String name = '';
  String tokens = '';
  var albumUrl;
  late AudioPlayer _audioPlayer;
  var bearer;
  Future<void> getToken() async {
    print("fetching tokens");
    const url = 'https://accounts.spotify.com/api/token';
    final uri = Uri.parse(url);
    const clientId = '6658b07776174f608b8fb108f1f25a6f';
    const clientSecret = 'f1e25f6c8a0d4747931552d89d536f22';
    var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    var body =
        'grant_type=client_credentials&client_id=$clientId&client_secret=$clientSecret';
    var authResponse = await http.post(
      uri,
      headers: headers,
      body: body,
    );
    print(authResponse.statusCode);
    try {
      if (authResponse.statusCode == 200) {
        var responseBody = authResponse.body;
        print(responseBody);
        var json = jsonDecode(responseBody);
        setState(() {
          tokens = json['access_token'];
        });

        print(tokens);
      }
    } catch (e) {
      print(e);
    }
    const urlAlbum = 'https://api.spotify.com/v1/tracks/11dFghVXANMlKmJXsNCbNl';
    final uriAlbum = Uri.parse(urlAlbum);
    final response =
        await http.get(uriAlbum, headers: {'Authorization': 'Bearer $tokens'});
    print(response.statusCode);
    final bodyData = response.body;
    final json1 = jsonDecode(bodyData);
    setState(() {
      data = json1['album'];
      albumUrl = json1['external_urls'];
    });
    print(data);
    print(albumUrl);
  }

  @override
  void initState() {
    super.initState();
    initializeAudioPlayer();
  }

  void initializeAudioPlayer() async {
    await getToken();
    Timer.periodic(const Duration(hours: 1), (Timer timer) {
      getToken();
    });
    //_audioPlayer = AudioPlayer()..setAsset('assets/Makhna.mp3');
    _audioPlayer = AudioPlayer()
      ..setUrl(
          'https:soundcloud.com/ameer-hamxa-385287711/zindagi_awargi_hai-jhoom_ost');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Music Player'),
        ),
        backgroundColor: const Color.fromARGB(255, 140, 179, 247),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 100,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(data['images'][1]['url']),
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            Text(data['name'], style: const TextStyle(fontSize: 35)),
            const SizedBox(
              height: 10,
            ),
            Text(data['artists'][0]['name'].toString(),
                style: const TextStyle(fontSize: 20)),
            Controls(audioPlayer: _audioPlayer),
          ],
        ));
  }
}

class Controls extends StatelessWidget {
  const Controls({super.key, required this.audioPlayer});
  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
        stream: audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final procesingState = playerState?.processingState;
          final playing = playerState?.playing;

          if (!(playing ?? false)) {
            return IconButton(
              onPressed: audioPlayer.play,
              icon: const Icon(Icons.play_arrow_rounded),
              iconSize: 80,
              color: Colors.white,
            );
          } else if (procesingState != ProcessingState.completed) {
            return IconButton(
              onPressed: audioPlayer.play,
              icon: const Icon(Icons.pause_rounded),
              iconSize: 80,
              color: Colors.white,
            );
          } else {
            return const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.white,
            );
          }
        });
  }
}
