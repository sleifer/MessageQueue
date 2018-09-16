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
}

public class MessageQueue<OutputType> {
    var queueInput: MessageQueueInput<OutputType>
    var queueOutput: MessageQueueOutput<OutputType>
    var depth: Int
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

    public class func create(depth: Int = 1, initial: OutputType? = nil) -> (MessageQueue<OutputType>, MessageQueueInput<OutputType>, MessageQueueOutput<OutputType>) {
        let me = MessageQueue<OutputType>(depth: depth, initial: initial)
        return (me, me.queueInput, me.queueOutput)
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
}

public class MessageQueueOutput<OutputType> {
    weak var queue: MessageQueue<OutputType>?
    var listeners: [MessageQueueListener<OutputType>?]
    var dispatch: DispatchQueue

    init() {
        listeners = []
        dispatch = DispatchQueue(label: "MessageQueueOutput DispatchQueue")
    }

    public func subscribe(context: MessageQueueContext = .main, handler: @escaping (OutputType) -> Void) -> MessageQueueListener<OutputType> {
        let listener = MessageQueueListener<OutputType>(context: context, handler: handler)
        dispatch.async {
            self.listeners.append(listener)
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
        
        for listener in listeners {
            if let obj = listener {
                obj.handler(value)
            }
        }
    }

    func sendQueue(to listener: MessageQueueListener<OutputType>) {
        if let q = queue {
            let items = q.queue
            for item in items {
                listener.handler(item)
            }
        }
    }
}
