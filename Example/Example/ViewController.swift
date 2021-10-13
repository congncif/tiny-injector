//
//  ViewController.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 10/12/21.
//

import TinyInjector
import UIKit

class ViewController: UIViewController {
    @LazyInjected var orderService: OrderService
    @LazyInjected var paymentService: PaymentService

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func payButtonDidTap() {
        let orderID = orderService.getOrder()
        paymentService.pay(item: orderID) { result in
            print("Payment Result: \(result)")
        }
    }
}
