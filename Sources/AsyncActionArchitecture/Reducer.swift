public protocol Reducer {
    associatedtype Action
    associatedtype AsyncAction
    associatedtype State: AnyObject
    
    func reduce(state: State, action: Action) -> Effect<Self>
    func run(action: AsyncAction) async -> Effect<Self>
}
