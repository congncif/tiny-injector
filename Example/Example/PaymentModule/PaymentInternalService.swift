//
//  PaymentInternalService.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import Foundation

/// The internal service which is used inside the Payment module and won't be exposed to the external services
protocol PaymentInternalService {
    func doSomething()
}

class PaymentInternalProvider: PaymentInternalService {
    func doSomething() {
        print("Do something internally")
    }
}
