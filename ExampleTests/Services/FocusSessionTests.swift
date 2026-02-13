import XCTest
@testable import Blinkrail

/// Example unit tests for a FocusSession service
/// These tests demonstrate best practices for testing business logic and services in Swift
class FocusSessionTests: XCTestCase {

    // MARK: - Properties

    var focusSession: FocusSession!
    var mockTimer: MockTimer!
    var mockNotificationService: MockNotificationService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockTimer = MockTimer()
        mockNotificationService = MockNotificationService()
        focusSession = FocusSession(
            duration: 25 * 60, // 25 minutes (Pomodoro default)
            timer: mockTimer,
            notificationService: mockNotificationService
        )
    }

    override func tearDown() {
        focusSession = nil
        mockTimer = nil
        mockNotificationService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testFocusSessionInitializesWithCorrectDuration() {
        // When
        let session = FocusSession(duration: 1800) // 30 minutes

        // Then
        XCTAssertEqual(session.duration, 1800)
        XCTAssertEqual(session.remainingTime, 1800)
        XCTAssertEqual(session.state, .ready)
    }

    func testFocusSessionInitializesWithDefaultPomodoroDuration() {
        // When
        let session = FocusSession()

        // Then
        XCTAssertEqual(session.duration, 25 * 60) // 25 minutes
    }

    // MARK: - State Transition Tests

    func testFocusSessionCanStart() {
        // When
        focusSession.start()

        // Then
        XCTAssertEqual(focusSession.state, .active)
        XCTAssertNotNil(focusSession.startedAt)
        XCTAssertTrue(mockTimer.isRunning)
    }

    func testFocusSessionCanPause() {
        // Given
        focusSession.start()

        // When
        focusSession.pause()

        // Then
        XCTAssertEqual(focusSession.state, .paused)
        XCTAssertFalse(mockTimer.isRunning)
    }

    func testFocusSessionCanResumeFromPause() {
        // Given
        focusSession.start()
        focusSession.pause()
        let remainingBeforePause = focusSession.remainingTime

        // When
        focusSession.resume()

        // Then
        XCTAssertEqual(focusSession.state, .active)
        XCTAssertTrue(mockTimer.isRunning)
        XCTAssertEqual(focusSession.remainingTime, remainingBeforePause)
    }

    func testFocusSessionCanComplete() {
        // Given
        focusSession.start()

        // When
        focusSession.complete()

        // Then
        XCTAssertEqual(focusSession.state, .completed)
        XCTAssertNotNil(focusSession.completedAt)
        XCTAssertFalse(mockTimer.isRunning)
    }

    func testCompletedFocusSessionCannotBeRestarted() {
        // Given
        focusSession.start()
        focusSession.complete()

        // When
        focusSession.start()

        // Then
        XCTAssertEqual(focusSession.state, .completed, "Completed session should not restart")
        XCTAssertFalse(mockTimer.isRunning)
    }

    // MARK: - Timer Tick Tests

    func testRemainingTimeDecrementsOnTimerTick() {
        // Given
        focusSession.start()
        let initialRemaining = focusSession.remainingTime

        // When
        mockTimer.simulateTick()

        // Then
        XCTAssertEqual(focusSession.remainingTime, initialRemaining - 1)
    }

    func testFocusSessionCompletesWhenTimeExpires() {
        // Given
        focusSession = FocusSession(duration: 1, timer: mockTimer)
        focusSession.start()

        // When
        mockTimer.simulateTick()

        // Then
        XCTAssertEqual(focusSession.state, .completed)
        XCTAssertTrue(mockNotificationService.didSendCompletionNotification)
    }

    // MARK: - Progress Calculation Tests

    func testProgressIsZeroAtStart() {
        // When/Then
        XCTAssertEqual(focusSession.progress, 0.0, accuracy: 0.01)
    }

    func testProgressIsCalculatedCorrectly() {
        // Given
        focusSession = FocusSession(duration: 100, timer: mockTimer)
        focusSession.start()

        // When
        for _ in 0..<50 {
            mockTimer.simulateTick()
        }

        // Then
        XCTAssertEqual(focusSession.progress, 0.5, accuracy: 0.01)
    }

    func testProgressIsOneWhenCompleted() {
        // Given
        focusSession.start()
        focusSession.complete()

        // When/Then
        XCTAssertEqual(focusSession.progress, 1.0, accuracy: 0.01)
    }

    // MARK: - Reward Calculation Tests

    func testFocusSparkRewardsAreCalculatedCorrectly() {
        // Given
        focusSession = FocusSession(duration: 25 * 60) // 25 minutes
        focusSession.start()
        focusSession.complete()

        // When
        let rewards = focusSession.calculateRewards()

        // Then
        XCTAssertEqual(rewards.focusSparks, 25) // 1 spark per minute
        XCTAssertGreaterThan(rewards.experiencePoints, 0)
    }

    func testBonusRewardsForLongSessions() {
        // Given
        focusSession = FocusSession(duration: 60 * 60) // 60 minutes
        focusSession.start()
        focusSession.complete()

        // When
        let rewards = focusSession.calculateRewards()

        // Then
        XCTAssertGreaterThan(rewards.focusSparks, 60) // Bonus for long sessions
        XCTAssertTrue(rewards.hasBonus)
    }

    func testNoRewardsForIncompleteSessions() {
        // Given
        focusSession.start()
        // Don't complete the session

        // When
        let rewards = focusSession.calculateRewards()

        // Then
        XCTAssertEqual(rewards.focusSparks, 0)
        XCTAssertEqual(rewards.experiencePoints, 0)
    }

    // MARK: - Extension Tests

    func testFocusSessionCanBeExtended() {
        // Given
        let initialDuration = focusSession.duration

        // When
        focusSession.extend(by: 5 * 60) // Extend by 5 minutes

        // Then
        XCTAssertEqual(focusSession.duration, initialDuration + 5 * 60)
        XCTAssertEqual(focusSession.remainingTime, initialDuration + 5 * 60)
    }

    func testCompletedSessionCannotBeExtended() {
        // Given
        focusSession.start()
        focusSession.complete()
        let completedDuration = focusSession.duration

        // When
        focusSession.extend(by: 5 * 60)

        // Then
        XCTAssertEqual(focusSession.duration, completedDuration, "Completed session should not be extendable")
    }

    // MARK: - Interruption Tests

    func testFocusSessionTracksInterruptions() {
        // Given
        focusSession.start()

        // When
        focusSession.recordInterruption(reason: "Zoom meeting detected")

        // Then
        XCTAssertEqual(focusSession.interruptions.count, 1)
        XCTAssertEqual(focusSession.interruptions.first?.reason, "Zoom meeting detected")
    }

    func testMultipleInterruptionsAreTracked() {
        // Given
        focusSession.start()

        // When
        focusSession.recordInterruption(reason: "Phone call")
        focusSession.recordInterruption(reason: "Notification")

        // Then
        XCTAssertEqual(focusSession.interruptions.count, 2)
    }

    // MARK: - Serialization Tests

    func testFocusSessionCanBeSavedAndRestored() throws {
        // Given
        focusSession.start()
        mockTimer.simulateTick()
        mockTimer.simulateTick()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When
        let encodedData = try encoder.encode(focusSession)
        let decodedSession = try decoder.decode(FocusSession.self, from: encodedData)

        // Then
        XCTAssertEqual(decodedSession.duration, focusSession.duration)
        XCTAssertEqual(decodedSession.remainingTime, focusSession.remainingTime)
        XCTAssertEqual(decodedSession.state, focusSession.state)
    }
}

// MARK: - Mock Objects

class MockTimer {
    var isRunning = false
    var tickHandler: (() -> Void)?

    func start(tickHandler: @escaping () -> Void) {
        self.isRunning = true
        self.tickHandler = tickHandler
    }

    func stop() {
        self.isRunning = false
    }

    func simulateTick() {
        tickHandler?()
    }
}

class MockNotificationService {
    var didSendCompletionNotification = false

    func sendCompletionNotification() {
        didSendCompletionNotification = true
    }
}
