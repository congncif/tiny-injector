//
//  OrderServiceRegistryPlugin.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import Foundation
import TinyInjector

public struct OrderServiceRegistryPlugin: ServiceRegistryPlugin {
    public func registerAllServices() {
        ServiceRegistry.container()
            .register { OrderProvider() }.implements(OrderService.self)
    }
}
