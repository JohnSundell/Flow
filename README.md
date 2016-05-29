# Flow

Flow is a lightweight Swift library for doing operation oriented programming. It enables you to easily define your own, atomic operations, and also contains an exensive library of ready-to-use operations that can be grouped, sequenced, queued and repeated.

### Operations

Using Flow is all about splitting your code up into multiple atomic pieces - called **operations**. Each operation defines a body of work, that can easily be reused throughout an app or library.

An operation can do anything, synchronously or asynchronously, and its scope is really up to you. The true power of operation oriented programming however, comes when you create groups, sequences and queues out of operations. Operations can potentially make code that is either asynchronous, or where work has to be done in several places, a lot simpler.

## How to use

- Create your own operations by conforming to `FlowOperation` in a custom object. All it needs to do it implement one method that performs it with a completion handler. It’s free to be initialized in whatever way you want, and can be either a `class` or a `struct`.

- Use any of the built-in operations, such as `FlowClosureOperation`, `FlowDelayOperation`, etc.

- Create sequences of operations (that get executed one by one) using `FlowOperationSequence`, groups (that get executed all at once) using `FlowOperationGroup`, or queues (that can be continuously filled with operations) using `FlowOperationQueue`.

## API reference

### Protocols

**`FlowOperation`**
Used to declare custom operations.

**`FlowOperationCollection`**
Used to declare custom collections of operations.

### Base operations

**`FlowClosureOperation`**
Operation that runs a closure, and returns directly when performed.

**`FlowAsyncClosureOperation`**
Operation that runs a closure, then waits for that closure to call a completion handler before it finishes.

**`FlowDelayOperation`**
Operation that waits for a certain delay before finishing. Useful in sequences and queues.

### Operation collections & utilities

**`FlowOperationGroup`**
Used to group together a series of operations that all get performed at once when the group is performed.

**`FlowOperationSequence`**
Used to sequence a series of operations, performing them one by one once the sequence is performed.

**`FlowOperationQueue`**
Queue that keeps executing the next operation as soon as it becomes idle. New operations can constantly be added.

**`FlowOperationRepeater`**
Used to repeat operations, optionally using an interval in between repeats.

## How is this different from NSOperations?

`NSOperations` are awesome - and are definetly one of the main sources of inspiration for Flow. However, `NSOperations` are quite heavyweight and can potentially take a long time to implement. Flow was designed to have the power of `NSOperations`, but be a lot simpler to implement. It’s also written 100% using Swift - making it ideal for Swift-based projects.

## Installation

**CocoaPods:**

Add the line `pod "Flow"` to your `Podfile`

**Carthage:**

Add the line `github "johnsundell/flow"` to your `Cartfile`

**Manual:**

Clone the repo and drag the file `Flow.swift` into your Xcode project.

**Swift Package Manager:**

Add the line `.Package(url: "https://github.com/johnsundell/flow.git", majorVersion: 1)` to your `Package.swift`

## Hope you enjoy using Flow!

For support, feedback & news about Flow; follow me on Twitter: [@johnsundell](http://twitter.com/johnsundell).

