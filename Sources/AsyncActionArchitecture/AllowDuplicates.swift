@propertyWrapper
public struct AllowDuplicates<Value> {
    public var wrappedValue: Value {
        didSet { self.version &+= 1 }
    }
    
    public var projectedValue: Self {
        self
    }
    
    private(set) var version = UInt.min
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension AllowDuplicates: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
