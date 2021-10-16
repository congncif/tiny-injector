//
//  SRPluginIntegrator.swift
//  SRPlugin
//
//  Created by NGUYEN CHI CONG on 9/30/21.
//

import Foundation

struct MainComponent: MainRegistryComponent {
    func registrar(domain: ServiceRegistry.Domain) -> ServiceRegistrar {
        ServiceRegistry.container(domain: domain)
    }
}

public final class SRPluginIntegrator: ServiceRegistryPlugin {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    private var plugins: [ServiceRegistryPlugin] = []

    public func install(plugin: ServiceRegistryPlugin) -> Self {
        guard !plugins.contains(where: { $0.identifier == plugin.identifier }) else {
            #if DEBUG
            print("⚠️ [DUPLICATION WARNING] The plugin \(plugin) was already installed.")
            #endif
            return self
        }
        plugins.append(plugin)
        return self
    }

    public func registerAllServices(into main: MainRegistryComponent) {
        plugins.forEach {
            $0.registerAllServices(into: main)
        }
    }
}

public extension SRPluginIntegrator {
    func registerAllServices() {
        registerAllServices(into: MainComponent())
    }
}
