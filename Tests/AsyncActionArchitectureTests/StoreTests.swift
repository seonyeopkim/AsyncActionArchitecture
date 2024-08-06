@testable import AsyncActionArchitecture
import Combine
import XCTest

final class StoreTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    func testRelayBetweenActionAndAsyncAction() {
        struct TestReducer: Reducer {
            struct State: Equatable {}
            
            enum Action {
                case first
                case third
            }
            
            enum AsyncAction {
                case second
            }
            
            let expectation: XCTestExpectation
            
            func reduce(into state: inout State, action: Action) -> Effect<Action, AsyncAction> {
                switch action {
                case .first:
                    return .run(.second)
                case .third:
                    self.expectation.fulfill()
                    return .none
                }
            }
            
            func run(action: AsyncAction) async -> Effect<Action, AsyncAction> {
                switch action {
                case .second: .send(.third)
                }
            }
        }
        
        // given
        let reducer = TestReducer(expectation: XCTestExpectation())
        let store = Store(reducer: reducer, initialState: .init())
        
        // when
        store._send(.first)
        
        // then
        wait(for: [reducer.expectation], timeout: 1)
    }
    
    func testRelayBetweenActions() {
        struct TestReducer: Reducer {
            struct State: Equatable {}
            struct AsyncAction {}
            
            enum Action {
                case first
                case second
            }
            
            let expectation: XCTestExpectation
            
            func reduce(into state: inout State, action: Action) -> Effect<Action, AsyncAction> {
                switch action {
                case .first:
                    return .send(.second)
                case .second:
                    self.expectation.fulfill()
                    return .none
                }
            }
        }
        
        // given
        let reducer = TestReducer(expectation: XCTestExpectation())
        let store = Store(reducer: reducer, initialState: .init())
        
        // when
        store._send(.first)
        
        // then
        wait(for: [reducer.expectation], timeout: 1)
    }
    
    func testRelayBetweenAsyncActions() {
        struct TestReducer: Reducer {
            struct State: Equatable {}
            struct Action {}
            
            enum AsyncAction {
                case first
                case second
            }
            
            let expectation: XCTestExpectation
            
            func run(action: AsyncAction) async -> Effect<Action, AsyncAction> {
                switch action {
                case .first:
                    return .run(.second)
                case .second:
                    self.expectation.fulfill()
                    return .none
                }
            }
        }
        
        // given
        let reducer = TestReducer(expectation: XCTestExpectation())
        let store = Store(reducer: reducer, initialState: .init())
        
        // when
        store.run(.first)
        
        // then
        wait(for: [reducer.expectation], timeout: 1)
    }
    
    func testAutoThreading() {
        struct TestReducer: Reducer {
            struct AsyncAction {}
            
            struct State: Equatable {
                var isMainThread: Bool?
            }
            
            enum Action: CaseIterable {
                case mainThreadAutoThreadingOn
                case mainThreadAutoThreadingOff
                case nonMainThreadAutoThreadingOn
                case nonMainThreadAutoThreadingOff
            }
            
            let expectation: XCTestExpectation
            
            func reduce(into state: inout State, action: Action) -> Effect<Action, AsyncAction> {
                state.isMainThread = Thread.isMainThread
                self.expectation.fulfill()
                return .none
            }
        }
        
        for action in TestReducer.Action.allCases {
            // given
            let reducer = TestReducer(expectation: XCTestExpectation())
            let store = Store(reducer: reducer, initialState: .init())
            
            // when
            switch action {
            case .mainThreadAutoThreadingOn:
                DispatchQueue.main.async {
                    store.send(action, autoThreading: .on())
                }
            case .mainThreadAutoThreadingOff:
                DispatchQueue.main.async {
                    store.send(action, autoThreading: .off)
                }
            case .nonMainThreadAutoThreadingOn:
                DispatchQueue.global().async {
                    store.send(action, autoThreading: .on())
                }
            case .nonMainThreadAutoThreadingOff:
                DispatchQueue.global().async {
                    store.send(action, autoThreading: .off)
                }
            }
            
            // then
            wait(for: [reducer.expectation], timeout: 1)
            switch action {
            case .mainThreadAutoThreadingOn:
                XCTAssertEqual(store.currentState.isMainThread, true)
            case .mainThreadAutoThreadingOff:
                XCTAssertEqual(store.currentState.isMainThread, true)
            case .nonMainThreadAutoThreadingOn:
                XCTAssertEqual(store.currentState.isMainThread, true)
            case .nonMainThreadAutoThreadingOff:
                XCTAssertEqual(store.currentState.isMainThread, false)
            }
        }
    }
    
    func testPublisherForWholeState() {
        // given
        let store = Store<TestReducer>()
        var stateHistory = [TestReducer.State]()
        store.publisher
            .sink { stateHistory.append($0) }
            .store(in: &self.cancellables)
        
        // when
        store.send(.resetState)
        store.send(.resetState)
        store.send(.logCount)
        store.send(.logCount)
        store.send(.increase)
        store.send(.increase)
        
        //then
        let expectedResult: [TestReducer.State] = [
            .init(counter: 0, log: nil),
            .init(counter: 0, log: "0"),
            .init(counter: 1, log: "0"),
            .init(counter: 2, log: "0")
        ]
        XCTAssertEqual(stateHistory, expectedResult)
    }
    
    func testPublisherForKeyPath() {
        // given
        let store = Store<TestReducer>()
        var countHistory = [Int]()
        var logs = [String?]()
        var duplicatedLogs = [String?]()
        store.publisher(for: \.counter)
            .sink { countHistory.append($0)}
            .store(in: &self.cancellables)
        store.publisher(for: \.log)
            .sink { logs.append($0) }
            .store(in: &self.cancellables)
        store.publisher(for: \.$log)
            .sink { duplicatedLogs.append($0) }
            .store(in: &self.cancellables)
        
        // when
        store.send(.resetState)
        store.send(.resetState)
        store.send(.logCount)
        store.send(.logCount)
        store.send(.increase)
        store.send(.increase)
        
        //then
        XCTAssertEqual(countHistory, [0, 1, 2])
        XCTAssertEqual(logs, [nil, "0"])
        XCTAssertEqual(duplicatedLogs, [nil, "0", "0"])
    }
    
    func testActionTester() {
        struct TestReducer: Reducer {
            struct State: Equatable {}
            struct AsyncAction: Equatable {}
            
            enum Action {
                case action
            }
        }
        
        // given
        let store = Store(reducer: TestReducer(), initialState: .init())
        
        // when
        store.test(action: .action) {
            // then
            XCTAssertEqual($0, .init())
            XCTAssertEqual($1, .none)
        }
    }
    
    func testAsyncActionTester() async {
        struct TestReducer: Reducer {
            struct State: Equatable {}
            struct Action: Equatable {}
            
            enum AsyncAction {
                case asyncAction
            }
        }
        
        // given
        let store = Store(reducer: TestReducer(), initialState: .init())
        
        // when
        await store.test(asyncAction: .asyncAction) {
            // then
            XCTAssertEqual($0, .none)
        }
    }
}

extension Store where R == TestReducer {
    convenience init() {
        self.init(reducer: .init(), initialState: .init())
    }
}

struct TestReducer: Reducer {
    struct AsyncAction {}
    
    struct State: Equatable {
        var counter: Int = .zero
        @AllowDuplicates var log: String?
    }
    
    enum Action {
        case increase
        case logCount
        case resetState
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action, AsyncAction> {
        switch action {
        case .increase: state.counter += 1
        case .logCount: state.log = "\(state.counter)"
        case .resetState: state = .init()
        }
        return .none
    }
}

extension Reducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action, AsyncAction> { .none }
    func run(action: AsyncAction) async -> Effect<Action, AsyncAction> { .none }
}
