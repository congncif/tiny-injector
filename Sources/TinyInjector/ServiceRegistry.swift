//
//  ServiceRegistry.swift
//  ServiceRegistry
//
//  Created by NGUYEN CHI CONG on 9/6/21.
//

import Foundation

public protocol ServiceRegistrar {
    @discardableResult
    func register<Service>(withName name: String?, scope: InstanceScope, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service>
}

public extension ServiceRegistrar {
    @discardableResult
    func register<Service>(scope: InstanceScope = .default, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service> {
        register(withName: nil, scope: scope, serviceRegistration)
    }

    @discardableResult
    func register<Service>(withName name: String? = nil, scope: InstanceScope = .default, _ serviceRegistration: @escaping () -> Service?) -> RegistrationOptions<Service> {
        let registration: ServiceRegistration<Service> = { _ in
            serviceRegistration()
        }
        return register(withName: name, scope: scope, registration)
    }
}

public protocol ServiceResolver: AnyObject {
    func optionalResolve<Service>(implementationOf _: Service.Type, name: String?) -> Service?
    func resolve<Service>(implementationOf _: Service.Type, name: String?) -> Service
}

public extension ServiceResolver {
    func optionalResolve<Service>(name: String? = nil) -> Service? {
        optionalResolve(implementationOf: Service.self, name: name)
    }

    func resolve<Service>(name: String? = nil) -> Service {
        resolve(implementationOf: Service.self, name: name)
    }
}

public typealias ServiceRegistration<Service> = (ServiceResolver) -> Service?

public final class ServiceRegistry: ServiceRegistrar, ServiceResolver {
    public struct Domain: Hashable, RawRepresentable, Equatable {
        public let rawValue: AnyHashable

        public init(rawValue: AnyHashable) {
            self.rawValue = rawValue
        }

        public static let shared = Domain(rawValue: "___SHARED___")
    }

    private(set) static var containers: [Domain: ServiceRegistry] = [:]

    public static func container(domain: Domain = .shared) -> ServiceRegistry {
        if let registry = containers[domain] {
            return registry
        }

        var newRegistry: ServiceRegistry
        if domain != .shared {
            newRegistry = ServiceRegistry(parent: .container(domain: .shared))
        } else {
            newRegistry = ServiceRegistry()
        }
        containers[domain] = newRegistry
        return newRegistry
    }

    public static var shared: ServiceRegistry {
        return container(domain: .shared)
    }

    public init(parent: ServiceRegistry? = nil) {
        self.parent = parent
    }

    @discardableResult
    public func register<Service>(withName name: String?, scope: InstanceScope, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service> {
        lock.lock()
        defer {
            lock.unlock()
        }

        let key = registrationKey(subject: Service.self, name: name)
        let reg = ServiceLocator(resolver: self, registration: serviceRegistration, instanceScope: scope)
        registrations[key] = reg

        return RegistrationOptions<Service>(registry: self)
    }

    @discardableResult
    public func register<Service, ServiceType>(_: ServiceType.Type, withName name: String? = nil, scope: InstanceScope, _ serviceRegistration: @escaping () -> Service?) -> RegistrationOptions<ServiceType> {
        register(withName: name, scope: scope) {
            serviceRegistration() as? ServiceType
        }
    }

    public func optionalResolve<Service>(implementationOf _: Service.Type, name: String?) -> Service? {
        lock.lock()
        defer {
            lock.unlock()
        }

        let factory: ServiceLocator<Service>? = locateRegistration(name: name)
        return factory?.makeService()
    }

    public func optionalResolve<Service>(_ serviceType: Service.Type, name: String? = nil) -> Service? {
        optionalResolve(implementationOf: serviceType, name: name)
    }

    public func resolve<Service>(implementationOf _: Service.Type, name: String?) -> Service {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let factory: ServiceLocator<Service> = locateRegistration(name: name) else {
            preconditionFailure("\(String(describing: Service.self)) isn't registered yet.")
        }

        guard let service = factory.makeService() else {
            preconditionFailure("\(String(describing: Service.self)) cannot be resolved.")
        }

        return service
    }

    public func resolve<Service>(_ serviceType: Service.Type, name: String? = nil) -> Service {
        resolve(implementationOf: serviceType, name: name)
    }

    private let lock = NSRecursiveLock()
    private(set) var registrations: [AnyHashable: Any] = [:]
    private(set) weak var parent: ServiceRegistry?
}

internal extension ServiceRegistry {
    func locateRegistration<Service>(name: String?) -> ServiceLocator<Service>? {
        let key = registrationKey(subject: Service.self, name: name)

        var factoryRegistrations: [AnyHashable: Any] = [:]

        var cursor: ServiceRegistry? = self
        while let iCursor = cursor {
            factoryRegistrations.merge(iCursor.registrations) { child, _ in child }
            cursor = iCursor.parent
        }
        return factoryRegistrations[key] as? ServiceLocator<Service>
    }

    func registrationKey<Service>(subject _: Service.Type, name: String?) -> AnyHashable {
        if let name = name {
            var hasher = Hasher()
            hasher.combine(ObjectIdentifier(Service.self))
            hasher.combine(name)
            return hasher.finalize()
        }
        return ObjectIdentifier(Service.self).hashValue
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
    public func register<Service>(withName name: String? = nil, scope: InstanceScope = .default, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service> {
        registry.register(withName: name, scope: scope, serviceRegistration)
    }

    @discardableResult
    public func register<Service>(withName name: String? = nil, scope: InstanceScope = .default, _ serviceRegistration: @escaping () -> Service?) -> RegistrationOptions<Service> {
        registry.register(withName: name, scope: scope, serviceRegistration)
    }
}

public enum InstanceScope {
    case `default`
    case shared
    case cached
}

final class ServiceLocator<Service> {
    init(resolver: ServiceResolver, registration: @escaping ServiceRegistration<Service>, instanceScope: InstanceScope) {
        self.resolver = resolver
        self.factory = registration
        self.instanceScope = instanceScope
    }

    weak var resolver: ServiceResolver!

    let factory: ServiceRegistration<Service>
    let instanceScope: InstanceScope

    func makeService() -> Service? {
        switch instanceScope {
        case .default:
            return factory(resolver)
        case .shared:
            return locateService(preferWeakRef: false)
        case .cached:
            return locateService(preferWeakRef: true)
        }
    }

    private func locateService(preferWeakRef: Bool) -> Service? {
        lock.lock()
        defer { lock.unlock() }

        if let instance = box.unboxed() {
            return instance
        } else {
            if let newService = factory(resolver) {
                setScopedInstance(newService, preferWeakRef: preferWeakRef)
                return newService
            }
            return nil
        }
    }

    func setScopedInstance(_ service: Service, preferWeakRef: Bool) {
        lock.lock()
        box.put(service: service, preferWeakRef: preferWeakRef)
        lock.unlock()
    }

    let lock = NSRecursiveLock()
    let box: ServiceBox<Service> = ServiceBox()
}

final class ServiceBox<Service> {
    weak var object: AnyObject?
    var value: Any?

    func put(service: Service, preferWeakRef: Bool = true) {
        if let service = service as? AnyObject {
            if preferWeakRef {
                object = service
            } else {
                value = service
            }
        } else {
            value = service
        }
    }

    func unboxed() -> Service? {
        if let object = object as? Service {
            return object
        } else if let value = value as? Service {
            return value
        }
        return nil
    }
}
