import 'dart:async';
import 'dart:convert';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class MusicList extends StatefulWidget {
  const MusicList({super.key});

  @override
  State<MusicList> createState() => _MusicListState();
}

class _MusicListState extends State<MusicList> {
  List<dynamic> data = [];
  late Map<String, dynamic> tracks;
  List<dynamic> artist = [];
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
    const urlAlbum = 'https://api.spotify.com/v1/albums/4aawyAB9vmqN3uQ7FjRGTy';
    final uriAlbum = Uri.parse(urlAlbum);
    final response =
        await http.get(uriAlbum, headers: {'Authorization': 'Bearer $tokens'});
    print(response.statusCode);
    final bodyData = response.body;
    final json1 = jsonDecode(bodyData);
    setState(() {
      data = json1['images'];
      tracks = json1['tracks'];
      artist = json1['artists'];
    });
    print(data);
    print(tracks);
    print(artist);
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _audioPlayer.positionStream,
          _audioPlayer.bufferedPositionStream,
          _audioPlayer.durationStream,
          (position, bufferposition, duration) => PositionData(
              position, bufferposition, duration ?? Duration.zero));

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
    _audioPlayer = AudioPlayer()..setUrl(tracks['items'][0]['preview_url']);
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
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 50,
              ),
              Image.network(data[1]['url']),
              const SizedBox(height: 10),
              StreamBuilder<PositionData>(
                stream: _positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  return ProgressBar(
                    progress: positionData?.position ?? Duration.zero,
                    buffered: positionData?.bufferPosition ?? Duration.zero,
                    total: positionData?.duration ?? Duration.zero,
                    onSeek: _audioPlayer.seek,
                  );
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Text(tracks['items'][0]['name'],
                  style: const TextStyle(fontSize: 25)),
              Text(artist[0]['name'], style: const TextStyle(fontSize: 20)),
              const SizedBox(
                height: 10,
              ),
              Controls(audioPlayer: _audioPlayer),
            ],
          ),
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
              onPressed: audioPlayer.pause,
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

class PositionData {
  final Duration position;
  final Duration bufferPosition;
  final Duration duration;
  const PositionData(this.position, this.bufferPosition, this.duration);
}
