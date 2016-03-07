import SpriteKit

/// Flow operation that wraps a SpriteKit action
public class FlowSpriteKitActionOperation: FlowOperation {
    private let action: SKAction
    private let node: SKNode
    
    /// Initialize an instance with an action and a node to perform it on
    public init(action: SKAction, node: SKNode) {
        self.action = action
        self.node = node
    }
    
    public func performWithCompletionHandler(completionHandler: () -> Void) {
        self.node.runAction(self.action, completion: completionHandler)
    }
}

/// Flow operation that preloads a SpriteKit texture atlas
public class FlowSpriteKitTextureAtlasPreloadOperation: FlowOperation {
    private let atlasName: String
    
    /// Initialize an instance with the name of the atlas to preload
    public init(atlasName: String) {
        self.atlasName = atlasName
    }
    
    public func performWithCompletionHandler(completionHandler: () -> Void) {
        let atlas = SKTextureAtlas(named: self.atlasName)
        atlas.preloadWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), completionHandler)
        })
    }
}
