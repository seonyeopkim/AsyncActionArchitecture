public enum Effect<Action, AsyncAction> {
    case none
    case send(Action)
    case run(AsyncAction, TaskPriority? = nil)
}

extension Effect: Equatable where Action: Equatable, AsyncAction: Equatable {}
