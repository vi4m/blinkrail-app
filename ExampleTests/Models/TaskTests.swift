import XCTest
@testable import Blinkrail

/// Example unit tests for a Task model
/// These tests demonstrate best practices for testing data models in Swift
class TaskTests: XCTestCase {

    // MARK: - Properties

    var task: Task!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        task = Task(
            id: UUID(),
            title: "Complete unit tests",
            description: "Write comprehensive unit tests for the Task model",
            createdAt: Date(),
            status: .pending
        )
    }

    override func tearDown() {
        task = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testTaskInitializesWithCorrectProperties() {
        // Given
        let id = UUID()
        let title = "Test Task"
        let description = "Test Description"
        let createdAt = Date()

        // When
        let newTask = Task(
            id: id,
            title: title,
            description: description,
            createdAt: createdAt,
            status: .pending
        )

        // Then
        XCTAssertEqual(newTask.id, id)
        XCTAssertEqual(newTask.title, title)
        XCTAssertEqual(newTask.description, description)
        XCTAssertEqual(newTask.createdAt, createdAt)
        XCTAssertEqual(newTask.status, .pending)
    }

    func testTaskInitializesWithDefaultStatus() {
        // Given/When
        let newTask = Task(
            id: UUID(),
            title: "New Task",
            description: "Description",
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(newTask.status, .pending)
    }

    // MARK: - Status Transition Tests

    func testTaskCanBeMarkedAsInProgress() {
        // When
        task.markAsInProgress()

        // Then
        XCTAssertEqual(task.status, .inProgress)
        XCTAssertNotNil(task.startedAt)
    }

    func testTaskCanBeMarkedAsCompleted() {
        // When
        task.markAsCompleted()

        // Then
        XCTAssertEqual(task.status, .completed)
        XCTAssertNotNil(task.completedAt)
    }

    func testCompletedTaskCannotBeMarkedAsInProgress() {
        // Given
        task.markAsCompleted()

        // When
        task.markAsInProgress()

        // Then
        XCTAssertEqual(task.status, .completed, "Completed task should remain completed")
    }

    // MARK: - Validation Tests

    func testTaskWithEmptyTitleIsInvalid() {
        // Given
        task.title = ""

        // When/Then
        XCTAssertFalse(task.isValid())
    }

    func testTaskWithValidTitleIsValid() {
        // Given
        task.title = "Valid Title"

        // When/Then
        XCTAssertTrue(task.isValid())
    }

    func testTaskTitleMustBeLessThan200Characters() {
        // Given
        task.title = String(repeating: "a", count: 201)

        // When/Then
        XCTAssertFalse(task.isValid())
    }

    // MARK: - Duration Calculation Tests

    func testTaskDurationIsNilWhenNotStarted() {
        // When/Then
        XCTAssertNil(task.duration)
    }

    func testTaskDurationIsCalculatedCorrectlyWhenCompleted() {
        // Given
        let startDate = Date()
        task.startedAt = startDate
        task.completedAt = startDate.addingTimeInterval(3600) // 1 hour later

        // When
        let duration = task.duration

        // Then
        XCTAssertNotNil(duration)
        XCTAssertEqual(duration, 3600, accuracy: 0.1)
    }

    // MARK: - Equality Tests

    func testTasksWithSameIdAreEqual() {
        // Given
        let id = UUID()
        let task1 = Task(id: id, title: "Task 1", description: "Description 1", createdAt: Date())
        let task2 = Task(id: id, title: "Task 2", description: "Description 2", createdAt: Date())

        // When/Then
        XCTAssertEqual(task1, task2)
    }

    func testTasksWithDifferentIdsAreNotEqual() {
        // Given
        let task1 = Task(id: UUID(), title: "Task 1", description: "Description", createdAt: Date())
        let task2 = Task(id: UUID(), title: "Task 1", description: "Description", createdAt: Date())

        // When/Then
        XCTAssertNotEqual(task1, task2)
    }

    // MARK: - Encoding/Decoding Tests

    func testTaskCanBeEncodedAndDecoded() throws {
        // Given
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When
        let encodedData = try encoder.encode(task)
        let decodedTask = try decoder.decode(Task.self, from: encodedData)

        // Then
        XCTAssertEqual(task.id, decodedTask.id)
        XCTAssertEqual(task.title, decodedTask.title)
        XCTAssertEqual(task.description, decodedTask.description)
        XCTAssertEqual(task.status, decodedTask.status)
    }
}
