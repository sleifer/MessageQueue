//
//  MessageQueue.swift
//  MessageQueue
//
//  Created by Simeon Leifer on 9/15/18.
//  Copyright © 2018 droolongcat.com. All rights reserved.
//

import Foundation

public enum MessageContext {
    case main
    case interactive
    case user
    case global
    case utility
    case background
    case custom(queue: DispatchQueue)
}

public class MessageQueue<OutputType> {
    public private(set) var queueInput: MessageInput<OutputType>
    public private(set) var queueOutput: MessageOutput<OutputType>
    public private(set) var depth: Int
    var queue: [OutputType]

    init(depth: Int = 1, initial: OutputType? = nil) {
        self.depth = depth
        self.queue = [OutputType]()
        self.queueInput = MessageInput<OutputType>()
        self.queueOutput = MessageOutput<OutputType>()
        queueInput.queue = self
        queueOutput.queue = self

        if let value = initial {
            send(value)
        }
    }

    public class func create(depth: Int = 1, initial: OutputType? = nil) -> (MessageQueue<OutputType>, MessageInput<OutputType>) {
        let me = MessageQueue<OutputType>(depth: depth, initial: initial)
        return (me, me.queueInput)
    }

    func send(_ value: OutputType) {
        queueOutput.send(value)
    }
}

public class MessageInput<OutputType> {
    weak var queue: MessageQueue<OutputType>?

    public func send(_ value: OutputType) {
        if let obj = queue {
            obj.send(value)
        }
    }
}

public class MessageListener<OutputType> {
    var context: MessageContext
    var handler: (OutputType) -> Void

    init(context: MessageContext, handler: @escaping (OutputType) -> Void) {
        self.context = context
        self.handler = handler
    }

    func send(_ value: OutputType) {
        var dq: DispatchQueue = DispatchQueue.main

        switch context {
        case .main:
            dq = DispatchQueue.main
        case .interactive:
            dq = DispatchQueue.global(qos: .userInteractive)
        case .user:
            dq = DispatchQueue.global(qos: .userInitiated)
        case .global:
            dq = DispatchQueue.global()
        case .utility:
            dq = DispatchQueue.global(qos: .utility)
        case .background:
            dq = DispatchQueue.global(qos: .background)
        case .custom(let queue):
            dq = queue
        }

        dq.sync {
            self.handler(value)
        }
    }
}

class Weak<T: AnyObject> {
    weak private(set) var value: T?

    init (_ value: T) {
        self.value = value
    }
}

public class MessageOutput<OutputType> {
    weak var queue: MessageQueue<OutputType>?
    var listeners: [Weak<MessageListener<OutputType>>]
    var dispatch: DispatchQueue

    init() {
        listeners = []
        dispatch = DispatchQueue(label: "MessageOutput DispatchQueue")
    }

    public func subscribe(context: MessageContext = .main, handler: @escaping (OutputType) -> Void) -> MessageListener<OutputType> {
        let listener = MessageListener<OutputType>(context: context, handler: handler)
        dispatch.async {
            self.listeners.append(Weak<MessageListener<OutputType>>(listener))
            self.sendQueue(to: listener)
        }
        return listener
    }

    func send(_ value: OutputType) {
        dispatch.async {
            self.actualSend(value)
        }
    }

    private func actualSend(_ value: OutputType) {
        if let qu = queue {
            qu.queue.append(value)
            if qu.queue.count > qu.depth {
                qu.queue.removeFirst(qu.queue.count - qu.depth)
            }
        }

        var needReap: Bool = false
        for listener in listeners {
            if let listener = listener.value {
                listener.send(value)
            } else {
                needReap = true
            }
        }
        if needReap == true {
            listeners = listeners.filter { nil != $0.value }
        }
    }

    func sendQueue(to listener: MessageListener<OutputType>) {
        if let qu = queue {
            let items = qu.queue
            for item in items {
                listener.send(item)
            }
        }
    }
}
