import XCTest
@testable import swiftcompress

/// Comprehensive tests for CommandExecutor
///
/// Test Coverage:
/// - Successful command execution
/// - Error handling and translation
/// - Exit code mapping
/// - Multiple command executions
/// - Mock command implementations
/// - Edge cases and error scenarios
final class CommandExecutorTests: XCTestCase {

    // MARK: - Test Fixtures

    var sut: CommandExecutor!
    fileprivate var mockErrorHandler: MockErrorHandler!

    override func setUp() {
        super.setUp()
        mockErrorHandler = MockErrorHandler()
        sut = CommandExecutor(errorHandler: mockErrorHandler)
    }

    override func tearDown() {
        sut = nil
        mockErrorHandler = nil
        super.tearDown()
    }

    // MARK: - Successful Execution Tests

    func testExecute_WhenCommandSucceeds_ReturnsSuccessResult() {
        // Arrange
        let command = MockCommand(shouldSucceed: true)

        // Act
        let result = sut.execute(command)

        // Assert
        switch result {
        case .success(let message):
            XCTAssertNil(message, "Success should return nil message for quiet mode")
            XCTAssertTrue(command.wasExecuted, "Command should have been executed")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testExecute_WhenCommandSucceeds_ExecutesCommandOnce() {
        // Arrange
        let command = MockCommand(shouldSucceed: true)

        // Act
        _ = sut.execute(command)

        // Assert
        XCTAssertEqual(command.executionCount, 1, "Command should be executed exactly once")
    }

    func testExecute_MultipleSuccessfulCommands_EachExecutesIndependently() {
        // Arrange
        let command1 = MockCommand(shouldSucceed: true)
        let command2 = MockCommand(shouldSucceed: true)
        let command3 = MockCommand(shouldSucceed: true)

        // Act
        let result1 = sut.execute(command1)
        let result2 = sut.execute(command2)
        let result3 = sut.execute(command3)

        // Assert
        XCTAssertTrue(command1.wasExecuted)
        XCTAssertTrue(command2.wasExecuted)
        XCTAssertTrue(command3.wasExecuted)

        switch result1 {
        case .success: break
        case .failure: XCTFail("Command 1 should succeed")
        }

        switch result2 {
        case .success: break
        case .failure: XCTFail("Command 2 should succeed")
        }

        switch result3 {
        case .success: break
        case .failure: XCTFail("Command 3 should succeed")
        }
    }

    // MARK: - Error Handling Tests

    func testExecute_WhenCommandThrowsDomainError_ReturnsFailureWithError() {
        // Arrange
        let expectedError = DomainError.invalidAlgorithmName(name: "invalid", supported: ["lzfse", "lz4"])
        let command = MockCommand(shouldSucceed: false, errorToThrow: expectedError)

        // Act
        let result = sut.execute(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error.errorCode, expectedError.errorCode)
        }
    }

    func testExecute_WhenCommandThrowsInfrastructureError_ReturnsFailureWithError() {
        // Arrange
        let expectedError = InfrastructureError.fileNotFound(path: "/test/file.txt")
        let command = MockCommand(shouldSucceed: false, errorToThrow: expectedError)

        // Act
        let result = sut.execute(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error.errorCode, expectedError.errorCode)
        }
    }

