/**
 *  Flow - Operation Oriented Programming in Swift
 *
 *  For usage, see documentation of the classes/symbols listed in this file, as well
 *  as the guide available at: github.com/johnsundell/flow
 *
 *  Copyright (c) 2015 John Sundell. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

// MARK: - API

/**
 *  Protocol used to define a Flow Operation
 *
 *  An operation takes any input, and produces any output that is passed to a completion
 *  handler once the operation was completed.
 *
 *  There are no constraints on how an operation choses to do its work. It can be synchronous
 *  or asynchronous, and be setup with any dependencies it needs.
 */
public protocol FlowOperation {
    /// The type of input that the operation accepts. May be an optional.
    typealias Input
    /// The type of output that the operation produces. May be an optional.
    typealias Output
    
    /**
     *  Perform the operation
     *
     *  @param input The input to use to perform the operation
     *  @param completionHandler A closure that the operation must call when it completed
     *         or failed. Must be called on the application's main queue.
     */
    func performWithInput(input: Input, completionHandler: Output -> Void)
}

/// Operation that performs a closure synchronously given any input/output combination
public class FlowClosureOperation<I, O>: FlowOperation {
    private let closure: I -> O
    
    public init(closure: I -> O) {
        self.closure = closure
    }
    
    public func performWithInput(input: I, completionHandler: O -> Void) {
        completionHandler(self.closure(input))
    }
}

/**
 *  Protocol defining the public API of a chain of operations
 *
 *  A chain is a queue of operations that execute serially on the application's main queue.
 *  To create a chain, initialize an instance of `FlowOperationChain` with a root operation.
 */
public protocol FlowOperationChainAPI: class, FlowOperation {
    /// The type of the chain's root operation
    typealias RootOperationType: FlowOperation
    /// The type of the operation currently located at the end of the chain
    typealias CurrentOperationType: FlowOperation
    
    /**
     *  Append an operation to the chain
     *
     *  @param operation The operation to append. It must accept an input that is of the same
     *         type as the previous operation's output.
     *
     *  @return A new operation chain that includes the appended operation
     */
    func append<O: FlowOperation where O.Input == CurrentOperationType.Output>(operation: O) -> FlowOperationChainLink<RootOperationType, O>
    
    /**
     *  Append a closure operation to the chain
     *
     *  @param closure The closure that forms the operation. It must accept an input that is of
     *         the same type as the previous operation's output.
     *
     *  @return A new operation chain that includes the appended operation
     */
    func appendClosure<O>(closure: CurrentOperationType.Output -> O) -> FlowOperationChainLink<RootOperationType, FlowClosureOperation<CurrentOperationType.Output, O>>
    
    /**
     *  Perform all operations in the chain in sequential order
     *
     *  @param input The input to use to perform the first operation of the chain
     *  @param completionHandler A closure to execue once all operations in the queue have
     *         finished. The completion handler will always be invoked on the application's
     *         main queue and be passed any output that the last operation produced.
     */
    func performWithInput(input: RootOperationType.Input, completionHandler: (CurrentOperationType.Output -> Void)?)
}

/// Default implementations for FlowOperationChainAPI
public extension FlowOperationChainAPI {
    func appendClosure<O>(closure: CurrentOperationType.Output -> O) -> FlowOperationChainLink<RootOperationType, FlowClosureOperation<CurrentOperationType.Output, O>> {
        return self.append(FlowClosureOperation(closure: closure))
    }
}

/**
 *  Concrete implementation of an operation chain, use this class to create a chain
 *
 *  For more information, see the documentation for `FlowOperationChainAPI`, that defines
 *  this class' public API.
 */
public class FlowOperationChain<T: FlowOperation>: FlowOperationChainAPI {
    public typealias RootOperationType = T
    public typealias CurrentOperationType = T
    
    private let operation: T
    private var nextLink: FlowAnyOperationChainLink?
    
    public init(rootOperation: T) {
        self.operation = rootOperation
    }
    
    public func append<O: FlowOperation where O.Input == T.Output>(operation: O) -> FlowOperationChainLink<T, O> {
        return self._append(operation)
    }
    
    public func performWithInput(input: T.Input, completionHandler: (T.Output -> Void)? = nil) {
        self._performWithInput(input, completionHandler: completionHandler)
    }
    
    public func performWithInput(input: T.Input, completionHandler: T.Output -> Void) {
        self._performWithInput(input, completionHandler: completionHandler)
    }
}

/**
 *  Class representing a link in an operation chain
 *
 *  For more information, see the documentation for `FlowOperationChainAPI`, that defines
 *  this class' public API.
 *
 *  You don't create instances of this class directly, instead they are the product of
 *  appending an operation to an instance of `FlowOperationChain`.
 */
public class FlowOperationChainLink<R: FlowOperation, C: FlowOperation>: FlowOperationChainAPI {
    public typealias RootOperationType = R
    public typealias CurrentOperationType = C
    
    private let operation: C
    private let rootLink: FlowOperationChain<R>
    private var nextLink: FlowAnyOperationChainLink?
    
    private init(operation: C, rootLink: FlowOperationChain<R>) {
        self.operation = operation
        self.rootLink = rootLink
    }
    
    public func append<O: FlowOperation where O.Input == C.Output>(operation: O) -> FlowOperationChainLink<R, O> {
        return self._append(operation)
    }
    
    public func performWithInput(input: R.Input, completionHandler: (C.Output -> Void)? = nil) {
        self._performWithInput(input, completionHandler: completionHandler)
    }
    
    public func performWithInput(input: R.Input, completionHandler: C.Output -> Void) {
        self._performWithInput(input, completionHandler: completionHandler)
    }
}

// MARK: - Private

private protocol FlowOperationChainPrivateAPI: FlowOperationChainAPI {
    var rootLink: FlowOperationChain<RootOperationType> { get }
    var nextLink: FlowAnyOperationChainLink? { get set }
}

extension FlowOperationChainPrivateAPI {
    func _append<O: FlowOperation where O.Input == CurrentOperationType.Output>(operation: O) -> FlowOperationChainLink<RootOperationType, O> {
        let nextLink = FlowOperationChainLink<RootOperationType, O>(operation: operation, rootLink: self.rootLink)
        self.nextLink = nextLink
        return nextLink
    }
    
    func _performWithInput(input: RootOperationType.Input, completionHandler: (CurrentOperationType.Output -> Void)?) {
        self.rootLink.operation.performWithInput(input, completionHandler: {
            if let nextLink = self.rootLink.nextLink {
                nextLink.performOperationWithInput($0, onAllComplete: {
                    completionHandler?($0 as! CurrentOperationType.Output)
                })
            } else {
                completionHandler?($0 as! CurrentOperationType.Output)
            }
        })
    }
}

extension FlowOperationChain: FlowOperationChainPrivateAPI {
    var rootLink: FlowOperationChain<T> { return self }
}

extension FlowOperationChainLink: FlowOperationChainPrivateAPI { }

private protocol FlowAnyOperationChainLink {
    func performOperationWithInput(input: Any, onAllComplete: Any -> Void)
}

extension FlowOperationChainLink: FlowAnyOperationChainLink {
    private func performOperationWithInput(input: Any, onAllComplete: Any -> Void) {
        self.operation.performWithInput(input as! C.Input, completionHandler: {
            if let nextLink = self.nextLink {
                nextLink.performOperationWithInput($0, onAllComplete: onAllComplete)
            } else {
                onAllComplete($0)
            }
        })
    }
}
