//
//  ViewController.swift
//  MessageQueueTryout
//
//  Created by Simeon Leifer on 9/15/18.
//  Copyright © 2018 droolongcat.com. All rights reserved.
//

import Cocoa

import MessageQueue

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        test()
    }

    func test() {
        let (q, qi, qo) = MessageQueue<Int>.create()

        let l1 = qo.subscribe(context: .main) { (value: Int) in
            print("A: \(value)")
        }

        print("Hi")

        qi.send(1)
        qi.send(2)

        let l2 = qo.subscribe(context: .main) { (value: Int) in
            print("B: \(value)")
        }

        qi.send(3)

        print("Bye")
    }
}

