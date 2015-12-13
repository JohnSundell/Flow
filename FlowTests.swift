import XCTest

// MARK: - Tests

class FlowTests: XCTestCase {
    func testClosureOperation() {
        let input = "input"
        
        let expectedOutput = 5
        var actualOutput: Int?
        
        let operation = FlowClosureOperation<String, Int>(closure: { return $0.characters.count })
        operation.performWithInput(input, completionHandler: {
            actualOutput = $0
        })
        
        XCTAssertEqual(actualOutput, expectedOutput)
    }

    func testOperationChain() {
        let stringLengthOperation = StringLengthOperation()
        let stringSplitOperation = AsyncStringReplicationOperation()
        
        let expectation = self.expectationWithDescription("Operation chain")
        
        let expectedOutput = Array(count: 5, repeatedValue: "STRING")
        var actualOutput = [String]()
        
        FlowOperationChain(rootOperation: stringLengthOperation)
            .append(stringSplitOperation)
            .performWithInput("input", completionHandler: {
                actualOutput = $0
                expectation.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(1, handler: {
            XCTAssertNil($0)
            XCTAssertEqual(actualOutput, expectedOutput)
        })
    }
    
    func testOptionalOperationChain() {
        let substringOperation = OptionalSubstringOperation()
        let chain = FlowOperationChain(rootOperation: substringOperation)
        
        let expectedOutput = "St"
        var actualOutput: String?
        
        chain.performWithInput("String", completionHandler: {
            actualOutput = $0
        })
        
        XCTAssertEqual(expectedOutput, actualOutput)
        
        chain.performWithInput(nil, completionHandler: {
            actualOutput = $0
        })
        
        XCTAssertNil(actualOutput)
    }
    
    func testPredicateOperation() {
        let predicateOperation = FlowPredicateOperation(predicate: "Flow", operation: FlowClosureOperation(closure: {
            return $0 + " Operation"
        }))
        
        var completionHandlerInvoked = false
        
        predicateOperation.performWithInput("Not flow", completionHandler: {
            XCTAssertEqual("Not flow", $0)
            completionHandlerInvoked = true
        })
        
        XCTAssertTrue(completionHandlerInvoked)
        completionHandlerInvoked = false
        
        predicateOperation.performWithInput("Flow", completionHandler: {
            XCTAssertEqual("Flow Operation", $0)
            completionHandlerInvoked = true
        })
        
        XCTAssertTrue(completionHandlerInvoked)
    }
    
    func testPredicateOperationDiscardingNonMatchingOutput() {
        let predicateOperation = FlowPredicateOperation(predicate: 5, operation: FlowClosureOperation(closure: {
            return "Flow " + String($0)
        }))
        
        var closureOperationInvoked = false
        
        StringLengthOperation()
            .toChain()
            .append(predicateOperation)
            .append(FlowClosureOperation(closure: {
                XCTAssertEqual($0, 5)
                closureOperationInvoked = true
            }))
            .performWithInput("Hello")
        
        XCTAssertTrue(closureOperationInvoked)
    }
}

// MARK: - Operations

class StringLengthOperation: FlowOperation {
    func performWithInput(input: String, completionHandler: Int -> Void) {
        completionHandler(input.characters.count)
    }
}

class AsyncStringReplicationOperation: FlowOperation {
    func performWithInput(input: Int, completionHandler: [String] -> Void) {
        dispatch_async(dispatch_queue_create("STRING_REPLICATION", nil), {
            completionHandler(Array(count: input, repeatedValue: "STRING"))
        })
    }
}

class OptionalSubstringOperation: FlowOperation {
    func performWithInput(input: String?, completionHandler: String? -> Void) {
        if let input = input {
            completionHandler(input.substringToIndex(input.startIndex.advancedBy(2)))
        } else {
            completionHandler(nil)
        }
    }
}
