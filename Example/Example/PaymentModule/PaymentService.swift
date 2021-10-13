//
//  PaymentService.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import Foundation

public protocol PaymentService {
    func pay(item itemID: String, completion: @escaping (Result<String, Error>) -> Void)
}

import TinyInjector

class PaymentProvider: PaymentService {
    // Inject an internal service
    @LazyInjected(registry: .container(.payment)) var internalService: PaymentInternalService

    func pay(item itemID: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("Process a payment for item \(itemID)")

        internalService.doSomething()

        completion(.success("TRANSACTION_ID"))
    }
}
