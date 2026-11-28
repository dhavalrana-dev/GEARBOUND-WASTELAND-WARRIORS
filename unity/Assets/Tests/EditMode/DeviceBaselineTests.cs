using System.IO;
using Gearbound.Baseline;
using NUnit.Framework;

namespace Gearbound.Tests
{
    /// <summary>The on-device baseline must pass in the editor too, from the repository's shared/ files.</summary>
    public sealed class DeviceBaselineTests
    {
        private static string Read(string relative)
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            while (dir != null && !Directory.Exists(Path.Combine(dir.FullName, "shared"))) dir = dir.Parent;
            Assert.IsNotNull(dir, "shared/ folder not found");
            return File.ReadAllText(Path.Combine(dir.FullName, "shared", relative));
        }

        [Test]
        public void BaselinePassesInTheEditor()
        {
            var result = DeviceBaseline.Run(Read);
            Assert.IsEmpty(result.Failures, result.Summary);
            Assert.AreEqual(7, result.CombatTraces);
            Assert.AreEqual(7, result.WorkshopCases);
            TestContext.WriteLine(result.Summary);
        }

        [Test]
        public void ACorruptFixtureIsReportedNotThrown()
        {
            var result = DeviceBaseline.Run(rel => rel == "test-fixtures/combat_traces.json"
                ? Read(rel).Replace("\"traceHash\": 2018397086", "\"traceHash\": 1")
                : Read(rel));
            Assert.IsFalse(result.Passed);
            Assert.That(result.Failures, Has.Some.Contains("combat trace lane1-press-idle-hero"));
        }
    }
}
