import XCTest

// MARK: - Tests

class FlowTests: XCTestCase {
    func testClosureOperation() {
        var closureCalled = false
        var completionHandlerCalled = false
        
        let operation = FlowClosureOperation(closure: {
            closureCalled = true
        })
        
        operation.performWithCompletionHandler({
            completionHandlerCalled = true
        })
        
        XCTAssertTrue(closureCalled)
        XCTAssertTrue(completionHandlerCalled)
    }
    
    func testAsyncClosureOperation() {
        var closureCalled = false
        var completionHandlerCalled = false
        
        let operation = FlowAsyncClosureOperation(closure: {
            closureCalled = true
            $0()
        })
        
        operation.performWithCompletionHandler({
            completionHandlerCalled = true
        })
        
        XCTAssertTrue(closureCalled)
        XCTAssertTrue(completionHandlerCalled)
    }
    
    func testDelayOperation() {
        let startTimestamp = NSDate().timeIntervalSince1970
        let delay = NSTimeInterval(1)
        let expectation = self.expectationWithDescription("delayOperation")
        
        let operation = FlowDelayOperation(delay: delay)
        operation.performWithCompletionHandler({
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(delay + 0.5, handler: {
            XCTAssertNil($0)
            
            let endTimestamp = NSDate().timeIntervalSince1970
            XCTAssertEqual(floor(endTimestamp - startTimestamp), delay)
        })
    }
    
    func testOperationSequence() {
        var numbersFromClosures = [Int]()
        
        let firstOperation = FlowClosureOperation(closure: {
            numbersFromClosures.append(1)
        })
        
        let secondOperation = FlowClosureOperation(closure: {
            numbersFromClosures.append(2)
        })
        
        let thirdOperation = FlowClosureOperation(closure: {
            numbersFromClosures.append(3)
        })
        
        var completionHandlerCalled = false
        
        let sequence = FlowOperationSequence(operations: [firstOperation, secondOperation, thirdOperation])
        sequence.performWithCompletionHandler({
            completionHandlerCalled = true
        })
        
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertEqual(numbersFromClosures, [1, 2, 3])
    }
    
    func testOperationSequenceIsImmutableWhileRunning() {
        let originalOperation = FlowOperationMock()
        
        var sequence = FlowOperationSequence(operation: originalOperation)
        sequence.performWithCompletionHandler({})
        
        var addedOperationPerformed = false
        
        let addedOperation = FlowClosureOperation(closure: {
            addedOperationPerformed = true
        })
        
        sequence.addOperation(addedOperation)
        originalOperation.complete()
        XCTAssertFalse(addedOperationPerformed)
        
        sequence.performWithCompletionHandler({})
        originalOperation.complete()
        XCTAssertTrue(addedOperationPerformed)
    }
    
    func testOperationGroup() {
        let firstOperation = FlowOperationMock()
        let secondOperation = FlowOperationMock()
        let group = FlowOperationGroup(operations: [firstOperation, secondOperation])
        
        var completionHandlerCalled = false
        
        group.performWithCompletionHandler({
            completionHandlerCalled = true
        })
        
        XCTAssertTrue(firstOperation.started)
        XCTAssertTrue(secondOperation.started)
        
        firstOperation.complete()
        XCTAssertFalse(completionHandlerCalled)
        
        secondOperation.complete()
        XCTAssertTrue(completionHandlerCalled)
    }
    
    func testOperationGroupIsImmutableWhileRunning() {
        let originalOperation = FlowOperationMock()
        
        var group = FlowOperationGroup(operation: originalOperation)
        group.performWithCompletionHandler({})
        
        var addedOperationPerformed = false
        
        let addedOperation = FlowClosureOperation(closure: {
            addedOperationPerformed = true
        })
        
        group.addOperation(addedOperation)
        originalOperation.complete()
        XCTAssertFalse(addedOperationPerformed)
        
        group.performWithCompletionHandler({})
        originalOperation.complete()
        XCTAssertTrue(addedOperationPerformed)
    }
    
    func testOperationQueue() {
        var initialOperationPerformed = false
        
        let initialOperation = FlowClosureOperation(closure: {
            initialOperationPerformed = true
        })
        
        let queue = FlowOperationQueue(operation: initialOperation)
        XCTAssertTrue(initialOperationPerformed)
        
        var queuedOperationPerformed = false
        
        let queuedOperation = FlowClosureOperation(closure: {
            queuedOperationPerformed = true
        })
        
        let blockingOperation = FlowOperationMock()
        
        queue.addOperation(blockingOperation)
        queue.addOperation(queuedOperation)
        
        XCTAssertFalse(queuedOperationPerformed)
        
        blockingOperation.complete()
        
        XCTAssertTrue(queuedOperationPerformed)
    }
    
    func testOperationRepeater() {
        var repeatCount = 0
        
        let incrementCountOperation = FlowClosureOperation(closure: {
            repeatCount += 1
        })
        
        let blockingOperation = FlowOperationMock()
        
        let repeater = FlowOperationRepeater(operations: [incrementCountOperation, blockingOperation])
        XCTAssertTrue(repeater.isStopped)
        XCTAssertEqual(repeatCount, 0)
        
        repeater.start()
        XCTAssertEqual(repeatCount, 1)
        
        blockingOperation.complete()
        blockingOperation.complete()
        blockingOperation.complete()
        XCTAssertEqual(repeatCount, 4)
    }
    
    func testOperationRepeaterWithInterval() {
        let expectation = self.expectationWithDescription("repeater-interval")
        
        let delayOperation = FlowDelayOperation(delay: 1.1)
        delayOperation.performWithCompletionHandler({
            expectation.fulfill()
        })
        
        var repeatCount = 0
        
        let operation = FlowClosureOperation(closure: {
            repeatCount += 1
        })
        
        let repeater = FlowOperationRepeater(operation: operation, interval: 0.25)
        repeater.start()
        
        self.waitForExpectationsWithTimeout(1.2, handler: {
            XCTAssertNil($0)
            XCTAssertEqual(repeatCount, 4)
        })
    }
}

private class FlowOperationMock: FlowOperation {
    var started = false
    var completionHandler: (() -> Void)?
    
    func performWithCompletionHandler(completionHandler: () -> Void) {
        self.started = true
        self.completionHandler = completionHandler
    }
    
    func complete() {
        if let completionHandler = self.completionHandler {
            completionHandler()
        } else {
            assertionFailure()
        }
    }
}
