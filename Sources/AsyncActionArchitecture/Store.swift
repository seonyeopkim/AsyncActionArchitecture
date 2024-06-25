import XCTest

public final class Store<R: Reducer> {
    private let state: R.State
    private let reducer: R
    
    public init(initialState: R.State, reducer: R) {
        self.state = initialState
        self.reducer = reducer
    }
    
    public func send(action: R.Action) {
        Task { await self.reduceState(action: action) }
    }
    
    public func send(asyncAction: R.AsyncAction) {
        Task { await self.run(action: asyncAction) }
    }
}

public extension Store {
    func state<Value>(_ keyPath: KeyPath<R.State, Value>) -> Value {
        self.state[keyPath: keyPath]
    }
}

public extension Store where R.State: Equatable {
    func test(action: R.Action, expectedState: () -> R.State) async {
        await self.reduceState(action: action)
        XCTAssertEqual(self.state, expectedState())
    }
}

public extension Store where R.State: Equatable, R.Action: Equatable, R.AsyncAction: Equatable {
    func testSideEffect(action: R.Action, expected: () -> (R.State, Effect<R>)) {
        let effect = self.reducer.reduce(state: self.state, action: action)
        let (expectedState, expectedEffect) = expected()
        XCTAssertEqual(self.state, expectedState)
        XCTAssertEqual(effect, expectedEffect)
    }
    
    func testSideEffect(asyncAction: R.AsyncAction, expectedEffect: () -> Effect<R>) async {
        let effect = await self.reducer.run(action: asyncAction)
        XCTAssertEqual(effect, expectedEffect())
    }
}

fileprivate extension Store {
    @MainActor
    func reduceState(action: R.Action) async {
        switch self.reducer.reduce(state: self.state, action: action) {
        case .reduceState(let action): await self.reduceState(action: action)
        case .run(let action): await self.run(action: action)
        case .none: return
        }
    }
    
    func run(action: R.AsyncAction) async {
        switch await self.reducer.run(action: action) {
        case .reduceState(let action): await self.reduceState(action: action)
        case .run(let action): await self.run(action: action)
        case .none: return
        }
    }
}
