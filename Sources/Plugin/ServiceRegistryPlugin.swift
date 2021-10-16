//
//  ServiceRegistryPlugin.swift
//  SRPlugin
//
//  Created by NGUYEN CHI CONG on 9/30/21.
//

import Foundation

public protocol MainRegistryComponent: ServiceRegistrar {
    func registrar(domain: ServiceRegistry.Domain) -> ServiceRegistrar
}

public extension MainRegistryComponent {
    @discardableResult
    func register<Service>(withName name: String?, _ serviceRegistration: @escaping ServiceRegistration<Service>) -> RegistrationOptions<Service> {
        registrar(domain: .shared).register(withName: name, serviceRegistration)
    }
}

// Define protocol allow every feature module conforms to make itself registrations
public protocol ServiceRegistryPlugin {
    var identifier: String { get }

    func registerAllServices(into main: MainRegistryComponent)
}

// Default identifier is equivalent to type name
public extension ServiceRegistryPlugin {
    var identifier: String { String(describing: Self.self) }
}
