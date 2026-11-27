import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;

import '../combat/battle_session.dart';
import '../combat/combat_simulation.dart';
import '../mechanical/gear_network.dart';

class GearboundGame extends FlameGame {
  GearboundGame(this.session);

  final BattleSession session;
  WorkshopBoardView? _view;
  double _simulationRemainder = 0;
  double _uiNotifyRemainder = 0;
  BattlePhase _lastNotifiedPhase = BattlePhase.preparation;
  void Function()? onSessionChanged;

  /// Most simulated time one frame may catch up. Longer stalls (debugger,
  /// slow device) are dropped instead of fast-forwarding dozens of ticks.
  static const maxCatchUpSeconds = 0.25;

  /// Gameplay pause, separate from Flame's engine pause: the battlefield
  /// still renders, but the simulation does not advance. Only the player
  /// resumes it; returning from the background never resumes on its own.
  bool get simulationPaused => _simulationPaused;
  bool _simulationPaused = false;

  void setSimulationPaused(bool value) {
    if (_simulationPaused == value) return;
    _simulationPaused = value;
    if (value) _simulationRemainder = 0;
    onSessionChanged?.call();
  }

  /// Called by the screen when the app leaves the foreground. (Flame's own
  /// `lifecycleStateChange` also fires when its widget is disposed, for
  /// example on rotation, so it is not used for gameplay pausing.)
  void onAppBackgrounded() {
    if (session.phase == BattlePhase.combat) setSimulationPaused(true);
  }

  /// Board cell tapped during preparation (cell coordinates, not pixels).
  void Function(int x, int y)? onCellTap;
  ({int x, int y})? Function()? selectedCell;
  bool Function()? isPlacing;

  /// Drag on the board: start returns false to refuse (empty cell, core).
  bool Function(int x, int y)? onDragStartCell;
  void Function(int x, int y)? onDropCell;
  void Function()? onDragCancelled;

  /// Target-cell feedback while dragging: null = no preview, otherwise
  /// (valid, powered).
  ({bool valid, bool powered})? Function(int x, int y)? previewCell;

