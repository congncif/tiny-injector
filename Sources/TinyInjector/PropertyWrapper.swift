import Foundation

@propertyWrapper
public struct Injected<Service> {
    private var service: Service
    public init(name: String? = nil, injector: Injector = .root) {
        service = injector.inject(name: name)
    }

    public var wrappedValue: Service {
        get { return service }
        mutating set { service = newValue }
    }

    public var projectedValue: Injected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
}

@propertyWrapper
public struct LazyInjected<Service> {
    private var service: Service!

    public var injector: Injector
    public var name: String?

    public init(name: String? = nil, injector: Injector = .root) {
        self.name = name
        self.injector = injector
    }

    public var isEmpty: Bool {
        return service == nil
    }

    public var wrappedValue: Service {
        mutating get {
            if self.service == nil {
                let locatedService: Service = injector.inject(name: name)
                service = locatedService
            }
            return service
        }
        mutating set { service = newValue }
    }

    public var projectedValue: LazyInjected<Service> {
        get { return self }
        mutating set { self = newValue }
    }

    public mutating func release() {
        service = nil
    }
}

@propertyWrapper
public struct OptionalInjected<Service> {
    private var service: Service?

    public init(name: String? = nil, injector: Injector = .root) {
        service = injector.optionalInject(name: name)
    }

    public var wrappedValue: Service? {
        get { return service }
        mutating set { service = newValue }
    }

    public var projectedValue: OptionalInjected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
}
