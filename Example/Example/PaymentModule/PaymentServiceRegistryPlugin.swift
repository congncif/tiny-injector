//
//  PaymentServiceRegistryPlugin.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import Foundation
import TinyInjector

extension ServiceRegistry.Domain {
    static let payment = ServiceRegistry.Domain(rawValue: "payment")
}

public struct PaymentServiceRegistryPlugin: ServiceRegistryPlugin {
    public func registerAllServices() {
        // Register public services
        ServiceRegistry.container()
            .register { PaymentProvider() }.implements(PaymentService.self)

        // Register internal services
        ServiceRegistry.container(.payment)
            .register { PaymentInternalProvider() }.implements(PaymentInternalService.self)
    }
}
