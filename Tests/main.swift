import Foundation
let focus = FocusSessionTests()
let preferences = PreferencesTests()
let gaming = GamingSessionTests()
let spotify = SpotifyTests()
let tests: [(String, () throws -> Void)] = [
    ("deadline countdown", focus.testCountdownUsesDeadlineInsteadOfNumberOfViewUpdates),
    ("pause and resume", focus.testPauseFreezesTimeAndResumePreservesRemainingDuration),
    ("completion and restart", focus.testExpiredSessionClampsToZeroAndCanRestart),
    ("persistence", focus.testRunningDeadlineSurvivesPersistenceAndAppAbsence),
    ("reset", focus.testResetClearsDeadlineAndChangesDuration),
    ("settings persistence", preferences.testPreferencesAndEditedActionsSurviveStorageRoundTrip),
    ("corrupt settings", preferences.testCorruptStoredDataFallsBackWithoutCrashing),
    ("safe action URLs", preferences.testQuickActionsRejectUnsafeAndIncompleteURLs),
    ("idle timer policy", preferences.testKeepAwakeRequiresBothActiveSceneAndEnabledSetting),
    ("gaming elapsed/idempotent start", gaming.testElapsedTimeContinuesWithoutViewTicksAndStartIsIdempotent),
    ("gaming pause/resume/reset", gaming.testPausedTimeIsExcludedAndResetStopsTheSession),
    ("gaming running persistence", gaming.testRunningSessionRestoresElapsedTimeAfterRelaunch),
    ("verified Mac game editions", gaming.testLibraryMatchesVerifiedMacEditions),
    ("game change boundary", gaming.testChangingGameResetsTimerButReselectingSameProfilePreservesIt),
    ("legacy preferences migration", gaming.testLegacyPreferencesKeepExistingFocusAndDisplaySettings),
    ("gaming preferences round trip", gaming.testGamingProfileModeAndMotionPreferenceRoundTrip),
    ("PKCE known vector", spotify.testPKCEChallengeMatchesRFC7636Vector),
    ("read-only OAuth scope", spotify.testAuthorizationRequestsOnlyReadOnlyPlaybackScope),
    ("OAuth rejects invalid callback", spotify.testCallbackRejectsWrongStateHostPathAndDeniedConsent),
    ("OAuth valid callback", spotify.testValidCallbackReturnsCode),
    ("token form escaping", spotify.testTokenFormEscapesReservedCharacters),
    ("original Spotify artwork decoding", spotify.testPlaybackDecodesOriginalArtworkAndSpotifyLink),
    ("empty/ad playback", spotify.testAbsentOrAdvertisementPlaybackDoesNotInventTrack)
]
for (name, run) in tests {
    let before = failures
    do { try run() } catch { failures += 1; print("FAIL \(name): \(error)") }
    print("\(failures == before ? "PASS" : "FAIL") \(name)")
}
print("\(tests.count) tests; \(failures) failures")
exit(failures == 0 ? 0 : 1)
