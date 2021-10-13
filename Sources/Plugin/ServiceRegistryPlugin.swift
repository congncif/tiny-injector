//
//  ServiceRegistryPlugin.swift
//  SRPlugin
//
//  Created by NGUYEN CHI CONG on 9/30/21.
//

import Foundation

// Define protocol allow every feature module conforms to make itself registrations
public protocol ServiceRegistryPlugin {
    var identifier: String { get }

    func registerAllServices()
}

// Default identifier is equivalent to type name
public extension ServiceRegistryPlugin {
    var identifier: String { String(describing: Self.self) }
}
