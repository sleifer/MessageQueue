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
        addCoreListeners()
        test()
        test()
        test()
    }

    func label() -> String {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8) ?? "<unknown>"
    }

    let (q, qi, qo) = MessageQueue<Int>.create()
    var ql: [MessageQueueListener<Int>] = []

    func addCoreListeners() {
        var l: MessageQueueListener<Int>

        l = qo.subscribe(context: .main) { (value: Int) in
            print("main: \(value)")
        }
        ql.append(l)

        l = qo.subscribe(context: .interactive) { (value: Int) in
            print("interactive: \(value)")
        }
        ql.append(l)

        l = qo.subscribe(context: .user) { (value: Int) in
            print("user: \(value)")
        }
        ql.append(l)

        l = qo.subscribe(context: .global) { (value: Int) in
            print("global: \(value)")
        }
        ql.append(l)

        l = qo.subscribe(context: .background) { (value: Int) in
            print("background: \(value)")
        }
        ql.append(l)

        if let q = dispatch {
            l = qo.subscribe(context: .custom(queue: q)) { (value: Int) in
                print("custom: \(value)")
            }
            ql.append(l)

        }
    }

    var ql2: [MessageQueueListener<Int>] = []
    var qlIdx: Int = 0

    func addListener() {
        var l: MessageQueueListener<Int>

        qlIdx += 1
        let i = qlIdx
        l = qo.subscribe(context: .main) { (value: Int) in
            print("\(i): \(value)")
        }
        ql2.append(l)
    }

    func removeListener() {
        ql2.removeFirst()
    }

    var testIdx: Int = 0

    func test() {
        testIdx += 1
        qi.send(testIdx)
    }

    @IBAction func addListenerAction(_ sender: Any) {
        addListener()
    }

    @IBAction func removeListenerAction(_ sender: Any) {
        removeListener()
    }

    @IBAction func testAction(_ sender: Any) {
        test()
    }
}

