using System;
using UnityEngine;

namespace Gearbound.Baseline
{
    /// <summary>
    /// Runs <see cref="DeviceBaseline"/> in a player build and reports the result in the device log
    /// (logcat tag Unity) and on screen. The shared JSON is bundled as TextAssets under
    /// Resources/GearboundShared by the Android baseline build; nothing is read from the network.
    /// </summary>
    public sealed class DeviceBaselineRunner : MonoBehaviour
    {
        public const string ResourceRoot = "GearboundShared/";

        private string summary = "Running the Gearbound baseline…";
        private bool passed;

        private static string Read(string relative)
        {
            var path = ResourceRoot + relative.Substring(0, relative.Length - ".json".Length);
            var asset = Resources.Load<TextAsset>(path);
            if (asset == null) throw new InvalidOperationException("bundled fixture missing: " + relative);
            return asset.text;
        }

        private void Start()
        {
            var started = Time.realtimeSinceStartup;
            var result = DeviceBaseline.Run(Read);
            passed = result.Passed;
            summary = result.Summary;
            var elapsed = Time.realtimeSinceStartup - started;
            // One line per run so a log reader can grep for it.
            Debug.Log($"{summary} (platform {Application.platform}, {SystemInfo.processorType}, {elapsed:0.00} s)");
            if (!passed) Debug.LogError(summary);
        }

        private void OnGUI()
        {
            var style = new GUIStyle(GUI.skin.label) { fontSize = Mathf.Max(24, Screen.width / 30), wordWrap = true };
            style.normal.textColor = passed ? new Color(0.55f, 0.9f, 0.45f) : new Color(1f, 0.75f, 0.35f);
            GUI.Label(new Rect(24, 24, Screen.width - 48, Screen.height - 48), "GEARBOUND Unity baseline\n\n" + summary, style);
        }
    }
}
