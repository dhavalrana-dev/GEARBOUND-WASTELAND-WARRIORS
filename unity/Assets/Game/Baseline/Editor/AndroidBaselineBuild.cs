using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Gearbound.Baseline.Editor
{
    /// <summary>
    /// Builds the Unity on-device baseline APK (Phase 01 item 1.7, GB-012):
    ///
    ///   Unity.exe -batchmode -nographics -quit -projectPath unity -buildTarget Android
    ///     -executeMethod Gearbound.Baseline.Editor.AndroidBaselineBuild.Build -logFile artifacts/unity-android-build.log
    ///
    /// Copies the shared fixtures into a generated Resources folder, generates a one-object scene,
    /// and builds an IL2CPP APK for ARM64 (phones) and x86_64 (the emulator) to unity/Builds/android/.
    /// Everything it generates lives under Assets/Generated, which is not committed.
    /// </summary>
    public static class AndroidBaselineBuild
    {
        private const string GeneratedRoot = "Assets/Generated";
        private const string ScenePath = GeneratedRoot + "/DeviceBaseline.unity";
        public const string OutputPath = "Builds/android/gearbound-unity-baseline.apk";
        public const string ApplicationId = "com.gearbound.unitybaseline";

        public static void Build()
        {
            try
            {
                var report = BuildApk();
                Debug.Log($"ANDROID BASELINE BUILD {report.summary.result}: {report.summary.outputPath} ({report.summary.totalSize} bytes, {report.summary.totalTime})");
                if (Application.isBatchMode) EditorApplication.Exit(report.summary.result == BuildResult.Succeeded ? 0 : 1);
            }
            catch (Exception e)
            {
                Debug.LogError("ANDROID BASELINE BUILD FAILED: " + e);
                if (Application.isBatchMode) EditorApplication.Exit(1);
            }
        }

        [MenuItem("Gearbound/Build Android Baseline APK")]
        private static void BuildFromMenu() => Debug.Log("Android baseline build: " + BuildApk().summary.result);

        private static BuildReport BuildApk()
        {
            BundleSharedFixtures();
            CreateScene();
            var android = NamedBuildTarget.Android;
            PlayerSettings.SetApplicationIdentifier(android, ApplicationId);
            PlayerSettings.SetScriptingBackend(android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64 | AndroidArchitecture.X86_64;
            Directory.CreateDirectory(Path.GetDirectoryName(OutputPath));
            return BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = OutputPath,
                target = BuildTarget.Android,
                options = BuildOptions.None,
            });
        }

        private static void BundleSharedFixtures()
        {
            var shared = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "shared"));
            if (!Directory.Exists(shared)) throw new DirectoryNotFoundException(shared);
            var target = Path.Combine(GeneratedRoot, "Resources", DeviceBaselineRunner.ResourceRoot.TrimEnd('/'));
            if (Directory.Exists(target)) Directory.Delete(target, true);
            foreach (var relative in DeviceBaseline.Files)
            {
                var destination = Path.Combine(target, relative);
                Directory.CreateDirectory(Path.GetDirectoryName(destination));
                File.Copy(Path.Combine(shared, relative), destination);
            }
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            var missing = DeviceBaseline.Files.Where(f => AssetDatabase.LoadAssetAtPath<TextAsset>(Path.Combine(target, f).Replace('\\', '/')) == null).ToArray();
            if (missing.Length > 0) throw new InvalidOperationException("fixtures not imported as TextAssets: " + string.Join(", ", missing));
        }

        private static void CreateScene()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            var camera = Camera.main;
            if (camera != null)
            {
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = new Color(0.11f, 0.09f, 0.07f);
            }
            new GameObject("DeviceBaseline").AddComponent<DeviceBaselineRunner>();
            if (!EditorSceneManager.SaveScene(scene, ScenePath)) throw new IOException("could not save " + ScenePath);
        }
    }
}
