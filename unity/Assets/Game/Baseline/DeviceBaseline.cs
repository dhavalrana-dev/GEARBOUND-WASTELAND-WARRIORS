using System;
using System.Collections.Generic;
using System.Linq;
using Gearbound.Core;
using Gearbound.Workshop;

namespace Gearbound.Baseline
{
    /// <summary>Outcome of one baseline run: how many checks ran and which ones failed.</summary>
    public sealed class BaselineResult
    {
        public int Checks { get; internal set; }
        public int CombatTraces { get; internal set; }
        public int WorkshopCases { get; internal set; }
        public List<string> Failures { get; } = new List<string>();
        public bool Passed => Failures.Count == 0 && Checks > 0;

        public string Summary => Passed
            ? $"UNITY DEVICE BASELINE OK: {Checks} checks, {CombatTraces} combat traces, {WorkshopCases} workshop cases"
            : $"UNITY DEVICE BASELINE FAILED: {Failures.Count} of {Checks} checks\n" + string.Join("\n", Failures);
    }

    /// <summary>
    /// Replays the shared fixtures through the C# rules, the same set flutter/tool/baseline_check.dart
    /// replays in Dart: random vectors, shop rolls, the mission_001 schedule, every combat trace with
    /// its checkpoints, and every workshop case step by step. Engine-free, so it runs in EditMode tests
    /// and in a player build (IL2CPP on Android) from the same code.
    /// </summary>
    public static class DeviceBaseline
    {
        /// <summary>Every shared file the baseline reads, relative to shared/.</summary>
        public static readonly string[] Files =
        {
            "test-fixtures/random_vectors.json", "test-fixtures/shop_cases.json", "test-fixtures/mission_001_spawns.json",
            "test-fixtures/combat_scenarios.json", "test-fixtures/combat_traces.json", "test-fixtures/workshop_cases.json",
            "gears/starter_gears.json", "economy/shop.json", "configs/gear_rules.json", "waves/mission_001.json", "enemies/enemies.json",
        };

        public static BaselineResult Run(Func<string, string> read)
        {
            var result = new BaselineResult();
            Step(result, "random vectors", () => RandomVectors(read, result));
            Step(result, "shop rolls", () => ShopRolls(read, result));
            Step(result, "mission_001 schedule", () => Schedule(read, result));
            Step(result, "combat traces", () => CombatTraces(read, result));
            Step(result, "workshop cases", () => WorkshopCases(read, result));
            return result;
        }

        private static void Step(BaselineResult result, string name, Action body)
        {
            try { body(); }
            catch (Exception e) { result.Checks++; result.Failures.Add($"{name}: {e.GetType().Name}: {e.Message}"); }
        }

        private static void Check(BaselineResult result, bool ok, string what)
        {
            result.Checks++;
            if (!ok) result.Failures.Add(what);
        }

        private static Dictionary<string, object> Fixture(Func<string, string> read, string name) =>
            SharedJson.Obj(SharedJson.Parse(read("test-fixtures/" + name)), name);

        private static void RandomVectors(Func<string, string> read, BaselineResult result)
        {
            var fixture = Fixture(read, "random_vectors.json");
            foreach (var item in SharedJson.Arr(fixture, "nextUintCases"))
            {
                var c = SharedJson.Obj(item, "case");
                var rng = new SeededRandom((uint)SharedJson.Long(c, "seed"));
                var expected = SharedJson.Arr(c, "nextUint").Select(v => (uint)(long)v).ToArray();
                var actual = expected.Select(_ => rng.NextUint()).ToArray();
                Check(result, expected.SequenceEqual(actual), "random seed " + c["seed"]);
            }
            var intCase = SharedJson.Obj(fixture["nextIntCase"], "nextIntCase");
            var r = new SeededRandom((uint)SharedJson.Long(intCase, "seed"));
            var ints = SharedJson.Arr(intCase, "bounds").Select(b => r.NextInt((int)(long)b)).ToArray();
            Check(result, SharedJson.Arr(intCase, "results").Select(v => (int)(long)v).SequenceEqual(ints) && r.Draws == ints.Length, "random nextInt");
        }

        private static void ShopRolls(Func<string, string> read, BaselineResult result)
        {
            var catalog = SharedDataLoader.LoadGears(read("gears/starter_gears.json"));
            var config = SharedDataLoader.LoadShop(read("economy/shop.json"));
            var fixture = Fixture(read, "shop_cases.json");
            var costs = SharedJson.Arr(fixture, "rerollCosts").Select(v => (int)(long)v).ToArray();
            Check(result, costs.SequenceEqual(Enumerable.Range(0, costs.Length).Select(k => GearShop.RerollCost(config, k))), "shop reroll costs");
            foreach (var item in SharedJson.Arr(fixture, "cases"))
            {
                var c = SharedJson.Obj(item, "case");
                var rng = new SeededRandom((uint)SharedJson.Long(c, "seed"));
                var unlocked = c["unlocked"] is List<object> u ? new HashSet<string>(u.Cast<string>()) : null;
                var locked = c["locked"] is List<object> l ? l.Select(o => o as string).ToArray() : null;
                var boardHas = SharedJson.Bool(c, "boardHasGuaranteedCategory");
                var ok = true;
                foreach (var expectedRoll in SharedJson.Arr(c, "expectedOffers"))
                {
                    var expected = ((List<object>)expectedRoll).Select(o => o as string).ToArray();
                    ok &= expected.SequenceEqual(GearShop.Roll(rng, catalog, config, unlocked, locked, boardHas));
                }
                Check(result, ok, "shop case " + SharedJson.Str(c, "id"));
            }
        }

