import XCTest
import Flow

// MARK: - Tests

class FlowTests: XCTestCase {
    func testClosureOperation() {
        var closureCalled = false
        var completionHandlerCalled = false
        
        let operation = FlowClosureOperation(closure: {
            closureCalled = true
        })
        
        operation.perform(completionHandler: {
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
        
        operation.perform(completionHandler: {
            completionHandlerCalled = true
        })
        
        XCTAssertTrue(closureCalled)
        XCTAssertTrue(completionHandlerCalled)
    }
    
    func testDelayOperation() {
        let startTimestamp = NSDate().timeIntervalSince1970
        let delay = TimeInterval(1)
        let expectation = self.expectation(withDescription: "delayOperation")
        
        let operation = FlowDelayOperation(delay: delay)
        operation.perform(completionHandler: {
            expectation.fulfill()
        })
        
        self.waitForExpectations(withTimeout: delay + 0.5, handler: {
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
        sequence.perform(completionHandler: {
            completionHandlerCalled = true
        })
        
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertEqual(numbersFromClosures, [1, 2, 3])
    }
    
    func testOperationSequenceIsImmutableWhileRunning() {
        let originalOperation = FlowOperationMock()
        
        var sequence = FlowOperationSequence(operation: originalOperation)
        sequence.perform(completionHandler: {})
        
        var addedOperationPerformed = false
        
        let addedOperation = FlowClosureOperation(closure: {
            addedOperationPerformed = true
        })
        
        sequence.add(operation: addedOperation)
        originalOperation.complete()
        XCTAssertFalse(addedOperationPerformed)
        
        sequence.perform(completionHandler: {})
        originalOperation.complete()
        XCTAssertTrue(addedOperationPerformed)
    }
    
    func testOperationGroup() {
        let firstOperation = FlowOperationMock()
        let secondOperation = FlowOperationMock()
        let group = FlowOperationGroup(operations: [firstOperation, secondOperation])
        
        var completionHandlerCalled = false
        
        group.perform(completionHandler: {
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
        group.perform(completionHandler: {})
        
        var addedOperationPerformed = false
        
        let addedOperation = FlowClosureOperation(closure: {
            addedOperationPerformed = true
        })
        
        group.add(operation: addedOperation)
        originalOperation.complete()
        XCTAssertFalse(addedOperationPerformed)
        
        group.perform(completionHandler: {})
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
        
        queue.add(operation: blockingOperation)
        queue.add(operation: queuedOperation)
        
        XCTAssertFalse(queuedOperationPerformed)
        
        blockingOperation.complete()
        
        XCTAssertTrue(queuedOperationPerformed)
    }
    
    func testObservingOperationQueue() {
        let operation = FlowOperationMock()
        let observer = FlowOperationQueueObserverMock()
        
        let queue = FlowOperationQueue(operation: operation)
        queue.add(observer: observer)
        
        operation.complete()
        XCTAssertEqual(observer.numberOfTimesQueueBecameEmpty, 1)
        
        queue.add(operation: operation)
        XCTAssertEqual(observer.startedOperations.count, 1)
        XCTAssertTrue(observer.startedOperations.first as? AnyObject === operation)
        
        operation.complete()
        XCTAssertEqual(observer.numberOfTimesQueueBecameEmpty, 2)
        
        queue.remove(observer: observer)
        
        queue.add(operation: operation)
        XCTAssertEqual(observer.startedOperations.count, 1)
        XCTAssertTrue(observer.startedOperations.first as? AnyObject === operation)
        
        operation.complete()
        XCTAssertEqual(observer.numberOfTimesQueueBecameEmpty, 2)
    }
    
    func testPausingOperationQueue() {
        let queue = FlowOperationQueue()
        queue.paused = true
        
        let operation = FlowOperationMock()
        queue.add(operation: operation)
        XCTAssertFalse(operation.started)
        
        queue.paused = false
        XCTAssertTrue(operation.started)
    }
    
    func testUnpausingEmptyOperationQueueDoesNotNotifyObservers() {
        let observer = FlowOperationQueueObserverMock()
        
        let queue = FlowOperationQueue()
        queue.paused = true
        queue.add(observer: observer)
        
        queue.paused = false
        XCTAssertEqual(observer.numberOfTimesQueueBecameEmpty, 0)
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
        let expectation = self.expectation(withDescription: "repeater-interval")
        
        let delayOperation = FlowDelayOperation(delay: 1.1)
        delayOperation.perform(completionHandler: {
            expectation.fulfill()
        })
        
        var repeatCount = 0
        
        let operation = FlowClosureOperation(closure: {
            repeatCount += 1
        })
        
        let repeater = FlowOperationRepeater(operation: operation, interval: 0.25)
        repeater.start()
        
        self.waitForExpectations(withTimeout: 5, handler: {
            XCTAssertNil($0)
            XCTAssertEqual(repeatCount, 5)
        })
    }
    
    func testAddingMultipleOperationsToCollection() {
        let operationA = FlowOperationMock()
        let operationB = FlowOperationMock()
        let operationC = FlowOperationMock()
        
        var collection = FlowOperationGroup()
        collection.add(operations: [operationA, operationB, operationC])
        collection.perform()
        
        XCTAssertTrue(operationA.started)
        XCTAssertTrue(operationB.started)
        XCTAssertTrue(operationC.started)
    }
}

// MARK: - Mocks

private class FlowOperationMock: FlowOperation {
    var started = false
    var completionHandler: (() -> Void)?
    
    func perform(completionHandler: () -> Void) {
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

private class FlowOperationQueueObserverMock: FlowOperationQueueObserver {
    var startedOperations = [FlowOperation]()
    var numberOfTimesQueueBecameEmpty = 0
    
    private func operationQueue(_ queue: FlowOperationQueue, willStartPerformingOperation operation: FlowOperation) {
        self.startedOperations.append(operation)
    }
    
    private func operationQueueDidBecomeEmpty(_ queue: FlowOperationQueue) {
        self.numberOfTimesQueueBecameEmpty += 1
    }
}
