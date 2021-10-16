//
//  OrderServiceRegistryPlugin.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import Foundation
import TinyInjector

public struct OrderServiceRegistryPlugin: ServiceRegistryPlugin {
    public func registerAllServices(into main: MainRegistryComponent) {
        main.register { OrderProvider() }.implements(OrderService.self)
    }
}