  @override
  Color backgroundColor() => const Color(0xFF202A30);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _view = WorkshopBoardView(session, this);
    await world.add(_view!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _view?.resizeTo(size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (session.phase == BattlePhase.combat && !_simulationPaused) {
      _simulationRemainder += dt;
      if (_simulationRemainder > maxCatchUpSeconds) {
        _simulationRemainder = maxCatchUpSeconds;
      }
      const step = 1 / 30;
      while (_simulationRemainder >= step &&
          session.phase == BattlePhase.combat) {
        session.tick();
        _simulationRemainder -= step;
      }
    }
    _uiNotifyRemainder += dt;
    if (session.phase != _lastNotifiedPhase || _uiNotifyRemainder >= 0.25) {
      _lastNotifiedPhase = session.phase;
      _uiNotifyRemainder = 0;
      onSessionChanged?.call();
    }
  }

  void refreshNetwork() {
    session.refreshNetwork();
  }

  bool startWave() => session.start();

  bool moveHeroToLane(int lane) => session.moveHeroToLane(lane);
}

class WorkshopBoardView extends PositionComponent
    with TapCallbacks, DragCallbacks {
  WorkshopBoardView(this.session, [this.game])
    : super(
        size: Vector2.zero(),
        anchor: Anchor.center,
        position: Vector2.zero(),
      );

  final BattleSession session;
  final GearboundGame? game;
  GearBoard get board => session.board;
  GearNetworkResult get network => session.network;
  bool _portrait = false;
  double _cell = 36;
  double _gridLeft = 0;
  double _gridTop = 0;

  void resizeTo(Vector2 canvasSize) {
    size = canvasSize;
    _portrait = canvasSize.y > canvasSize.x;
    if (_portrait) {
      _cell = math.min((canvasSize.x - 36) / 5, (canvasSize.y * 0.46 - 38) / 5);
      _gridLeft = (canvasSize.x - _cell * 5) / 2;
      _gridTop = canvasSize.y - _cell * 5 - 22;
    } else {
      _cell = math.min((canvasSize.y - 110) / 5, canvasSize.x * 0.08);
      _gridLeft = 24;
      _gridTop = (canvasSize.y - _cell * 5) / 2 + 18;
    }
    _cell = math.max(20, _cell);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    resizeTo(size);
  }

  /// Maps a point in this component's local space to a board cell.
  ({int x, int y})? cellAt(Vector2 local) {
    final x = ((local.x - _gridLeft) / _cell).floor();
    final y = ((local.y - _gridTop) / _cell).floor();
    if (x < 0 || y < 0 || x >= board.width || y >= board.height) return null;
    return (x: x, y: y);
  }

  @override
  void onTapUp(TapUpEvent event) {
    final cell = cellAt(event.localPosition);
    if (cell != null) game?.onCellTap?.call(cell.x, cell.y);
  }

  /// Pointer position of an accepted drag, in local coordinates.
  Vector2? dragPosition;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = cellAt(event.localPosition);
    final accepted =
        cell != null && (game?.onDragStartCell?.call(cell.x, cell.y) ?? false);
    dragPosition = accepted ? event.localPosition.clone() : null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // Accumulate deltas from the drag-start point. In Flame 1.38,
    // `localEndPosition` adds the delta to a position that already includes it,
    // so it runs ahead of the finger (found by the pointer-drag widget test).
    dragPosition?.add(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final position = dragPosition;
    dragPosition = null;
    if (position == null) return;
    final cell = cellAt(position);
    if (cell == null) {
      game?.onDragCancelled?.call();
    } else {
      game?.onDropCell?.call(cell.x, cell.y);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (dragPosition != null) game?.onDragCancelled?.call();
    dragPosition = null;
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint()..color = const ui.Color(0xFF263238),
    );
    _drawHeader(canvas);
    _drawBoard(canvas);
    _drawBattlefield(canvas);
  }

  void _drawHeader(ui.Canvas canvas) {
    final titleSize = _portrait ? 18.0 : 22.0;
    canvas.drawParagraph(
      _paragraph(
        'WAYFARER // POWER DECK',
        titleSize,
        0xFFFFE8C8,
        bold: true,
        width: size.x - 48,
      ),
      const ui.Offset(24, 18),
    );
    canvas.drawParagraph(
      _paragraph('GEAR LINK STATUS', 10, 0xFF8EAAA9, bold: true),
      const ui.Offset(26, 52),
    );
    final scrap = ui.Paint()..color = const ui.Color(0xFFFFA84A);
    canvas.drawCircle(ui.Offset(size.x - 72, 32), 6, scrap);
    canvas.drawCircle(ui.Offset(size.x - 52, 32), 6, scrap);
    canvas.drawCircle(ui.Offset(size.x - 32, 32), 6, scrap);
  }

  void _drawBoard(ui.Canvas canvas) {
    final cellPaint = ui.Paint()..color = const ui.Color(0xFF33434A);
    final gridPaint = ui.Paint()
      ..color = const ui.Color(0xFF53636A)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final coreGlow = ui.Paint()..color = const ui.Color(0x44FFC05B);
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        final rect = ui.Rect.fromLTWH(
          _gridLeft + x * _cell,
          _gridTop + y * _cell,
          _cell - 3,
          _cell - 3,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(7)),
          cellPaint,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(7)),
          gridPaint,
        );
        final node = board.at(x, y);
        final selected = game?.selectedCell?.call();
        final placing = game?.isPlacing?.call() ?? false;
        if ((selected != null && selected.x == x && selected.y == y) ||
            (placing && node == null)) {
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(7)),
            ui.Paint()
              ..color = placing
                  ? const ui.Color(0x669CDD74)
                  : const ui.Color(0xFFFFC05B)
              ..style = placing
                  ? ui.PaintingStyle.fill
                  : ui.PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
        if (node == null) continue;
        final result = network.nodes[node.id];
        final center = rect.center;
        final gearColor = switch (node.kind) {
          GearKind.core => const ui.Color(0xFFFFB447),
          GearKind.transmission => const ui.Color(0xFFB7C2C3),
          GearKind.booster => const ui.Color(0xFF9CDD74),
          GearKind.output => const ui.Color(0xFF65C5D9),
        };
        if (node.kind == GearKind.core) {
          canvas.drawCircle(center, _cell * 0.42, coreGlow);
        }
        canvas.drawCircle(center, _cell * 0.33, ui.Paint()..color = gearColor);
        canvas.drawCircle(
          center,
          _cell * 0.11,
          ui.Paint()..color = const ui.Color(0xFF263238),
        );
        for (var tooth = 0; tooth < 4; tooth++) {
          final angle = (tooth + node.rotationQuarterTurns) * math.pi / 2;
          final start =
              center +
              ui.Offset(
                math.cos(angle) * _cell * 0.17,
                math.sin(angle) * _cell * 0.17,
              );
          final end =
              center +
              ui.Offset(
                math.cos(angle) * _cell * 0.28,
                math.sin(angle) * _cell * 0.28,
              );
          canvas.drawLine(
            start,
            end,
            ui.Paint()
              ..color = const ui.Color(0xFF263238)
              ..strokeWidth = _cell * 0.07,
          );
        }
        final indicator = result?.state == NetworkState.powered
            ? const ui.Color(0xFF9CDD74)
            : result?.state == NetworkState.unpowered
            ? const ui.Color(0xFFE47A66)
            : const ui.Color(0xFFE9BA64);
        if (node.tier > 1) {
          canvas.drawParagraph(
            _paragraph('T${node.tier}', 9, 0xFFFFE8C8, bold: true),
            ui.Offset(rect.left + 3, rect.bottom - 13),
          );
        }
        canvas.drawCircle(
          center.translate(_cell * 0.27, -_cell * 0.27),
          math.max(2, _cell * 0.06),
          ui.Paint()..color = indicator,
        );
      }
    }
    final connected = ui.Paint()
      ..color = const ui.Color(0xFF8DD5A6)
      ..strokeWidth = math.max(2.5, _cell * 0.08)
      ..strokeCap = ui.StrokeCap.round;
    for (final (aId, bId) in network.edges) {
      final a = board.nodes.firstWhere((node) => node.id == aId);
      final b = board.nodes.firstWhere((node) => node.id == bId);
      if (network.nodes[aId]?.state != NetworkState.powered) continue;
      final ac = ui.Offset(
        _gridLeft + a.x * _cell + (_cell - 3) / 2,
        _gridTop + a.y * _cell + (_cell - 3) / 2,
      );
      final bc = ui.Offset(
        _gridLeft + b.x * _cell + (_cell - 3) / 2,
        _gridTop + b.y * _cell + (_cell - 3) / 2,
      );
      canvas.drawLine(ac, bc, connected);
    }
    _drawDragFeedback(canvas);
    final labelTop = _gridTop + _cell * 5 + 3;
    canvas.drawParagraph(
      _paragraph('5 × 5 MECHANICAL GRID', 9, 0xFF8EAAA9, bold: true),
      ui.Offset(_gridLeft, labelTop),
    );
  }

  void _drawDragFeedback(ui.Canvas canvas) {
    final position = dragPosition;
    if (position == null) return;
    final cell = cellAt(position);
    if (cell != null) {
      final preview = game?.previewCell?.call(cell.x, cell.y);
      if (preview != null) {
        final color = !preview.valid
            ? const ui.Color(0x99E47A66)
            : preview.powered
            ? const ui.Color(0x889CDD74)
            : const ui.Color(0x88E9BA64);
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(
              _gridLeft + cell.x * _cell,
              _gridTop + cell.y * _cell,
              _cell - 3,
              _cell - 3,
            ),
            const ui.Radius.circular(7),
          ),
          ui.Paint()..color = color,
        );
      }
    }
    // Ghost gear under the finger.
    canvas.drawCircle(
      position.toOffset(),
      _cell * 0.33,
      ui.Paint()..color = const ui.Color(0xAAFFE8C8),
    );
  }

  void _drawBattlefield(ui.Canvas canvas) {
    late final ui.Rect panelRect;
    late final double laneTop;
    late final double laneSpacing;
    if (_portrait) {
      final panelTop = 78.0;
      final panelHeight = size.y * 0.34;
      panelRect = ui.Rect.fromLTWH(18, panelTop, size.x - 36, panelHeight);
      laneTop = panelTop + panelHeight * 0.33;
      laneSpacing = panelHeight * 0.23;
    } else {
      final panelLeft = _gridLeft + _cell * 5 + 28;
      panelRect = ui.Rect.fromLTWH(
        panelLeft,
        78,
        size.x - panelLeft - 18,
        size.y - 98,
      );
      laneTop = panelRect.top + 74;
      laneSpacing = (panelRect.height - 112) / 2;
    }
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(panelRect, const ui.Radius.circular(16)),
      ui.Paint()..color = const ui.Color(0xFF1D262B),
    );
    canvas.drawParagraph(
      _paragraph(
        'COPPERWASH PASS',
        12,
        0xFFFFE8C8,
        bold: true,
        width: panelRect.width - 24,
      ),
      ui.Offset(panelRect.left + 16, panelRect.top + 12),
    );
    final laneLine = ui.Paint()
      ..color = const ui.Color(0xFF40525A)
      ..strokeWidth = 2;
    for (var lane = 0; lane < 3; lane++) {
      final y = laneTop + lane * laneSpacing;
      final left = panelRect.left + 14;
      final right = panelRect.right - 14;
      canvas.drawLine(ui.Offset(left, y), ui.Offset(right, y), laneLine);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(left - 1, y - 18, 8, 36),
          const ui.Radius.circular(3),
        ),
        ui.Paint()..color = const ui.Color(0xFF4AABB3),
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(right - 7, y - 18, 8, 36),
          const ui.Radius.circular(3),
        ),
        ui.Paint()..color = const ui.Color(0xFFD16A50),
      );
    }
    final battleWidth = panelRect.width - 32;
    final radius = math.max(6.0, math.min(12.0, laneSpacing * 0.16));
    for (final unit in session.combat.combatants.where(
      (unit) => unit.isAlive,
    )) {
      final progress = (unit.positionMm / session.combat.worldLengthMm).clamp(
        0.0,
        1.0,
      );
      final x = panelRect.left + 16 + battleWidth * progress;
      final y = laneTop + unit.lane * laneSpacing - radius;
      final isHero = unit.id == session.heroId;
      final color = unit.faction == CombatFaction.enemy
          ? const ui.Color(0xFFD96E52)
          : isHero
          ? const ui.Color(0xFFFFB447)
          : const ui.Color(0xFF62C5D0);
      canvas.drawCircle(
        ui.Offset(x, y),
        radius + 2,
        ui.Paint()..color = const ui.Color(0x33202A30),
      );
      canvas.drawCircle(ui.Offset(x, y), radius, ui.Paint()..color = color);
      canvas.drawCircle(
        ui.Offset(x + radius * 0.22, y - radius * 0.1),
        radius * 0.13,
        ui.Paint()..color = const ui.Color(0xFF202A30),
      );
      final barWidth = radius * 2.5;
      final barRect = ui.Rect.fromLTWH(
        x - barWidth / 2,
        y + radius + 3,
        barWidth,
        3,
      );
      canvas.drawRect(barRect, ui.Paint()..color = const ui.Color(0xFF111719));
      canvas.drawRect(
        barRect.topLeft &
            ui.Size(barWidth * unit.health / unit.maxHealth, barRect.height),
        ui.Paint()..color = const ui.Color(0xFF9CDD74),
      );
    }
    final footerY = panelRect.bottom - 20;
    final phaseText = switch (session.phase) {
      BattlePhase.preparation => 'WAVE 1/${session.waves.length} · READY',
      BattlePhase.combat =>
        'WAVE ${session.waveIndex + 1}/${session.waves.length} · TICK ${session.elapsedTicks}',
      BattlePhase.intermission =>
        'WAVE ${session.waveIndex + 1} CLEAR · +${session.lastWaveReward} SCRAP · REBUILD',
      BattlePhase.victory => 'MISSION CLEAR · +${session.scrapReward} SCRAP',
      BattlePhase.defeat => 'WAYFARER DISABLED',
    };
    canvas.drawParagraph(
      _paragraph(
        phaseText,
        9,
        0xFFB3E1D7,
        bold: true,
        width: panelRect.width - 28,
      ),
      ui.Offset(panelRect.left + 14, footerY),
    );
  }

  ui.Paragraph _paragraph(
    String value,
    double fontSize,
    int color, {
    bool bold = false,
    double width = 380,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: fontSize,
              fontFamily: 'sans-serif',
              fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
            ),
          )
          ..pushStyle(ui.TextStyle(color: ui.Color(color)))
          ..addText(value);
    return builder.build()..layout(ui.ParagraphConstraints(width: width));
  }
}
