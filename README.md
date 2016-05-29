# Flow

Flow is a lightweight Swift library for doing operation oriented programming. It enables you to easily define your own, atomic operations, and also contains an exensive library of ready-to-use operations that can be grouped, sequenced, queued and repeated.

### Operations

Using Flow is all about splitting your code up into multiple atomic pieces - called **operations**. Each operation defines a body of work, that can easily be reused throughout an app or library.

An operation can do anything, synchronously or asynchronously, and its scope is really up to you. The true power of operation oriented programming however, comes when you create groups, sequences and queues out of operations. Operations can potentially make code that is either asynchronous, or where work has to be done in several places, a lot simpler.

## How to use

- Create your own operations by conforming to `FlowOperation` in a custom object. All it needs to do it implement one method that performs it with a completion handler. It’s free to be initialized in whatever way you want, and can be either a `class` or a `struct`.

- Use any of the built-in operations, such as `FlowClosureOperation`, `FlowDelayOperation`, etc.

- Create sequences of operations (that get executed one by one) using `FlowOperationSequence`, groups (that get executed all at once) using `FlowOperationGroup`, or queues (that can be continuously filled with operations) using `FlowOperationQueue`.

## Example

Let’s say we’re building a game and we want to perform a series of animations where a `Player` attacks an `Enemy`, destroys it and then plays a victory animation. This could of course be accomplished with the use of completion handler closures:

```
player.moveTo(enemy.position) {
    player.performAttack() {
        enemy.destroy() {
            player.playVictoryAnimation()
        }
    }
}
```

However, this quickly becomes hard to reason about and debug, especially if we start adding multiple animations that we want to sync. Let’s say we decide to implement a new **spin attack** in our game, that destroys multiple enemies, and we want all enemies to be destroyed before we play the victory animation. We’d have to do something like this:

```
player.moveTo(mainEnemy.position) {
    player.performAttack() {
        var enemiesDestroyed = 0
                
        for enemy in enemies {
            enemy.destroy({
                enemiesDestroyed += 1
                        
                if enemiesDestroyed == enemies.count {
                    player.playVictoryAnimation()
                }
            })
        }
    }
}
```

It becomes clear that the more we add to our animation, the more error prone and hard to debug it becomes. Wouldn’t it be great if our animations (or any other sequence of tasks) could scale gracefully as we make them more and more complex?

Let’s implement the above using Flow instead:

```
let moveOperation = FlowAsyncClosureOperation(closure: {
    player.moveTo(mainEnemy.position, completionHandler: $0)
})
        
let attackOperation = FlowAsyncClosureOperation(closure: {
    player.performAttack($0)
})
        
var destroyEnemiesOperationGroup = FlowOperationGroup()
        
for enemy in enemies {
    let destroyEnemyOperation = FlowAsyncClosureOperation(closure: {
        enemy.destroy($0)
    })
            
    destroyEnemiesOperationGroup.addOperation(destroyEnemyOperation)
}
        
let victoryOperation = FlowClosureOperation(closure: {
    player.playVictoryAnimation()
})
        
let operationSequence = FlowOperationSequence(operations: [
    moveOperation,
    attackOperation,
    destroyEnemiesOperationGroup,
    victoryOperation
])
        
operationSequence.perform()
```

While this code becomes a bit more verbose - it really has some big advantages.

Firstly; we can now use a `FlowOperationGroup` to make sure that all enemy animations are finished before moving on, and by doing this we’ve reduced the state we need to keep within the animation itself.

Secondly; all parts of the animation are now independant operations that don’t have to be aware of each other, making them a lot easier to test & debug - and they can potentially also be reused in other parts of our game.

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

