//
//  PropertyWrapper.swift
//  ServiceRegistry
//
//  Created by NGUYEN CHI CONG on 9/6/21.
//

import Foundation

@propertyWrapper
public struct Injected<Service> {
    private var service: Service
    public init(name: String? = nil, resolver: ServiceResolver = ServiceRegistry.shared) {
        service = resolver.resolve(name: name)
    }

    public init(name: String? = nil, domain: ServiceRegistry.Domain) {
        self.init(name: name, resolver: ServiceRegistry.container(domain: domain))
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

    public var resolver: ServiceResolver
    public var name: String?

    public init(name: String? = nil, resolver: ServiceResolver = ServiceRegistry.shared) {
        self.name = name
        self.resolver = resolver
    }

    public init(name: String? = nil, domain: ServiceRegistry.Domain) {
        self.init(name: name, resolver: ServiceRegistry.container(domain: domain))
    }

    public var isEmpty: Bool {
        return service == nil
    }

    public var wrappedValue: Service {
        mutating get {
            if self.service == nil {
                let locatedService: Service = resolver.resolve(name: name)
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

    public init(name: String? = nil, resolver: ServiceResolver = ServiceRegistry.shared) {
        service = resolver.optionalResolve(name: name)
    }

    public init(name: String? = nil, domain: ServiceRegistry.Domain) {
        self.init(name: name, resolver: ServiceRegistry.container(domain: domain))
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
