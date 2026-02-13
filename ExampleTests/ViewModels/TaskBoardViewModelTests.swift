import XCTest
import Combine
@testable import Blinkrail

/// Example unit tests for a TaskBoardViewModel
/// These tests demonstrate best practices for testing view models with Combine publishers in Swift
class TaskBoardViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: TaskBoardViewModel!
    var mockTaskRepository: MockTaskRepository!
    var mockFocusSessionService: MockFocusSessionService!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockTaskRepository = MockTaskRepository()
        mockFocusSessionService = MockFocusSessionService()
        cancellables = []

        viewModel = TaskBoardViewModel(
            taskRepository: mockTaskRepository,
            focusSessionService: mockFocusSessionService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockTaskRepository = nil
        mockFocusSessionService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitializesWithEmptyTasks() {
        // When/Then
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Load Tasks Tests

    func testLoadTasksFetchesFromRepository() async {
        // Given
        let expectedTasks = [
            Task(id: UUID(), title: "Task 1", description: "Description 1", createdAt: Date()),
            Task(id: UUID(), title: "Task 2", description: "Description 2", createdAt: Date())
        ]
        mockTaskRepository.tasksToReturn = expectedTasks

        // When
        await viewModel.loadTasks()

        // Then
        XCTAssertEqual(viewModel.tasks.count, 2)
        XCTAssertEqual(viewModel.tasks, expectedTasks)
        XCTAssertTrue(mockTaskRepository.didCallFetchTasks)
    }

    func testLoadTasksSetsLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        await viewModel.loadTasks()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [false, true, false], "Should transition from false -> true -> false")
    }

    func testLoadTasksHandlesErrorGracefully() async {
        // Given
        mockTaskRepository.shouldThrowError = true

        // When
        await viewModel.loadTasks()

        // Then
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Add Task Tests

    func testAddTaskCreatesNewTask() async {
        // Given
        let title = "New Task"
        let description = "New Description"

        // When
        await viewModel.addTask(title: title, description: description)

        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, title)
        XCTAssertEqual(viewModel.tasks.first?.description, description)
        XCTAssertTrue(mockTaskRepository.didCallSaveTask)
    }

    func testAddTaskWithEmptyTitleShowsError() async {
        // When
        await viewModel.addTask(title: "", description: "Description")

        // Then
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Task title cannot be empty")
    }

    func testAddTaskPublishesUpdate() async {
        // Given
        let expectation = XCTestExpectation(description: "Tasks published")
        var taskCount = 0

        viewModel.$tasks
            .sink { tasks in
                taskCount = tasks.count
                if taskCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        await viewModel.addTask(title: "Test", description: "Description")

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(taskCount, 1)
    }

    // MARK: - Update Task Tests

    func testUpdateTaskModifiesExistingTask() async {
        // Given
        let task = Task(id: UUID(), title: "Original", description: "Original", createdAt: Date())
        viewModel.tasks = [task]
        let newTitle = "Updated Title"

        // When
        await viewModel.updateTask(id: task.id, title: newTitle, description: task.description)

        // Then
        XCTAssertEqual(viewModel.tasks.first?.title, newTitle)
        XCTAssertTrue(mockTaskRepository.didCallUpdateTask)
    }

    func testUpdateNonExistentTaskShowsError() async {
        // Given
        let nonExistentId = UUID()

        // When
        await viewModel.updateTask(id: nonExistentId, title: "New Title", description: "Description")

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Delete Task Tests

    func testDeleteTaskRemovesTask() async {
        // Given
        let task = Task(id: UUID(), title: "Task", description: "Description", createdAt: Date())
        viewModel.tasks = [task]

        // When
        await viewModel.deleteTask(id: task.id)

        // Then
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertTrue(mockTaskRepository.didCallDeleteTask)
    }

    func testDeleteTaskPublishesUpdate() async {
        // Given
        let task = Task(id: UUID(), title: "Task", description: "Description", createdAt: Date())
        viewModel.tasks = [task]

        let expectation = XCTestExpectation(description: "Tasks updated after deletion")
        var finalCount = 1

        viewModel.$tasks
            .dropFirst() // Skip initial value
            .sink { tasks in
                finalCount = tasks.count
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        await viewModel.deleteTask(id: task.id)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(finalCount, 0)
    }

    // MARK: - Complete Task Tests

    func testCompleteTaskMarksTaskAsCompleted() async {
        // Given
        let task = Task(id: UUID(), title: "Task", description: "Description", createdAt: Date())
        viewModel.tasks = [task]

        // When
        await viewModel.completeTask(id: task.id)

        // Then
        XCTAssertEqual(viewModel.tasks.first?.status, .completed)
        XCTAssertTrue(mockTaskRepository.didCallUpdateTask)
    }

    func testCompleteTaskTriggersCelebration() async {
        // Given
        let task = Task(id: UUID(), title: "Task", description: "Description", createdAt: Date())
        viewModel.tasks = [task]

        let expectation = XCTestExpectation(description: "Celebration triggered")

        viewModel.$showsCelebration
            .dropFirst()
            .sink { shows in
                if shows {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        await viewModel.completeTask(id: task.id)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showsCelebration)
    }

    // MARK: - Filter Tests

    func testFilterTasksByStatus() {
        // Given
        let pendingTask = Task(id: UUID(), title: "Pending", description: "Desc", createdAt: Date(), status: .pending)
        let completedTask = Task(id: UUID(), title: "Completed", description: "Desc", createdAt: Date(), status: .completed)
        viewModel.tasks = [pendingTask, completedTask]

        // When
        viewModel.filterBy(status: .pending)

        // Then
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertEqual(viewModel.filteredTasks.first?.status, .pending)
    }

    func testFilterAllShowsAllTasks() {
        // Given
        let task1 = Task(id: UUID(), title: "Task 1", description: "Desc", createdAt: Date(), status: .pending)
        let task2 = Task(id: UUID(), title: "Task 2", description: "Desc", createdAt: Date(), status: .completed)
        viewModel.tasks = [task1, task2]

        // When
        viewModel.filterBy(status: nil)

        // Then
        XCTAssertEqual(viewModel.filteredTasks.count, 2)
    }

    // MARK: - Search Tests

    func testSearchFiltersTasks() {
        // Given
        let task1 = Task(id: UUID(), title: "Write unit tests", description: "Desc", createdAt: Date())
        let task2 = Task(id: UUID(), title: "Fix bugs", description: "Desc", createdAt: Date())
        viewModel.tasks = [task1, task2]

        // When
        viewModel.searchText = "unit"

        // Then
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertEqual(viewModel.filteredTasks.first?.title, "Write unit tests")
    }

    func testSearchIsCaseInsensitive() {
        // Given
        let task = Task(id: UUID(), title: "UPPERCASE", description: "Desc", createdAt: Date())
        viewModel.tasks = [task]

        // When
        viewModel.searchText = "upper"

        // Then
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
    }

    // MARK: - Statistics Tests

    func testTaskStatisticsAreCalculatedCorrectly() {
        // Given
        let pending = Task(id: UUID(), title: "Task 1", description: "Desc", createdAt: Date(), status: .pending)
        let completed = Task(id: UUID(), title: "Task 2", description: "Desc", createdAt: Date(), status: .completed)
        let inProgress = Task(id: UUID(), title: "Task 3", description: "Desc", createdAt: Date(), status: .inProgress)
        viewModel.tasks = [pending, completed, inProgress]

        // When
        let stats = viewModel.taskStatistics

        // Then
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.completed, 1)
        XCTAssertEqual(stats.pending, 1)
        XCTAssertEqual(stats.inProgress, 1)
        XCTAssertEqual(stats.completionRate, 1.0/3.0, accuracy: 0.01)
    }

    // MARK: - Start Focus Session Tests

    func testStartFocusSessionForTask() async {
        // Given
        let task = Task(id: UUID(), title: "Focus Task", description: "Desc", createdAt: Date())
        viewModel.tasks = [task]

        // When
        await viewModel.startFocusSession(for: task.id)

        // Then
        XCTAssertTrue(mockFocusSessionService.didStartSession)
        XCTAssertEqual(mockFocusSessionService.sessionTaskId, task.id)
        XCTAssertEqual(viewModel.tasks.first?.status, .inProgress)
    }
}

// MARK: - Mock Objects

class MockTaskRepository {
    var tasksToReturn: [Task] = []
    var shouldThrowError = false
    var didCallFetchTasks = false
    var didCallSaveTask = false
    var didCallUpdateTask = false
    var didCallDeleteTask = false

    func fetchTasks() async throws -> [Task] {
        didCallFetchTasks = true
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return tasksToReturn
    }

    func save(task: Task) async throws {
        didCallSaveTask = true
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
    }

    func update(task: Task) async throws {
        didCallUpdateTask = true
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
    }

    func delete(taskId: UUID) async throws {
        didCallDeleteTask = true
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
    }
}

class MockFocusSessionService {
    var didStartSession = false
    var sessionTaskId: UUID?

    func startSession(for taskId: UUID) {
        didStartSession = true
        sessionTaskId = taskId
    }
}
