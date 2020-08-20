import 'dart:async';
import 'dart:convert';

import 'package:films_app/src/models/actores_model.dart';
import 'package:http/http.dart' as http;

import 'package:films_app/src/models/pelicula_model.dart';

class PeliculasProvider {
  String _apiKey = 'f5cc953612402ed192276b49d407bd8a';
  String _url = 'api.themoviedb.org';
  String _language = 'es-ES';

  int _popularesPage = 0;
  bool _cargando = false;

  List<Pelicula> _populares = new List();

  // Stream: list of peliculas flows through the stream. Broadcast to have many
  // places where the stream can be listened
  final _popularesStreamController =
      StreamController<List<Pelicula>>.broadcast();

  // To insert data into the stream
  Function(List<Pelicula>) get popularesSink =>
      _popularesStreamController.sink.add;

  // To get data from the stream
  Stream<List<Pelicula>> get popularesStream =>
      _popularesStreamController.stream;

  // It is necessary to close the streams manually
  void disposeStreams() {
    _popularesStreamController?.close();
  }

  Future<List<Pelicula>> _processarRespuesta(Uri url) async {
    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final peliculas = new Peliculas.fromJsonList(decodedData['results']);

    return peliculas.items;
  }

  Future<List<Pelicula>> getEnCines() async {
    final url = Uri.https(_url, '3/movie/now_playing',
        {'api_key': _apiKey, 'language': _language});

    return _processarRespuesta(url);
  }

  Future<List<Pelicula>> getPopulares() async {
    if (_cargando) return [];
    _cargando = true;
    _popularesPage++;

    final url = Uri.https(_url, '3/movie/popular', {
      'api_key': _apiKey,
      'language': _language,
      'page': _popularesPage.toString()
    });

    final resp = await _processarRespuesta(url);

    // Adds info to the stream
    _populares.addAll(resp);
    popularesSink(_populares);

    _cargando = false;
    return resp;
  }

  Future<List<Actor>> getCast(String peliId) async {
    final url = Uri.https(_url, '3/movie/$peliId/credits', {
      'api_key': _apiKey,
      'language': _language,
    });

    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final cast = new Cast.fromJsonList(decodedData['cast']);

    return cast.actores;
  }

  Future<List<Pelicula>> buscarPelicula(String query) async {
    final url = Uri.https(_url, '3/search/movie',
        {'api_key': _apiKey, 'language': _language, 'query': query});

    return _processarRespuesta(url);
  }
}
