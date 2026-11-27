// Generates shared/test-fixtures/combat_traces.json from combat_scenarios.json using the
// Unity reference simulation (Gearbound.Core sources), outside the editor.
// Build and run with tools/simulation/generate_combat_traces.ps1.
using System;
using System.IO;
using Gearbound.Core;

internal static class CombatTraceGenerator
{
    public static int Main(string[] args)
    {
        var shared = args.Length > 0 ? args[0] : Path.Combine("..", "..", "shared");
        var check = Array.IndexOf(args, "--check") >= 0;
        var results = CombatScenarioRunner.RunAll(
            File.ReadAllText(Path.Combine(shared, "test-fixtures", "combat_scenarios.json")),
            File.ReadAllText(Path.Combine(shared, "waves", "mission_001.json")),
            File.ReadAllText(Path.Combine(shared, "enemies", "enemies.json")));
        var json = CombatScenarioRunner.ToJson(results);
        var target = Path.Combine(shared, "test-fixtures", "combat_traces.json");
        foreach (var r in results)
            Console.WriteLine($"{r.Id}: {r.Phase} at tick {r.ElapsedTicks}, fortress {r.FortressHealth}, produced {r.FriendlyUnitsProduced}, hash {r.TraceHash}");
        if (check)
        {
            var current = File.Exists(target) ? File.ReadAllText(target).Replace("\r\n", "\n") : "";
            if (current != json) { Console.WriteLine("STALE combat_traces.json"); return 1; }
            Console.WriteLine("combat traces up to date");
            return 0;
        }
        File.WriteAllText(target, json);
        Console.WriteLine("wrote " + target);
        return 0;
    }
}
