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

    private let (qu, qi) = MessageQueue<Int>.create()
    public private(set) lazy var qo = {
        return qu.queueOutput
    }()
    var ql: [MessageListener<Int>] = []

    func addCoreListeners() {
        var li: MessageListener<Int>

        li = qo.subscribe(context: .main) { (value: Int) in
            print("main: \(value)")
        }
        ql.append(li)

        li = qo.subscribe(context: .interactive) { (value: Int) in
            print("interactive: \(value)")
        }
        ql.append(li)

        li = qo.subscribe(context: .user) { (value: Int) in
            print("user: \(value)")
        }
        ql.append(li)

        li = qo.subscribe(context: .global) { (value: Int) in
            print("global: \(value)")
        }
        ql.append(li)

        li = qo.subscribe(context: .background) { (value: Int) in
            print("background: \(value)")
        }
        ql.append(li)

        if let qu = dispatch {
            li = qo.subscribe(context: .custom(queue: qu)) { (value: Int) in
                print("custom: \(value)")
            }
            ql.append(li)

        }
    }

    var ql2: [MessageListener<Int>] = []
    var qlIdx: Int = 0

    func addListener() {
        var li: MessageListener<Int>

        qlIdx += 1
        let idx = qlIdx
        li = qo.subscribe(context: .main) { (value: Int) in
            print("\(idx): \(value)")
        }
        ql2.append(li)
    }

    func removeListener() {
        if ql2.count > 0 {
            ql2.removeFirst()
        }
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
