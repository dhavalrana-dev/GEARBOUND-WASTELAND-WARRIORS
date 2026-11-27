using System;
using Gearbound.Core;

internal static class GearNetworkSmoke
{
    private static readonly Direction[] AllPorts = { Direction.North, Direction.East, Direction.South, Direction.West };
    private static int passed;

    private static GearNode Gear(string id, GearKind kind, int x, int y, int interval = 0) =>
        new GearNode(id, kind, x, y, AllPorts, interval);

    private static void Check(string name, Action action)
    {
        action();
        passed++;
        Console.WriteLine("PASS " + name);
    }

    private static void Require(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
    }

    public static int Main()
    {
        Check("powered chain and alternating rotation", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("shaft", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(Gear("press", GearKind.Output, 2, 0, 90), out _);
            var result = GearNetwork.Rebuild(board);
            Require(result.Nodes["press"].State == NetworkState.Powered, "Output is not powered.");
            Require(result.Nodes["shaft"].RotationParity == 1 && result.Nodes["press"].RotationParity == 0, "Rotation parity did not alternate.");
        });
        Check("disconnected output remains inactive", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("press", GearKind.Output, 4, 4, 90), out _);
            Require(GearNetwork.Rebuild(board).Nodes["press"].State == NetworkState.Unpowered, "Disconnected output is powered.");
        });
        Check("MVP board enforces a single core", () =>
        {
            var board = new GearBoard();
            Require(board.TryPlace(Gear("core-a", GearKind.Core, 0, 0), out _), "First core was rejected.");
            Require(!board.TryPlace(Gear("core-b", GearKind.Core, 4, 4), out _), "Second core exceeded the configured cap.");
        });
        Check("removing a coupler cuts downstream power", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("shaft", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(Gear("press", GearKind.Output, 2, 0, 90), out _);
            board.RemoveAt(1, 0);
            Require(GearNetwork.Rebuild(board).Nodes["press"].State == NetworkState.Unpowered, "Output stayed powered.");
        });
        Check("booster contribution is capped", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("b1", GearKind.Booster, 1, 0), out _);
            board.TryPlace(Gear("b2", GearKind.Booster, 2, 0), out _);
            board.TryPlace(Gear("b3", GearKind.Booster, 3, 0), out _);
            board.TryPlace(Gear("b4", GearKind.Booster, 4, 0), out _);
            board.TryPlace(Gear("press", GearKind.Output, 4, 1, 90), out _);
            var result = GearNetwork.Rebuild(board).Nodes["press"];
            Require(result.BoosterBonusPercent == 30 && result.EffectiveIntervalTicks == 70, "Boost cap/interval was unexpected.");
        });
        Check("even loop is consistent and two-core network conflicts", () =>
        {
            var loop = new GearBoard();
            loop.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            loop.TryPlace(Gear("e", GearKind.Transmission, 1, 0), out _);
            loop.TryPlace(Gear("s", GearKind.Transmission, 0, 1), out _);
            loop.TryPlace(Gear("corner", GearKind.Transmission, 1, 1), out _);
            Require(GearNetwork.Rebuild(loop).Nodes["corner"].State == NetworkState.Powered, "Even loop was jammed.");
            var conflict = new GearBoard(maxCores: 2);
            conflict.TryPlace(Gear("core-a", GearKind.Core, 0, 0), out _);
            conflict.TryPlace(Gear("core-b", GearKind.Core, 1, 0), out _);
            conflict.TryPlace(Gear("press", GearKind.Output, 2, 0, 90), out _);
            Require(GearNetwork.Rebuild(conflict).Nodes["press"].State == NetworkState.Conflicted, "Two-core component was not disabled.");
        });
        Check("merge uses row-major cell and configured tier output", () =>
        {
            var board = new GearBoard();
            board.TryPlace(new GearNode("press-a", GearKind.Output, 2, 1, AllPorts, 90, 0, "unit.press", 1), out _);
            board.TryPlace(new GearNode("press-b", GearKind.Output, 1, 0, AllPorts, 90, 0, "unit.press", 1), out _);
            Require(board.TryMerge(2, 1, 1, 0, 3, 60, out var merged, out var error), error ?? "Merge failed.");
            Require(merged.X == 1 && merged.Y == 0 && merged.Tier == 2 && merged.BaseIntervalTicks == 60, "Merged gear data is wrong.");
        });
        Check("lane separation and stable movement", () =>
        {
            var simulation = new CombatSimulation(worldLengthMm: 1000);
            var friendly = new Combatant(1, CombatFaction.Friendly, 0, 0, 20, 0, 5, 20, 100, 10);
            var enemy = new Combatant(2, CombatFaction.Enemy, 1, 1000, 20, 0, 5, 20, 100, 10);
            simulation.Add(friendly);
            simulation.Add(enemy);
            simulation.Tick();
            Require(friendly.PositionMm == 100 && enemy.PositionMm == 900, "Movement did not use the fixed tick step.");
            Require(friendly.Health == 20 && enemy.Health == 20, "Units in different lanes attacked each other.");
        });
        Check("damage resolves armor, reduction and shield in order", () =>
        {
            var simulation = new CombatSimulation();
            var attacker = new Combatant(1, CombatFaction.Friendly, 1, 1000, 100, 0, 11, 100, 0, 10);
            var defender = new Combatant(2, CombatFaction.Enemy, 1, 1050, 20, 2, 1, 0, 0, 10, shield: 2, damageReductionPercent: 25);
            simulation.Add(attacker);
            simulation.Add(defender);
            simulation.Tick();
            Require(defender.Shield == 0 && defender.Health == 16, "Damage formula produced an unexpected result.");
        });
        Check("mutual knockout resolves both scheduled hits", () =>
        {
            var simulation = new CombatSimulation();
            var friendly = new Combatant(1, CombatFaction.Friendly, 0, 1000, 5, 0, 5, 0, 0, 1);
            var enemy = new Combatant(2, CombatFaction.Enemy, 0, 1000, 5, 0, 5, 0, 0, 1);
            simulation.Add(friendly);
            simulation.Add(enemy);
            simulation.Tick();
            Require(friendly.State == CombatState.Dead && enemy.State == CombatState.Dead, "Same-tick mutual knockout was not resolved.");
        });
        Check("fortress defeat halts later simulation ticks", () =>
        {
            var simulation = new CombatSimulation(fortressHealth: 10);
            simulation.Add(new Combatant(1, CombatFaction.Enemy, 2, 0, 20, 0, 10, 0, 0, 1));
            simulation.Tick();
            simulation.Tick();
            Require(simulation.IsDefeated && simulation.FortressHealth == 0 && simulation.TickIndex == 1, "Fortress defeat did not halt the simulation.");
        });
        Check("powered infantry output emits bounded unit spawns", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("drive", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(new GearNode("press", GearKind.Output, 2, 0, AllPorts, 3, outputKind: GearOutputKind.SpawnInfantry), out _);
            var network = GearNetwork.Rebuild(board);
            var combat = new CombatSimulation();
            var outputs = new GearOutputSystem();
            for (var tick = 0; tick < 9; tick++) outputs.Tick(board, network, combat);
            Require(combat.Combatants.Count == 3, "Output cadence did not spawn the expected unit count.");
            Require(outputs.Clocks["press"].ProgressTicks == 0 && outputs.Clocks["press"].Status == GearOutputStatus.Produced, "Output clock state was not reset after spawning.");
        });
        Check("unit cap queues one spawn and prevents excess units", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("drive", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(new GearNode("press", GearKind.Output, 2, 0, AllPorts, 1, outputKind: GearOutputKind.SpawnInfantry), out _);
            var combat = new CombatSimulation();
            combat.Add(new Combatant(5, CombatFaction.Friendly, 1, 0, 30, 0, 1, 0, 0, 1));
            var outputs = new GearOutputSystem(unitCapPerLane: 1);
            outputs.Tick(board, GearNetwork.Rebuild(board), combat);
            Require(combat.Combatants.Count == 1 && outputs.Clocks["press"].PendingSpawn, "Unit cap did not hold a single pending spawn.");
        });
        Check("disconnect pauses gear production while existing units persist", () =>
        {
            var board = new GearBoard();
            board.TryPlace(Gear("core", GearKind.Core, 0, 0), out _);
            board.TryPlace(Gear("drive", GearKind.Transmission, 1, 0), out _);
            board.TryPlace(new GearNode("press", GearKind.Output, 2, 0, AllPorts, 3, outputKind: GearOutputKind.SpawnInfantry), out _);
            var combat = new CombatSimulation();
            var outputs = new GearOutputSystem();
            var network = GearNetwork.Rebuild(board);
            for (var tick = 0; tick < 3; tick++) outputs.Tick(board, network, combat);
            board.RemoveAt(1, 0);
            network = GearNetwork.Rebuild(board);
            outputs.Tick(board, network, combat);
            Require(combat.Combatants.Count == 1 && outputs.Clocks["press"].Status == GearOutputStatus.Inactive, "Disconnect did not pause further production.");
        });
        Check("wave session waits for scheduled spawns and resolves victory", () =>
        {
            var board = new GearBoard();
            var combat = new CombatSimulation(worldLengthMm: 1000);
            combat.Add(new Combatant(1, CombatFaction.Friendly, 1, 0, 100, 0, 50, 1000, 0, 1));
            var wave = new WaveDefinition("test.wave", new[] { new WaveSpawnEvent(2, 1, 10, 0, 1, 0, 0, 1) }, 4);
            var session = new BattleSession(board, GearNetwork.Rebuild(board), wave, combat: combat);
            session.Start();
            session.Tick();
            Require(session.Phase == BattlePhase.Combat, "Wave ended before its scheduled enemy.");
            session.Tick();
            session.Tick();
            Require(session.Phase == BattlePhase.Victory && session.ScrapReward == 4, "Wave did not resolve victory and reward.");
        });
        Check("wave defeat and hero lane command are represented", () =>
        {
            var board = new GearBoard();
            var combat = new CombatSimulation(fortressHealth: 5);
            var wave = new WaveDefinition("test.defeat", new[] { new WaveSpawnEvent(0, 0, 10, 0, 5, 0, 20000, 1) });
            var session = new BattleSession(board, GearNetwork.Rebuild(board), wave, combat: combat);
            Require(session.MoveHeroToLane(2), "Hero lane command was rejected.");
            session.Start();
            session.Tick();
            Require(session.Phase == BattlePhase.Defeat, "Fortress loss did not end the wave.");
        });
        Console.WriteLine("RESULT " + passed + " checks passed.");
        return 0;
    }
}
