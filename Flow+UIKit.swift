import UIKit

/// Flow operation that performs a UIKit animation
public class FlowUIAnimationOperation: FlowOperation {
    private let duration: NSTimeInterval
    private let animations: () -> Void
    private let delay: NSTimeInterval
    private let options: UIViewAnimationOptions
    
    /// Initialize an instance with a series of animation parameters, and a block containing animations
    public init(duration: NSTimeInterval, delay: NSTimeInterval = 0, options: UIViewAnimationOptions = [], animations: () -> Void) {
        self.duration = duration
        self.animations = animations
        self.delay = delay
        self.options = options
    }
    
    public func performWithCompletionHandler(completionHandler: () -> Void) {
        UIView.animateWithDuration(self.duration,
            delay: self.delay,
            options: self.options,
            animations: self.animations,
            completion: {
                $0
                completionHandler()
            }
        )
    }
}
