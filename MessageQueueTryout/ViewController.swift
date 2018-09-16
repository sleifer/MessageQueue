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

    var dispatch: DispatchQueue?

    override func viewDidLoad() {
        super.viewDidLoad()

        dispatch = DispatchQueue(label: "ViewController Queue")
        test()
    }

    func label() -> String {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8) ?? "<unknown>"
    }

    func test() {
        let (q, qi, qo) = MessageQueue<Int>.create()

        let l1 = qo.subscribe(context: .main) { (value: Int) in
            print("main: \(value) || \(self.label())")
        }
        let l2 = qo.subscribe(context: .interactive) { (value: Int) in
            print("interactive: \(value) || \(self.label())")
        }
        let l3 = qo.subscribe(context: .user) { (value: Int) in
            print("user: \(value) || \(self.label())")
        }
        let l4 = qo.subscribe(context: .global) { (value: Int) in
            print("global: \(value) || \(self.label())")
        }
        let l5 = qo.subscribe(context: .background) { (value: Int) in
            print("background: \(value) || \(self.label())")
        }
        if let q = dispatch {
            let l6 = qo.subscribe(context: .custom(queue: q)) { (value: Int) in
                print("custom: \(value) || \(self.label())")
            }
        }

        print("Hi")

        qi.send(1)
        qi.send(2)
        qi.send(3)

        print("Bye")
    }
}

