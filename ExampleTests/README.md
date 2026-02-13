# Example Unit Tests for Blinkrail

This directory contains example unit tests that demonstrate best practices for testing a Swift/macOS application like Blinkrail. These tests are designed to serve as templates and examples for implementing comprehensive test coverage in the main source code repository.

## Overview

The example tests are organized into three categories, mirroring a typical Swift application architecture:

- **Models/** - Tests for data models and entities
- **Services/** - Tests for business logic and services
- **ViewModels/** - Tests for presentation layer and Combine publishers

## Test Files

### 1. TaskTests.swift (Models)

Tests for the `Task` data model, covering:

- **Initialization**: Verifying objects are created with correct properties
- **State Transitions**: Testing status changes (pending → in progress → completed)
- **Validation**: Ensuring business rules are enforced (title length, required fields)
- **Duration Calculation**: Testing time-based computations
- **Equality**: Verifying object comparison logic
- **Serialization**: Testing JSON encoding/decoding

**Key Testing Patterns:**
- Given-When-Then structure for clarity
- Comprehensive property validation
- Edge case handling (empty strings, boundary values)
- State machine testing for status transitions

### 2. FocusSessionTests.swift (Services)

Tests for the `FocusSession` service, demonstrating:

- **Service Lifecycle**: Start, pause, resume, complete operations
- **Timer Integration**: Using mock timers for deterministic testing
- **Business Logic**: Reward calculations, progress tracking
- **State Management**: Preventing invalid state transitions
- **Dependency Injection**: Using mocks for external dependencies
- **Edge Cases**: Extension limits, interruption tracking

**Key Testing Patterns:**
- Dependency injection with mock objects
- Timer simulation for time-based logic
- State transition validation
- Reward system verification
- Mock notification service integration

### 3. TaskBoardViewModelTests.swift (ViewModels)

Tests for the `TaskBoardViewModel`, covering:

- **Async/Await**: Testing asynchronous operations with modern Swift concurrency
- **Combine Publishers**: Verifying reactive state updates
- **Repository Integration**: Using mocks to isolate view model logic
- **CRUD Operations**: Create, Read, Update, Delete functionality
- **Filtering & Search**: Testing data transformation logic
- **Error Handling**: Graceful degradation and user feedback
- **Loading States**: UI state management during async operations

**Key Testing Patterns:**
- Combine publisher testing with `sink` and expectations
- Mock repositories for data layer isolation
- Async/await testing patterns
- Publisher value collection and assertion
- Error state verification

## Testing Framework

These tests use **XCTest**, Apple's native testing framework for Swift/macOS applications.

### Key XCTest Features Used:

- `XCTestCase`: Base class for all test cases
- `setUp()` / `tearDown()`: Test lifecycle management
- `XCTAssert*`: Assertion methods for verification
- `XCTestExpectation`: Async operation testing
- `@testable import`: Access to internal types for testing

## Best Practices Demonstrated

### 1. Test Structure

Each test follows the **Given-When-Then** pattern:

```swift
func testExample() {
    // Given - Set up test conditions
    let task = Task(id: UUID(), title: "Test")

    // When - Perform the action being tested
    task.markAsCompleted()

    // Then - Verify the expected outcome
    XCTAssertEqual(task.status, .completed)
}
```

### 2. Mock Objects

Use mock objects to isolate the system under test:

```swift
class MockTimer {
    var isRunning = false

    func simulateTick() {
        tickHandler?()
    }
}
```

Benefits:
- Fast execution (no real timers or network calls)
- Deterministic results
- Easy to simulate edge cases
- Test isolation

### 3. Test Naming

Tests use descriptive names that explain what is being tested:

```swift
func testFocusSessionCompletesWhenTimeExpires()
func testTaskWithEmptyTitleIsInvalid()
func testAddTaskWithEmptyTitleShowsError()
```

Format: `test[SystemUnderTest][Condition][ExpectedBehavior]`

### 4. Test Coverage Areas

Complete test coverage includes:

- ✅ **Happy Path**: Normal, expected usage
- ✅ **Edge Cases**: Boundary values, empty inputs
- ✅ **Error Handling**: Invalid states, exceptions
- ✅ **State Transitions**: Valid and invalid transitions
- ✅ **Integration Points**: Mock external dependencies
- ✅ **Async Operations**: Proper handling of timing
- ✅ **Data Persistence**: Serialization/deserialization

### 5. Dependency Injection

Services and ViewModels accept dependencies through initializers:

```swift
class TaskBoardViewModel {
    init(
        taskRepository: TaskRepositoryProtocol,
        focusSessionService: FocusSessionServiceProtocol
    ) {
        // Use protocols to enable mocking
    }
}
```

This enables:
- Easy mocking in tests
- Loose coupling
- Better testability
- Flexible implementation swapping

## Running the Tests

Once integrated into the main Xcode project:

### Command Line
```bash
# Run all tests
xcodebuild test -scheme Blinkrail -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme Blinkrail -only-testing:BlinkrailTests/TaskTests

# Run specific test method
xcodebuild test -scheme Blinkrail -only-testing:BlinkrailTests/TaskTests/testTaskInitializesWithCorrectProperties
```

### Xcode IDE
- Press `⌘U` to run all tests
- Click the diamond icon in the gutter to run individual tests
- Use Test Navigator (`⌘6`) to browse and run tests

## Test Organization in Main Project

When integrating into the actual Blinkrail project, organize tests as:

```
Blinkrail/
├── Blinkrail/                    # Main app target
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   └── Views/
└── BlinkrailTests/               # Test target
    ├── Models/
    │   ├── TaskTests.swift
    │   └── FocusSessionModelTests.swift
    ├── Services/
    │   ├── FocusSessionTests.swift
    │   ├── GitHubSyncServiceTests.swift
    │   └── MediaKeyHandlerTests.swift
    ├── ViewModels/
    │   ├── TaskBoardViewModelTests.swift
    │   └── SettingsViewModelTests.swift
    ├── Helpers/
    │   └── TestHelpers.swift
    └── Mocks/
        ├── MockTaskRepository.swift
        └── MockNotificationService.swift
```

## Additional Test Areas for Blinkrail

Based on the application's features, additional test coverage should include:

### Core Features
- **Media Key Handling**: Test Play/Pause/Skip functionality
- **Zoom Detection**: Test meeting pause/resume logic
- **GitHub Integration**: Test OAuth flow and sync operations
- **Break Management**: Test break timer and nag banner logic
- **Reward System**: Test focus spark calculations and tree progress
- **Settings Persistence**: Test iCloud sync and local storage

### Platform-Specific
- **macOS Integration**: Menu bar, notifications, global hotkeys
- **Sparkle Updates**: Test update checking and installation flow
- **Accessibility**: Test VoiceOver and keyboard navigation

## Continuous Integration

Integrate tests into CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    xcodebuild test \
      -scheme Blinkrail \
      -destination 'platform=macOS' \
      -enableCodeCoverage YES

- name: Generate Coverage Report
  run: |
    xcrun xccov view --report --json \
      DerivedData/Logs/Test/*.xcresult > coverage.json
```

## Code Coverage Goals

Aim for:
- **Models**: 90-100% coverage (pure logic, easy to test)
- **Services**: 80-90% coverage (business logic with some OS integration)
- **ViewModels**: 80-90% coverage (presentation logic)
- **Views**: 60-70% coverage (UI code, harder to unit test)

Use Xcode's code coverage tools to identify untested code paths.

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Swift with XCTest](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [Swift Testing Best Practices](https://www.swift.org/documentation/articles/testing.html)
- [Combine Testing Techniques](https://developer.apple.com/documentation/combine/testing)

## Contributing

When adding new tests:

1. Follow the existing structure and naming conventions
2. Include Given-When-Then comments for clarity
3. Test both success and failure paths
4. Mock external dependencies
5. Keep tests fast and isolated
6. Write descriptive test names
7. Add comments for complex test scenarios

## Notes

These are **example tests** for a repository that contains only release artifacts. To use these tests in the actual Blinkrail application:

1. Copy the test files to your Xcode project's test target
2. Adjust import statements to match your actual module names
3. Implement the actual models, services, and view models being tested
4. Ensure protocols exist for mockable dependencies
5. Run tests and adjust as needed for your specific implementation

---

**Last Updated**: 2026-02-13
**XCTest Version**: Compatible with Xcode 15.x and later
**Swift Version**: Swift 5.9+
