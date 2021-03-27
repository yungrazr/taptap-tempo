import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapTapTempo',
      theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Poppins'),
      home: MyHomePage(title: 'TapTapTempo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //For bpm counter
  int _counter = 0;
  String _avg = '0';
  int _last = 0;
  int _now, _diff = 0;
  List<int> times = [];
  List<double> bpms = [];
  var timer;

  //For metronome
  var player;
  bool metronome = false;
  var metronomeTimer;
  int metronomeNote = 1;
  int first = 0, last = 0;
  int difference = 0;
  int delay = 0, delay2 = 0;
  var loop = false;
  int lastTimePlayedSound = 0;

  @override
  void initState() {
    super.initState();

    if (kIsWeb)
      player = new AudioPlayer();
    else
      player = new AudioCache(prefix: 'assets/metronome/');
  }

  void startTimeoutReset() {
    if (timer == null)
      timer = new Timer(const Duration(milliseconds: 2000), reset);
    else
      timer.cancel();
    timer = new Timer(const Duration(milliseconds: 2000), reset);
  }

  void reset() {
    times = [];
    bpms = [];
    _avg = '0';
    lastTimePlayedSound = 0;
    first = 0;
    last = 0;
    _diff = 0;
    metronomeNote = 1;
    if (metronomeTimer != null) {
      metronomeTimer.cancel();
    }
    setState(() {
      _last = 0;
      _counter = 0;
    });
  }

  void toggleMetronome() {
    reset();
    metronome = !metronome;
    if (metronome) {
      if (!kIsWeb) player.loadAll(['first.wav', 'last.wav']);
    } else {
      if (!kIsWeb) player.clearCache();
    }
  }

  void playMetronome(Timer timer) {
    if (DateTime.now().millisecondsSinceEpoch >=
        lastTimePlayedSound + (60000 / _counter - 1).round()) {
      lastTimePlayedSound = DateTime.now().millisecondsSinceEpoch;
      if (metronomeNote == 0) {
        if (kIsWeb)
          player.play('assets/metronome/first.wav', isLocal: true);
        else
          player.play('first.wav', mode: PlayerMode.LOW_LATENCY);
        metronomeNote++;
      } else {
        if (kIsWeb)
          player.play('assets/metronome/last.wav', isLocal: true);
        else
          player.play('last.wav', mode: PlayerMode.LOW_LATENCY);
        metronomeNote++;
      }
      if (metronomeNote > 3) {
        metronomeNote = 0;
      }
    }
  }

  void startTimeoutMetronome() {
    delay2 = DateTime.now().millisecondsSinceEpoch;
    var diff = delay2 - delay;
    if (metronomeTimer == null) {
      metronomeTimer = new Timer.periodic(
          Duration(milliseconds: ((60000 / _counter).round()) - diff),
          playMetronome);
      delay = delay2;
    } else {
      metronomeTimer.cancel();
      metronomeTimer = new Timer.periodic(
          Duration(milliseconds: ((60000 / _counter).round()) - diff),
          playMetronome);
      delay = delay2;
    }
  }

  void _incrementCounter() {
    if (_last == 0) {
      if (metronome) {
        if (kIsWeb)
          player.play('assets/metronome/first.wav', isLocal: true);
        else
          player.play('first.wav', mode: PlayerMode.LOW_LATENCY);
      } else {
        timer = new Timer(const Duration(milliseconds: 2000), reset);
      }
      _last = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _counter = 0;
      });
    } else {
      _now = DateTime.now().millisecondsSinceEpoch;
      _diff = _now - _last;
      _last = _now;
      times.add(_diff);
      double _bpm = 0;
      double _average = 0;

      if (times.length > 0) {
        _average = times.reduce((result, t) => result + t) / times.length;
        _bpm = ((60 / _average) * 1000);
        _avg = _bpm.toStringAsFixed(2);
        if (bpms.length > 0) {
          _bpm = (_bpm + bpms[bpms.length - 1]) / 2;
        }
        setState(() {
          _counter = _bpm.round();
        });
        bpms.add(_bpm);
      }
      if (times.length > 8) {
        times.remove(times[0]);
        bpms.remove(times[0]);
      }
      if (metronome == false) {
        startTimeoutReset();
      } else {
        startTimeoutMetronome();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool confirmBpm() {
      if (bpms.length > 5) {
        if (bpms[bpms.length - 1].round() == _counter &&
            bpms[bpms.length - 2].round() == _counter &&
            bpms[bpms.length - 3].round() == _counter &&
            bpms[bpms.length - 4].round() == _counter &&
            bpms[bpms.length - 5].round() == _counter) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    }

    void onEventKey(RawKeyEvent event) async {
      if (event.runtimeType == RawKeyUpEvent) {
        if (event.logicalKey == LogicalKeyboardKey.space) {
          _incrementCounter();
        }
      }
    }

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: onEventKey,
          autofocus: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: InkWell(
                    splashColor: Colors.teal,
                    highlightColor: null,
                    onTap: _incrementCounter,
                    onLongPress: reset,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: confirmBpm()
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors.teal,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(50))
                              : null,
                          child: Text(
                            '$_counter',
                            style: TextStyle(
                                fontSize: 120,
                                color: Colors.white,
                                fontWeight: FontWeight.w300),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Beats Per Minute',
                              style:
                                  TextStyle(fontSize: 42, color: Colors.white),
                              textAlign: TextAlign.center,
                            )),
                        Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              metronome
                                  ? 'Metronome mode \n Press spacebar or click screen to set tempo \n Press and hold to reset'
                                  : (_last == 0
                                      ? 'BPM mode \n Press spacebar or click screen to start \n Press and hold or wait 2 sec to reset'
                                      : '$_diff ms    avg: $_avg \n  \n'),
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                              textAlign: TextAlign.center,
                            )),
                      ],
                    ),
                  ))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: toggleMetronome,
          child: Icon(CupertinoIcons.metronome),
          backgroundColor: Colors.teal,
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: InkWell(
                    splashColor: Colors.teal,
                    highlightColor: null,
                    onTap: _incrementCounter,
                    onLongPress: reset,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: confirmBpm()
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors.teal,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(50))
                              : null,
                          child: Text(
                            '$_counter',
                            style: TextStyle(
                                fontSize: 120,
                                color: Colors.white,
                                fontWeight: FontWeight.w300),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Beats Per Minute',
                              style:
                                  TextStyle(fontSize: 42, color: Colors.white),
                              textAlign: TextAlign.center,
                            )),
                        Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              metronome
                                  ? 'Metronome mode \n Tap on the screen to set a tempo \n Press and hold to reset'
                                  : (_last == 0
                                      ? 'BPM mode \n Tap on the screen to start \n Press and hold or wait 2 sec to reset'
                                      : '$_diff ms    avg: $_avg \n  \n'),
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                              textAlign: TextAlign.center,
                            )),
                      ],
                    ),
                  ))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: toggleMetronome,
          child: Icon(CupertinoIcons.metronome),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }
}
