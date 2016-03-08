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
    /// The texture atlas that this operation is preloading
    public let atlas: SKTextureAtlas
    
    /// Initialze an instance with a texture atlas to preload
    public init(atlas: SKTextureAtlas) {
        self.atlas = atlas
    }
    
    /// Initialize an instance with the name of the atlas to preload
    public convenience init(atlasName: String) {
        self.init(atlas: SKTextureAtlas(named: atlasName))
    }
    
    public func performWithCompletionHandler(completionHandler: () -> Void) {
        self.atlas.preloadWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), completionHandler)
        })
    }
}
