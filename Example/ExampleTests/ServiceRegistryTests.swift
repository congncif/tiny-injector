//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by NGUYEN CHI CONG on 10/13/21.
//

@testable import TinyInjector
import XCTest

private var registry: ServiceRegistry!

class ServiceRegistryTests: XCTestCase {
    override func setUpWithError() throws {
        registry = ServiceRegistry(parent: nil)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOptionalService() throws {
        registry.register { MockProvider() }.implements(MockService.self).implements(MockService2.self)

        let provider: MockProvider? = registry.optionalResolve()
        let service1: MockService? = registry.optionalResolve()
        let service2: MockService2? = registry.optionalResolve()

        XCTAssertNotNil(provider)
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
    }

    func testNonOptionalService() throws {
        registry.register { MockProvider() }.implements(MockService.self).implements(MockService2.self)

        let _: MockProvider = registry.resolve()
        let _: MockService = registry.resolve()
        let _: MockService2 = registry.resolve()
    }

    func testDependentService() throws {
        registry.register { MockProvider() }.implements(MockService.self).implements(MockService2.self)
            .register {
                BiggerProvider(mockService: $0.resolve())
            }.implements(BiggerMockService.self)

        let biggerService: BiggerMockService? = registry.optionalResolve()

        XCTAssertNotNil(biggerService)
    }

//    func testPropertyWrapper() throws {
//        registry.register { MockProvider() }.implements(MockService.self).implements(MockService2.self)
//            .register {
//                BiggerProvider(mockService: $0.resolve())
//            }.implements(BiggerMockService.self)
//
//        let sut = PropertyWrapperProvider()
//        _ = sut.mockService
//        _ = sut.biggerService
//        XCTAssertNotNil(sut.mockService2)
//    }
}

// MARK: - Mock

private protocol MockService {
    func doSomething()
}

private protocol MockService2 {
    func doSomething2()
}

private class MockProvider: MockService, MockService2 {
    func doSomething() {}
    func doSomething2() {}
}

private protocol BiggerMockService {}

private class BiggerProvider: BiggerMockService {
    let mockService: MockService

    init(mockService: MockService) {
        self.mockService = mockService
    }
}

//private class PropertyWrapperProvider {
//    @LazyInjected(registry: registry) var mockService: MockService
//    @Injected(registry: registry) var biggerService: BiggerMockService
//    @OptionalInjected(registry: registry) var mockService2: MockService2?
//}
