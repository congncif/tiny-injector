//
//  ServiceInjector.swift
//  ServiceRegistry
//
//  Created by NGUYEN CHI CONG on 9/6/21.
//

import Foundation

public protocol ServiceRegistryContainer {
    func registry(domain: ServiceRegistry.Domain) -> ServiceRegistry
}

public extension ServiceRegistryContainer {
    func registry(domain: ServiceRegistry.Domain = .shared) -> ServiceRegistry {
        ServiceRegistry.container(domain: domain)
    }
}
