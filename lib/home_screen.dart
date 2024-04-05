import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:unustasis/control_screen.dart';
import 'package:unustasis/scooter_service.dart';
import 'package:unustasis/scooter_state.dart';
import 'package:unustasis/scooter_visual.dart';

class HomeScreen extends StatefulWidget {
  final ScooterService scooterService;
  const HomeScreen({required this.scooterService, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScooterState _scooterState = ScooterState.disconnected;
  bool _connected = false;
  bool _scanning = false;
  bool _seatClosed = true;
  bool _handlebarsLocked = true;
  int _primarySOC = 100;
  int _secondarySOC = 100;

  @override
  void initState() {
    super.initState();
    widget.scooterService.state.listen((state) {
      setState(() {
        _scooterState = state;
      });
    });
    widget.scooterService.connected.listen((isConnected) {
      setState(() {
        _connected = isConnected;
      });
    });
    widget.scooterService.scanning.listen((isScanning) {
      setState(() {
        _scanning = isScanning;
      });
      log("Scanning: $isScanning");
    });
    widget.scooterService.seatClosed.listen((isClosed) {
      setState(() {
        _seatClosed = isClosed;
      });
    });
    widget.scooterService.handlebarsLocked.listen((isLocked) {
      setState(() {
        _handlebarsLocked = isLocked;
      });
    });
    widget.scooterService.primarySOC.listen((soc) {
      setState(() {
        _primarySOC = soc;
      });
    });
    widget.scooterService.secondarySOC.listen((soc) {
      setState(() {
        _secondarySOC = soc;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black,
              _scooterState.isOn
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : _connected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  "Scooter Pro",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  _scanning
                      ? "Scanning..."
                      : (_scooterState.name +
                          (_connected && !_handlebarsLocked
                              ? " - Unlocked"
                              : "")),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width / 6,
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          value: _primarySOC / 100.0,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                    const SizedBox(width: 8),
                    Text("$_primarySOC%"),
                    _secondarySOC > 0 ? const VerticalDivider() : Container(),
                    _secondarySOC > 0
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width / 6,
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              value: _secondarySOC / 100.0,
                              color: Theme.of(context).colorScheme.primary,
                            ))
                        : Container(),
                    _secondarySOC > 0 ? const SizedBox(width: 8) : Container(),
                    _secondarySOC > 0 ? Text("$_secondarySOC%") : Container(),
                  ],
                ),
                Expanded(
                    child: ScooterVisual(
                  state: _scooterState,
                  scanning: _scanning,
                )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ScooterActionButton(
                      onPressed: _connected && _scooterState.isOn && _seatClosed
                          ? widget.scooterService.openSeat
                          : null,
                      label: _seatClosed ? "Open seat" : "Seat is open!",
                      icon: Icons.work_outline,
                      iconColor: !_seatClosed
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    ScooterPowerButton(
                        action: _connected
                            ? (_scooterState.isOn
                                ? () {
                                    if (!_seatClosed) {
                                      showSeatWarning();
                                    } else {
                                      widget.scooterService.lock();
                                    }
                                  }
                                : widget.scooterService.unlock)
                            : null,
                        icon: _scooterState.isOn
                            ? Icons.lock_open
                            : Icons.lock_outline,
                        label: _scooterState.isOn
                            ? "Hold to lock"
                            : "Hold to unlock"),
                    ScooterActionButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ControlScreen(
                                      scooterService: widget.scooterService)));
                        },
                        icon: Icons.more_vert,
                        label: "Controls"),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showSeatWarning() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seat is open!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "For safety reasons, the scooter can't be locked while the seat is open."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Route _createControlRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ControlScreen(
        scooterService: widget.scooterService,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

class ScooterPowerButton extends StatefulWidget {
  const ScooterPowerButton({
    super.key,
    required void Function()? action,
    Widget? child,
    required IconData icon,
    required String label,
  })  : _action = action,
        _icon = icon,
        _label = label;

  final void Function()? _action;
  final String _label;
  final IconData _icon;

  @override
  State<ScooterPowerButton> createState() => _ScooterPowerButtonState();
}

class _ScooterPowerButtonState extends State<ScooterPowerButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    Color mainColor = widget._action == null
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2)
        : Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            backgroundColor: mainColor,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(widget._label)));
          },
          onLongPress: widget._action == null
              ? null
              : () {
                  setState(() {
                    loading = true;
                  });
                  widget._action!();
                  Future.delayed(const Duration(seconds: 5), () {
                    setState(() {
                      loading = false;
                    });
                  });
                },
          child: loading
              ? CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.background,
                )
              : Icon(
                  widget._icon,
                  color: Theme.of(context).colorScheme.background,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          widget._label,
          style: TextStyle(
            color: mainColor,
          ),
        ),
      ],
    );
  }
}

class ScooterActionButton extends StatelessWidget {
  const ScooterActionButton({
    super.key,
    required void Function()? onPressed,
    required IconData icon,
    Color? iconColor,
    required String label,
  })  : _onPressed = onPressed,
        _icon = icon,
        _iconColor = iconColor,
        _label = label;

  final void Function()? _onPressed;
  final IconData _icon;
  final String _label;
  final Color? _iconColor;

  @override
  Widget build(BuildContext context) {
    Color mainColor = _iconColor ??
        (_onPressed == null
            ? Theme.of(context).colorScheme.onBackground.withOpacity(0.2)
            : Theme.of(context).colorScheme.onBackground);
    return Column(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(24),
            side: BorderSide(
              color: mainColor,
            ),
          ),
          onPressed: _onPressed,
          child: Icon(
            _icon,
            color: mainColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _label,
          style: TextStyle(
            color: mainColor,
          ),
        ),
      ],
    );
  }
}