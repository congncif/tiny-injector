import Foundation

public typealias ServiceRegistration<Service> = (ServiceRegistry) -> Service?

public final class ServiceRegistry {
    public struct Domain: Hashable, RawRepresentable, Equatable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let shared = Domain(rawValue: "___SHARED___")
    }

    private static var containers: [Domain: ServiceRegistry] = [:]

    public static func container(_ domain: Domain = .shared) -> ServiceRegistry {
        if let registry = containers[domain] {
            return registry
        }

        var newRegistry: ServiceRegistry
        if domain != .shared {
            newRegistry = ServiceRegistry(parent: .container(.shared))
        } else {
            newRegistry = ServiceRegistry()
        }
        containers[domain] = newRegistry
        return newRegistry
    }

    public init(parent: ServiceRegistry? = nil) {
        self.parent = parent
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service> {
        lock.lock()
        defer {
            lock.unlock()
        }

        let key = registrationKey(subject: Service.self, name: name)
        registrations[key] = serviceRegistration

        return RegistrationOptions<Service>(registry: self)
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, _ serviceRegistration: @escaping () -> Service?) -> RegistrationOptions<Service> {
        let registration: ServiceRegistration<Service> = { _ in
            serviceRegistration()
        }
        return register(withName: name, registration)
    }

    public func optionalResolve<Service>(implementationOf _: Service.Type = Service.self, name: String? = nil) -> Service? {
        lock.lock()
        defer {
            lock.unlock()
        }

        let factory: ServiceRegistration<Service>? = locateRegistration(name: name)
        return factory?(self)
    }

    public func resolve<Service>(implementationOf _: Service.Type = Service.self, name: String? = nil) -> Service {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let factory: ServiceRegistration<Service> = locateRegistration(name: name) else {
            preconditionFailure("\(String(describing: Service.self)) isn't registered yet.")
        }

        guard let service = factory(self) else {
            preconditionFailure("\(String(describing: Service.self)) cannot be resolved.")
        }

        return service
    }

    private let lock = NSRecursiveLock()
    private var registrations: [String: Any] = [:]
    private var parent: ServiceRegistry?
}

private extension ServiceRegistry {
    func locateRegistration<Service>(name: String?) -> ServiceRegistration<Service>? {
        let key = registrationKey(subject: Service.self, name: name)

        var factoryRegistrations: [String: Any] = [:]

        var cursor: ServiceRegistry? = self
        while let iCursor = cursor {
            factoryRegistrations.merge(iCursor.registrations) { child, _ in child }
            cursor = iCursor.parent
        }
        return factoryRegistrations[key] as? ServiceRegistration<Service>
    }

    func registrationKey<Service>(subject _: Service.Type, name: String?) -> String {
        if let name = name {
            return String(describing: Service.self) + "." + name
        }
        return String(describing: Service.self)
    }
}

public final class RegistrationOptions<Service> {
    weak var registry: ServiceRegistry!

    init(registry: ServiceRegistry) {
        self.registry = registry
    }

    @discardableResult
    public func implements<ProjectedType>(_: ProjectedType.Type,
                                          name: String? = nil) -> RegistrationOptions<Service> {
        registry?.register { internalRegistry -> ProjectedType? in
            let service: Service? = internalRegistry.optionalResolve(name: name)
            return service as? ProjectedType
        }
        return self
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service> {
        registry.register(withName: name, serviceRegistration)
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, _ serviceRegistration: @escaping () -> Service?) -> RegistrationOptions<Service> {
        registry.register(withName: name, serviceRegistration)
    }
}
