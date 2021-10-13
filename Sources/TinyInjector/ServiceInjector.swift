//
//  ServiceInjector.swift
//  ServiceRegistry
//
//  Created by NGUYEN CHI CONG on 9/6/21.
//

import Foundation

public protocol ServiceInjector {
    var registry: ServiceRegistry { get }
}

public extension ServiceInjector {
    var registry: ServiceRegistry { .container() }
}