        private static void Schedule(Func<string, string> read, BaselineResult result)
        {
            var mission = SharedDataLoader.LoadMission(read("waves/mission_001.json"));
            var waves = SharedJson.Arr(Fixture(read, "mission_001_spawns.json"), "waves");
            Check(result, waves.Count == mission.Waves.Count, "mission_001 wave count");
            for (var w = 0; w < Math.Min(waves.Count, mission.Waves.Count); w++)
            {
                var expected = SharedJson.Arr(SharedJson.Obj(waves[w], "wave"), "spawns").Select(s =>
                {
                    var spawn = SharedJson.Obj(s, "spawn");
                    return $"{SharedJson.Int(spawn, "tick")}:{SharedJson.Int(spawn, "lane")}:{SharedJson.Str(spawn, "enemyId")}";
                });
                var actual = WaveDirector.Schedule(mission.Waves[w]).Select(s => $"{s.Tick}:{s.Lane}:{s.EnemyId}");
                Check(result, expected.SequenceEqual(actual), "mission_001 " + mission.Waves[w].Id);
            }
        }

        private static void CombatTraces(Func<string, string> read, BaselineResult result)
        {
            var results = CombatScenarioRunner.RunAll(read("test-fixtures/combat_scenarios.json"), read("waves/mission_001.json"), read("enemies/enemies.json"));
            var expected = SharedJson.Arr(Fixture(read, "combat_traces.json"), "results").Select(r => SharedJson.Obj(r, "result")).ToArray();
            Check(result, expected.Length == results.Count, "combat trace count");
            for (var i = 0; i < Math.Min(expected.Length, results.Count); i++)
            {
                var e = expected[i];
                var r = results[i];
                var ok = SharedJson.Str(e, "id") == r.Id && SharedJson.Str(e, "phase") == r.Phase
                    && SharedJson.Int(e, "elapsedTicks") == r.ElapsedTicks && SharedJson.Int(e, "fortressHealth") == r.FortressHealth
                    && SharedJson.Int(e, "friendlyUnitsProduced") == r.FriendlyUnitsProduced && SharedJson.Int(e, "friendlyAlive") == r.FriendlyAlive
                    && SharedJson.Int(e, "enemiesAlive") == r.EnemiesAlive && (uint)SharedJson.Long(e, "traceHash") == r.TraceHash
                    && SharedJson.Arr(e, "checkpoints").Select(v => (uint)(long)v).SequenceEqual(r.Checkpoints);
                Check(result, ok, "combat trace " + r.Id);
                result.CombatTraces++;
            }
        }

