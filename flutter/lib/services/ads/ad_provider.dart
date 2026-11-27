import '../../economy/wallet.dart';

/// Outcome reported by an ad provider for one rewarded show.
enum RewardedOutcome { earned, dismissedEarly, noFill, failedToShow }

/// Provider boundary. The real implementation (google_mobile_ads) is not
/// integrated yet; see docs/ADVERTISING_ARCHITECTURE.md. Gameplay code only
/// ever sees this interface.
abstract interface class AdProvider {
  bool get isLive;
  Future<bool> loadRewarded(String placementId);

  /// Shows an ad. [onEarned] may be invoked zero, one or (with buggy SDKs)
  /// several times; the controller must tolerate all three.
  Future<RewardedOutcome> showRewarded(
    String placementId, {
    required void Function() onEarned,
  });
}

/// Deterministic fake for tests and debug builds. Never reports itself as live.
class MockAdProvider implements AdProvider {
  MockAdProvider({
    this.fill = true,
    this.outcome = RewardedOutcome.earned,
    this.earnedCallbacks = 1,
  });

  bool fill;
  RewardedOutcome outcome;

  /// How many times the earned callback fires (simulates duplicate callbacks).
  int earnedCallbacks;
  int shows = 0;

  @override
  bool get isLive => false;

  @override
  Future<bool> loadRewarded(String placementId) async => fill;

  @override
  Future<RewardedOutcome> showRewarded(
    String placementId, {
    required void Function() onEarned,
  }) async {
    shows++;
    if (!fill) return RewardedOutcome.noFill;
    if (outcome == RewardedOutcome.earned) {
      for (var i = 0; i < earnedCallbacks; i++) {
        onEarned();
      }
    }
    return outcome;
  }
}

enum RewardedFlowResult {
  granted,
  alreadyGranted,
  notEligible,
  unavailable,
  notEarned,
}

/// Runs one opted-in rewarded offer: eligibility → load → show → grant once.
/// The grant goes through the wallet ledger keyed by [offerId], so duplicate
/// callbacks, retries after a crash, or a second tap can never pay twice.
/// Dismissing early, no fill and SDK failures grant nothing and never block
/// the player.
class RewardedAdController {
  RewardedAdController({required this.provider, required this.wallet});

  final AdProvider provider;
  final Wallet wallet;

  Future<RewardedFlowResult> run({
    required String placementId,
    required String offerId,
    required bool eligible,
    required List<TxnDelta> reward,
    DateTime? at,
  }) async {
    final key = 'ad_reward:$placementId:$offerId';
    if (wallet.hasProcessed(key)) return RewardedFlowResult.alreadyGranted;
    if (!eligible) return RewardedFlowResult.notEligible;
    if (!await provider.loadRewarded(placementId)) {
      return RewardedFlowResult.unavailable;
    }
    var earned = false;
    final outcome = await provider.showRewarded(
      placementId,
      onEarned: () => earned = true,
    );
    if (outcome == RewardedOutcome.noFill ||
        outcome == RewardedOutcome.failedToShow) {
      return RewardedFlowResult.unavailable;
    }
    if (!earned) return RewardedFlowResult.notEarned;
    final result = wallet.apply(
      TxnRequest(
        idempotencyKey: key,
        type: 'ad_reward',
        source: placementId,
        referenceId: offerId,
        deltas: reward,
      ),
      at: at,
    );
    return switch (result.status) {
      TxnStatus.applied => RewardedFlowResult.granted,
      TxnStatus.duplicate => RewardedFlowResult.alreadyGranted,
      TxnStatus.rejected => RewardedFlowResult.notEarned,
    };
  }
}
