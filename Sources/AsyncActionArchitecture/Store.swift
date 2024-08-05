import Combine
import Foundation

public final class Store<R: Reducer> {
    public var currentState: R.State {
        self.state
    }
    @Published private var state: R.State
    private let reducer: R
    
    public init(reducer: R, initialState: R.State) {
        self.reducer = reducer
        self.state = initialState
    }
}

public extension Store {
    var publisher: AnyPublisher<R.State, Never> {
        self.$state
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func publisher<Value: Equatable>(for keyPath: KeyPath<R.State, Value>) -> AnyPublisher<Value, Never> {
        self.$state
            .map(keyPath)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func publisher<Value>(for keyPath: KeyPath<R.State, AllowDuplicates<Value>>) -> AnyPublisher<Value, Never> {
        self.$state
            .map(keyPath)
            .removeDuplicates { $0.version == $1.version }
            .map(\.wrappedValue)
            .eraseToAnyPublisher()
    }
}

extension Store {
    public enum AutoThreading {
        case on(TaskPriority? = nil)
        case off
    }
    
    public func send(_ action: R.Action, autoThreading: AutoThreading = .off) {
        guard case .on(let priority) = autoThreading,
              !Thread.isMainThread else {
            self._send(action)
            self.issueNonMainThreadRuntimeWarningIfNeeded()
            return
        }
        
        Task(priority: priority) {
            await MainActor.run {
                self._send(action)
                self.issueAutoThreadingRuntimeWarning()
            }
        }
    }
    
    public func run(_ action: R.AsyncAction, priority: TaskPriority? = nil) {
        Task(priority: priority) {
            switch await self.reducer.run(action: action) {
            case .none:
                return
            case .send(let action):
                await MainActor.run {
                    self._send(action)
                }
            case .run(let action, let priority):
                self.run(action, priority: priority)
            }
        }
    }

    func _send(_ action: R.Action) {
        switch self.reducer.reduce(into: &self.state, action: action) {
        case .none:
            return
        case .send(let action):
            self._send(action)
        case .run(let action, let priority):
            self.run(action, priority: priority)
        }
    }
}

public extension Store {
    func test(action: R.Action, result: (R.State, Effect<R.Action, R.AsyncAction>) -> Void) {
        let effect = self.reducer.reduce(into: &self.state, action: action)
        result(self.state, effect)
    }
    
    func test(asyncAction: R.AsyncAction, result: (Effect<R.Action, R.AsyncAction>) -> Void) async {
        result(await self.reducer.run(action: asyncAction))
    }
}

extension Store {
    func issueNonMainThreadRuntimeWarningIfNeeded() {
        if Thread.isMainThread {
            return
        }
        
        // TODO: Issue a non main thread runtime warning
    }
    
    func issueAutoThreadingRuntimeWarning() {
        // TODO: Issue a auto threading runtime warning
    }
}