        private static void WorkshopCases(Func<string, string> read, BaselineResult result)
        {
            var fixture = Fixture(read, "workshop_cases.json");
            foreach (var item in SharedJson.Arr(fixture, "mixSeed32"))
            {
                var v = SharedJson.Obj(item, "vector");
                Check(result, (uint)SharedJson.Long(v, "mixed") == SeededRandom.MixSeed32((uint)SharedJson.Long(v, "seed")), "mixSeed32 " + v["seed"]);
            }
            var gears = SharedDataLoader.LoadGears(read("gears/starter_gears.json"));
            var shop = SharedDataLoader.LoadShop(read("economy/shop.json"));
            var rules = WorkshopRules.Load(read("configs/gear_rules.json"));
            foreach (var item in SharedJson.Arr(fixture, "cases"))
            {
                var c = SharedJson.Obj(item, "case");
                var id = SharedJson.Str(c, "id");
                var w = new WorkshopController(new GearBoard(), gears, shop, rules, (uint)SharedJson.Long(c, "seed"),
                    () => new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc));
                var ops = SharedJson.Arr(c, "ops");
                var steps = SharedJson.Arr(c, "steps");
                string failure = null;
                if (ops.Count + 1 != steps.Count) failure = "step count";
                else if (Expected(SharedJson.Obj(steps[0], "step")) != Snapshot(w, "start")) failure = "start";
                for (var i = 0; failure == null && i < ops.Count; i++)
                {
                    var op = SharedJson.Obj(ops[i], "op");
                    var step = SharedJson.Obj(steps[i + 1], "step");
                    string opResult;
                    if ((string)op["op"] == "checkpoint")
                    {
                        var dart = SharedJson.Obj(step["checkpoint"], "checkpoint");
                        if (!JsonEquals(dart, SharedJson.Parse(SharedJson.Write(w.ToJson())))) { failure = "step " + (i + 1) + " checkpoint"; break; }
                        w = WorkshopController.Restore(w.Board, gears, shop, rules, dart, () => new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc));
                        opResult = "checkpoint";
                    }
                    else opResult = Apply(w, op);
                    if (Expected(step) != Snapshot(w, opResult)) failure = "step " + (i + 1);
                }
                Check(result, failure == null, $"workshop case {id}{(failure == null ? "" : " at " + failure)}");
                result.WorkshopCases++;
            }
        }

        /// <summary>Structural equality of parsed JSON (object key order ignored).</summary>
        private static bool JsonEquals(object a, object b)
        {
            if (a is Dictionary<string, object> da && b is Dictionary<string, object> db)
                return da.Count == db.Count && da.All(p => db.TryGetValue(p.Key, out var v) && JsonEquals(p.Value, v));
            if (a is List<object> la && b is List<object> lb)
                return la.Count == lb.Count && la.Zip(lb, JsonEquals).All(x => x);
            return Equals(a, b);
        }

        private static string Camel(string s) => char.ToLowerInvariant(s[0]) + s.Substring(1);

        private static (int X, int Y) Cell(object value)
        {
            var list = (List<object>)value;
            return (Convert.ToInt32(list[0]), Convert.ToInt32(list[1]));
        }

        private static string Snapshot(WorkshopController w, string result)
        {
            var board = w.Board.Nodes.OrderBy(n => n.Y).ThenBy(n => n.X)
                .Select(n => $"{n.Id}|{n.DefinitionId}|t{n.Tier}|{n.X},{n.Y}|lane{n.TargetLane}|{n.BaseIntervalTicks}");
            var sel = w.Selected.HasValue ? $"{w.Selected.Value.X},{w.Selected.Value.Y}" : "null";
            return $"result={result} scrap={w.BattleScrapBalance} offers=[{string.Join(",", w.Offers.Select(o => o ?? "null"))}] " +
                   $"hand={w.Hand?.Id ?? "null"} selected={sel} held=[{string.Join(",", w.Held.Select(h => h ? "true" : "false"))}] " +
                   $"rerolls={w.RerollsTaken} locked={w.Locked} board=[{string.Join(";", board)}]";
        }

        private static string Expected(Dictionary<string, object> s)
        {
            var offers = ((List<object>)s["offers"]).Select(o => (string)o ?? "null");
            var sel = s["selected"] is List<object> l ? $"{l[0]},{l[1]}" : "null";
            var board = ((List<object>)s["board"]).Cast<string>();
            return $"result={s["result"]} scrap={SharedJson.Int(s, "scrap")} offers=[{string.Join(",", offers)}] " +
                   $"hand={(string)s["hand"] ?? "null"} selected={sel} held=[{string.Join(",", ((List<object>)s["held"]).Select(h => (bool)h ? "true" : "false"))}] " +
                   $"rerolls={SharedJson.Int(s, "rerollsTaken")} " +
                   $"locked={((bool)s["locked"] ? "True" : "False")} board=[{string.Join(";", board)}]";
        }

        private static string Apply(WorkshopController w, Dictionary<string, object> op)
        {
            switch ((string)op["op"])
            {
                case "buy": return Camel(w.Buy(SharedJson.Int(op, "slot")).ToString());
                case "buyId": return Camel(w.Buy(Array.IndexOf(w.Offers, (string)op["id"])).ToString());
                case "tap": return Camel(w.TapCell(SharedJson.Int(op, "x"), SharedJson.Int(op, "y")).ToString());
                case "drop": return Camel(w.Drop(Cell(op["from"]), Cell(op["to"])).ToString());
                case "sell": return Camel(w.SellSelected().ToString());
                case "undo": return Camel(w.Undo().ToString());
                case "cancel": return Camel(w.CancelHand().ToString());
                case "reroll": return Camel(w.Reroll().ToString());
                case "hold": return Camel(w.ToggleHold(SharedJson.Int(op, "slot")).ToString());
                case "lock": w.Lock(); return "ok";
                case "intermission": return Camel(w.BeginIntermission(SharedJson.Int(op, "wave"), SharedJson.Int(op, "reward")).ToString());
                case "preview":
                    var p = w.PreviewAt(SharedJson.Int(op, "x"), SharedJson.Int(op, "y"),
                        op.TryGetValue("from", out var from) && from != null ? Cell(from) : default((int X, int Y)?));
                    return $"valid={(p.Valid ? "true" : "false")};state={(p.State.HasValue ? Camel(p.State.Value.ToString()) : "null")};" +
                           $"interval={p.IntervalTicks};lane={(p.Lane.HasValue ? p.Lane.Value.ToString() : "null")}";
                default: throw new ArgumentException("unknown op " + op["op"]);
            }
        }
    }
}
