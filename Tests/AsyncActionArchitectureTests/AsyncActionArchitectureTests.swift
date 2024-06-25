import XCTest
@testable import AsyncActionArchitecture

final class AsyncActionArchitectureTests: XCTestCase {
    func testRequestData() async {
        await TestReducer.defaultStore.test(action: .requestData) {
            let expectedState = TestReducer.State()
            expectedState.data = .data
            return expectedState
        }
    }
    
    func testEachActions() async {
        let store = TestReducer.defaultStore
        
        store.testSideEffect(action: .requestData) {
            let expectedState = TestReducer.State()
            expectedState.isLoading = true
            return (expectedState, .run(.loadDataFromServer))
        }
        
        await store.testSideEffect(asyncAction: .loadDataFromServer) {
            .reduceState(.update(data: .data))
        }
        
        store.testSideEffect(action: .update(data: .data)) {
            let expectedState = TestReducer.State()
            expectedState.data = .data
            return (expectedState, .none)
        }
    }
}

struct TestReducer: Reducer {
    static var defaultStore: Store<TestReducer> {
        .init(initialState: .init(), reducer: .init())
    }
    
    enum Failure: Error, Equatable {
        case failedToLoadData
    }
    
    enum Action: Equatable {
        case requestData
        case update(data: String)
        case `throws`(Failure)
    }
    
    enum AsyncAction: Equatable {
        case loadDataFromServer
    }
    
    final class State: Equatable {
        static func == (lhs: State, rhs: State) -> Bool {
            [lhs.data == rhs.data,
             lhs.isLoading == rhs.isLoading]
                .allSatisfy { $0 }
        }
        
        var data: String?
        var error: Failure?
        var isLoading: Bool = false
    }
    
    func reduce(state: State, action: Action) -> Effect<TestReducer> {
        switch action {
        case .requestData:
            state.isLoading = true
            return .run(.loadDataFromServer)
        case .update(let data):
            state.data = data
            state.isLoading = false
            return .none
        case .throws(let error):
            state.error = error
            return .none
        }
    }
    
    func run(action: AsyncAction) async -> Effect<TestReducer> {
        switch action {
        case .loadDataFromServer:
            do {
                let data = try await MockDataLoader.loadDataFromServer()
                return .reduceState(.update(data: data))
            } catch {
                return .reduceState(.throws(.failedToLoadData))
            }
        }
    }
}

fileprivate struct MockDataLoader {
    static func loadDataFromServer() async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return .data
    }
}

fileprivate extension String {
    static let data = "This is data"
}
