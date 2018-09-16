//
//  MessageQueue.swift
//  MessageQueue
//
//  Created by Simeon Leifer on 9/15/18.
//  Copyright © 2018 droolongcat.com. All rights reserved.
//

import Foundation

public enum MessageQueueContext {
    case main
    case interactive
    case user
    case global
    case utility
    case background
    case custom(queue: DispatchQueue)
}

public class MessageQueue<OutputType> {
    public private(set) var queueInput: MessageQueueInput<OutputType>
    public private(set) var queueOutput: MessageQueueOutput<OutputType>
    public private(set) var depth: Int
    var queue: [OutputType]

    init(depth: Int = 1, initial: OutputType? = nil) {
        self.depth = depth
        self.queue = Array<OutputType>()
        self.queueInput = MessageQueueInput<OutputType>()
        self.queueOutput = MessageQueueOutput<OutputType>()
        queueInput.queue = self
        queueOutput.queue = self

        if let value = initial {
            send(value)
        }
    }

    public class func create(depth: Int = 1, initial: OutputType? = nil) -> (MessageQueue<OutputType>, MessageQueueInput<OutputType>) {
        let me = MessageQueue<OutputType>(depth: depth, initial: initial)
        return (me, me.queueInput)
    }

    func send(_ value: OutputType) {
        queueOutput.send(value)
    }
}

public class MessageQueueInput<OutputType> {
    weak var queue: MessageQueue<OutputType>?

    public func send(_ value: OutputType) {
        if let obj = queue {
            obj.send(value)
        }
    }
}

public class MessageQueueListener<OutputType> {
    var context: MessageQueueContext
    var handler: (OutputType) -> Void

    init(context: MessageQueueContext, handler: @escaping (OutputType) -> Void) {
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
    weak private(set) var value : T?

    init (_ value: T) {
        self.value = value
    }
}

public class MessageQueueOutput<OutputType> {
    weak var queue: MessageQueue<OutputType>?
    var listeners: [Weak<MessageQueueListener<OutputType>>]
    var dispatch: DispatchQueue

    init() {
        listeners = []
        dispatch = DispatchQueue(label: "MessageQueueOutput DispatchQueue")
    }

    public func subscribe(context: MessageQueueContext = .main, handler: @escaping (OutputType) -> Void) -> MessageQueueListener<OutputType> {
        let listener = MessageQueueListener<OutputType>(context: context, handler: handler)
        dispatch.async {
            self.listeners.append(Weak<MessageQueueListener<OutputType>>(listener))
            self.sendQueue(to: listener)
        }
        return listener
    }

    func send(_ value: OutputType) {
        dispatch.async {
            self._send(value)
        }
    }

    func _send(_ value: OutputType) {
        if let q = queue {
            q.queue.append(value)
            if q.queue.count > q.depth {
                q.queue.removeFirst(q.queue.count - q.depth)
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

    func sendQueue(to listener: MessageQueueListener<OutputType>) {
        if let q = queue {
            let items = q.queue
            for item in items {
                listener.send(item)
            }
        }
    }
}
