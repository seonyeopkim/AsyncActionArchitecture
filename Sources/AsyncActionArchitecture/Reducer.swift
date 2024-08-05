public protocol Reducer {
    associatedtype State: Equatable
    associatedtype Action
    associatedtype AsyncAction
    
    func reduce(into state: inout State, action: Action) -> Effect<Action, AsyncAction>
    func run(action: AsyncAction) async -> Effect<Action, AsyncAction>
}
