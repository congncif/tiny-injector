//
//  OrderService.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import Foundation

public protocol OrderService {
    func getOrder() -> String
}

class OrderProvider: OrderService {
    func getOrder() -> String {
        return "ORDER_ID"
    }
}
