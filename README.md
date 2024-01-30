
# SwiftMock - Mocking Framework for Swift

## Overview

`SwiftMock` is a simple mocking utility for Swift, designed to facilitate unit testing by allowing you to create and verify expectations on method calls. It is particularly useful for isolating and testing individual components in your codebase. It is inspired in other mocking frameworks as Mockito or Mockk

## Installation

To use `SwiftMock` Add the framework to your Xcode project:

    - Navigate to File › Add Packages… and enter “https://github.com/alopezh/SwiftMock”

	- Change Dependency Rule to Up to Next Minor Version and enter “0.1.0”

    - Click Add Package

    - Select your test target and click Add Package

## Usage

### Creating Mocks

```swift
let taskServiceMock = TaskServiceMock()
let sut = TasksUseCaseImpl(taskService: taskServiceMock)

sut.save(tasks: tasks)
    .sink { saved  in
        // Handle the result
    }
    .store(in: &cancelables)

// Verify that the 'createTask' method was called exactly 2 times
taskServiceMock.verifyCreateTask(called: .exact(2))
```

### Registering Expectations

```swift
let tasks = [Task(id: UUID(), name: "Name1", description: "Desc", done: false, modified: false, new: true),
             Task(id: UUID(), name: "Name2", description: "Desc", done: false, modified: false, new: true)]

taskServiceMock.registerCreateTask(tasks)
```
###  Verifying Method Calls
```swift
sut.save(tasks: tasks)
    .sink { saved  in
        // Handle the result
    }
    .store(in: &cancelables)

// Verify that the 'createTask' method was called exactly 2 times
taskServiceMock.verifyCreateTask(called: .exact(2))
```

### Capturing Parameters
```swift
// Retrieve the captured parameters for the 'createTask' method
let capturedParams = taskServiceMock.paramCaptured("createTask")

// Assert on the captured parameters if needed
XCTAssertEqual(capturedParams?.count, 2)
```
### Handling Asynchronous Calls

`SwiftMock` works seamlessly with asynchronous code using Combine. You can use the `.sink` operator to handle the asynchronous results and verify expectations accordingly.

### Additional Verifications

```swift
// Verify that no unexpected interactions occurred
taskServiceMock.verifyNoMoreInteractions()
```
## Example Test
```swift
// Protocol to mock
protocol TaskService {
	func getTasks() -> AnyPublisher<[Task], Error>
	func updateTask(id: UUID, _ task: Task) -> AnyPublisher<Task, Error>
	func createTask(_ task: Task) -> AnyPublisher<Task, Error>
}

//Mock implementation
class TaskServiceMock: SwiftMock, TaskService {

    init() {
        super.init("TaskApiMock")
    }

    func getTasks() -> AnyPublisher<[Task], Error> {
        call("getTasks") as! AnyPublisher<[Task], Error>
    }

    func updateTask(id: UUID, _ task: Task) -> AnyPublisher<Task, Error> {
        call("updateTask", params: ["task": task]) as! AnyPublisher<Task, Error>
    }
	
	func createTask(_ task: Task) -> AnyPublisher<Task, Error> {
		call("createTask", params: ["task": task]) as! AnyPublisher<Task, Error>
	}

  func registerCreateTask(_ tasks: [Task]) {
        let publisherTasks = tasks.map { Just($0).setFailureType(to: Error.self).eraseToAnyPublisher() }

        registerMock("createTask", responses: publisherTasks )
    }

    func verifyCreateTask(called: VerifyCount = .atLeastOnce) -> MockedFuncCall? {
        verify("createTask", called: called)
    }
}

// Actual Test
class TaskUseCaseTests: XCTestCase {
	private var cancelables: Set<AnyCancellable>!

	private var sut: TasksUseCaseImpl!
	
	private var taskServiceMock: TaskServiceMock!

	override func setUpWithError() throws {
		cancelables = []
		taskServiceMock = TaskServiceMock()
        sut = TasksUseCaseImpl(taskService: taskServiceMock)
    }

	func testGivenNewElementsThenSaveAllOfThem() throws {
	    // Test setup code...

	    let responseReceived = expectation(description: "response received")

	    var savedTasks: [Task]?

	    sut.save(tasks: tasks)
	        .sink { saved  in
	            savedTasks = saved
	            responseReceived.fulfill()
	        }
	        .store(in: &cancelables)

	    waitForExpectations(timeout: 1, handler: nil)

	    // Verify expectations
	    taskServiceMock.verifyCreateTask(called: .exact(2))

	    // Additional assertions...
	}
	
}
```
## Conclusion

`SwiftMock` simplifies the process of mocking and verifying method calls in Swift unit tests. It promotes clean and readable test code, making it easier to maintain and understand your test suite.
