import Foundation

public protocol Injecting {
    var injector: Injector { get }
}

public extension Injecting {
    var injector: Injector { .root }
}

public typealias InjectingFactory<Service> = (Injector) -> Service?
public typealias SimpleInjectingFactory<Service> = () -> Service?

public final class Injector {
    public init(parent: Injector? = nil) {
        self.parent = parent
    }

    public static var root = Injector()

    public func makeChild() -> Injector {
        Injector(parent: self)
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, _ serviceFactory: @escaping InjectingFactory<Service>) -> RegistrationOptions<Service> {
        lock.lock()
        defer {
            lock.unlock()
        }

        let key = registrationKey(subject: Service.self, name: name)
        registrations[key] = serviceFactory

        return RegistrationOptions<Service>(injector: self)
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, _ serviceFactory: @escaping SimpleInjectingFactory<Service>) -> RegistrationOptions<Service> {
        let factory: InjectingFactory<Service> = { _ in
            serviceFactory()
        }
        return register(withName: name, factory)
    }

    public func optionalInject<Service>(implementationOf _: Service.Type = Service.self, name: String? = nil) -> Service? {
        lock.lock()
        defer {
            lock.unlock()
        }

        let factory: InjectingFactory<Service>? = locateFactory(name: name)
        return factory?(self)
    }

    public func inject<Service>(implementationOf _: Service.Type = Service.self, name: String? = nil) -> Service {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let factory: InjectingFactory<Service> = locateFactory(name: name) else {
            preconditionFailure("\(String(describing: Service.self)) not registered. To register service \(Service.self) use injector.register().")
        }

        guard let service = factory(self) else {
            preconditionFailure("\(String(describing: Service.self)) not resolved. To disambiguate optionals use injector.optionalInject().")
        }

        return service
    }

    private let lock = NSRecursiveLock()
    private var registrations: [String: Any] = [:]
    private var parent: Injector?
}

private extension Injector {
    func locateFactory<Service>(name: String?) -> InjectingFactory<Service>? {
        let key = registrationKey(subject: Service.self, name: name)

        var factoryRegistrations: [String: Any] = [:]

        var cursor: Injector? = self
        while let iCursor = cursor {
            factoryRegistrations.merge(iCursor.registrations) { child, _ in child }
            cursor = iCursor.parent
        }
        return factoryRegistrations[key] as? InjectingFactory<Service>
    }

    func registrationKey<Service>(subject _: Service.Type, name: String?) -> String {
        if let name = name {
            return String(describing: Service.self) + "." + name
        }
        return String(describing: Service.self)
    }
}

public final class RegistrationOptions<Service> {
    weak var injector: Injector?

    init(injector: Injector) {
        self.injector = injector
    }

    @discardableResult
    public func implements<ProjectedType>(_: ProjectedType.Type,
                                          name: String? = nil) -> RegistrationOptions<Service> {
        injector?.register { injector -> ProjectedType? in
            let service: Service? = injector.optionalInject(name: name)
            return service as? ProjectedType
        }
        return self
    }
}