    func testExecute_WhenCommandThrowsApplicationError_ReturnsFailureWithError() {
        // Arrange
        let expectedError = ApplicationError.preconditionFailed(message: "Test precondition")
        let command = MockCommand(shouldSucceed: false, errorToThrow: expectedError)

        // Act
        let result = sut.execute(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error.errorCode, expectedError.errorCode)
        }
    }

    func testExecute_WhenCommandThrowsUnexpectedError_WrapsInApplicationError() {
        // Arrange
        struct UnexpectedError: Error {}
        let command = MockCommand(shouldSucceed: false, errorToThrow: UnexpectedError())

        // Act
        let result = sut.execute(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            // Should be wrapped in ApplicationError.commandExecutionFailed
            guard let appError = error as? ApplicationError else {
                XCTFail("Expected ApplicationError")
                return
            }

            switch appError {
            case .commandExecutionFailed(let commandName, _):
                XCTAssertTrue(commandName.contains("MockCommand"))
            default:
                XCTFail("Expected commandExecutionFailed error")
            }
        }
    }

    // MARK: - Error Translation Tests

    func testExecute_WhenMultipleErrorsOccur_HandlesEachIndependently() {
        // Arrange
        let error1 = DomainError.invalidAlgorithmName(name: "test1", supported: ["lzfse", "lz4"])
        let error2 = InfrastructureError.fileNotFound(path: "/test1")
        let error3 = ApplicationError.preconditionFailed(message: "test")

        let command1 = MockCommand(shouldSucceed: false, errorToThrow: error1)
        let command2 = MockCommand(shouldSucceed: false, errorToThrow: error2)
        let command3 = MockCommand(shouldSucceed: false, errorToThrow: error3)

        // Act
        let result1 = sut.execute(command1)
        let result2 = sut.execute(command2)
        let result3 = sut.execute(command3)

        // Assert
        switch result1 {
        case .failure(let error):
            XCTAssertEqual(error.errorCode, error1.errorCode)
        case .success:
            XCTFail("Expected failure for command 1")
        }

        switch result2 {
        case .failure(let error):
            XCTAssertEqual(error.errorCode, error2.errorCode)
        case .success:
            XCTFail("Expected failure for command 2")
        }

        switch result3 {
        case .failure(let error):
            XCTAssertEqual(error.errorCode, error3.errorCode)
        case .success:
            XCTFail("Expected failure for command 3")
        }
    }

    // MARK: - Command State Tests

    func testExecute_CommandStateBeforeExecution_NotExecuted() {
        // Arrange
        let command = MockCommand(shouldSucceed: true)

        // Assert (before act)
        XCTAssertFalse(command.wasExecuted)
        XCTAssertEqual(command.executionCount, 0)
    }

    func testExecute_CommandStateAfterSuccessfulExecution_Executed() {
        // Arrange
        let command = MockCommand(shouldSucceed: true)

        // Act
        _ = sut.execute(command)

        // Assert
        XCTAssertTrue(command.wasExecuted)
        XCTAssertEqual(command.executionCount, 1)
    }

    func testExecute_CommandStateAfterFailedExecution_Executed() {
        // Arrange
        let command = MockCommand(
            shouldSucceed: false,
            errorToThrow: DomainError.invalidAlgorithmName(name: "test", supported: ["lzfse"])
        )

        // Act
        _ = sut.execute(command)

        // Assert
        XCTAssertTrue(command.wasExecuted, "Command should be marked as executed even on failure")
        XCTAssertEqual(command.executionCount, 1)
    }

    // MARK: - Edge Cases

    func testExecute_RepeatedExecutionOfSameCommand_ExecutesEachTime() {
        // Arrange
        let command = MockCommand(shouldSucceed: true)

        // Act
        _ = sut.execute(command)
        _ = sut.execute(command)
        _ = sut.execute(command)

        // Assert
        XCTAssertEqual(command.executionCount, 3, "Command should execute 3 times")
    }

    func testExecute_AlternatingSuccessAndFailure_HandlesCorrectly() {
        // Arrange
        let successCommand = MockCommand(shouldSucceed: true)
        let failureCommand = MockCommand(
            shouldSucceed: false,
            errorToThrow: DomainError.invalidAlgorithmName(name: "test", supported: ["lzfse"])
        )

        // Act
        let result1 = sut.execute(successCommand)
        let result2 = sut.execute(failureCommand)
        let result3 = sut.execute(successCommand)

        // Assert
        switch result1 {
        case .success: break
        case .failure: XCTFail("First execution should succeed")
        }

        switch result2 {
        case .failure: break
        case .success: XCTFail("Second execution should fail")
        }

        switch result3 {
        case .success: break
        case .failure: XCTFail("Third execution should succeed")
        }
    }

    // MARK: - Integration with Different Command Types

    func testExecute_WithDifferentCommandImplementations_AllWork() {
        // Arrange
        let mockCommand = MockCommand(shouldSucceed: true)
        let anotherCommand = AnotherMockCommand(shouldSucceed: true)

        // Act
        let result1 = sut.execute(mockCommand)
        let result2 = sut.execute(anotherCommand)

        // Assert
        switch result1 {
        case .success: break
        case .failure: XCTFail("MockCommand should succeed")
        }

        switch result2 {
        case .success: break
        case .failure: XCTFail("AnotherMockCommand should succeed")
        }
    }
}

// MARK: - Mock Implementations

/// Mock command for testing
private class MockCommand: Command {
    var wasExecuted = false
    var executionCount = 0
    let shouldSucceed: Bool
    let errorToThrow: Error?

    init(shouldSucceed: Bool, errorToThrow: Error? = nil) {
        self.shouldSucceed = shouldSucceed
        self.errorToThrow = errorToThrow
    }

    func execute() throws {
        wasExecuted = true
        executionCount += 1

        if !shouldSucceed {
            throw errorToThrow ?? DomainError.invalidAlgorithmName(name: "default-error", supported: ["lzfse"])
        }
    }
}

/// Alternative mock command implementation
private class AnotherMockCommand: Command {
    let shouldSucceed: Bool

    init(shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
    }

    func execute() throws {
        if !shouldSucceed {
            throw DomainError.invalidAlgorithmName(name: "another-mock-error", supported: ["lzfse"])
        }
    }
}

/// Mock error handler for testing
fileprivate class MockErrorHandler: ErrorHandlerProtocol {
    var handleCallCount = 0
    var lastErrorHandled: Error?

    func handle(_ error: Error) -> UserFacingError {
        handleCallCount += 1
        lastErrorHandled = error

        // Return a simple user-facing error
        return UserFacingError(
            message: "Test error: \(error.localizedDescription)",
            exitCode: 1,
            shouldPrintStackTrace: false
        )
    }
}
