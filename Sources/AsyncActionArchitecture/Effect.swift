public enum Effect<R: Reducer> {
    case reduceState(R.Action)
    case run(R.AsyncAction)
    case none
}

extension Effect: Equatable where R.Action: Equatable, R.AsyncAction: Equatable {
    public static func == (lhs: Effect<R>, rhs: Effect<R>) -> Bool {
        switch (lhs, rhs) {
        case (.reduceState(let lhsAction), .reduceState(let rhsAction)):
            lhsAction == rhsAction
        case (.run(let lhsAction), .run(let rhsAction)):
            lhsAction == rhsAction
        case (.none, .none):
            true
        default:
            false
        }
    }
}
