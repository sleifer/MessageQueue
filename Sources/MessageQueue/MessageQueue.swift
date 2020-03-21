//
//  MessageQueue.swift
//  MessageQueue
//
//  Created by Simeon Leifer on 9/15/18.
//  Copyright © 2018 droolongcat.com. All rights reserved.
//

import Foundation

/// Enumeration of DispatchQueues to send messages on
///
/// - main: the main queue
/// - interactive: the userInteractive QOS queue
/// - user: the userInitiated QOS queue
/// - global: the global queue
/// - utility: the utility QOS queue
/// - background: the background QOS queue
/// - custom: a custom queue passed as a parameter
public enum MessageContext {
    /// - main: the main queue
    case main
    /// - interactive: the userInteractive QOS queue
    case interactive
    /// - user: the userInitiated QOS queue
    case user
    /// - global: the global queue
    case global
    /// - utility: the utility QOS queue
    case utility
    /// - background: the background QOS queue
    case background
    /// - custom: a custom queue passed as a parameter
    case custom(queue: DispatchQueue)

    var queue: DispatchQueue {
        switch self {
        case .main:
            return DispatchQueue.main
        case .interactive:
            return DispatchQueue.global(qos: .userInteractive)
        case .user:
            return DispatchQueue.global(qos: .userInitiated)
        case .global:
            return DispatchQueue.global()
        case .utility:
            return DispatchQueue.global(qos: .utility)
        case .background:
            return DispatchQueue.global(qos: .background)
        case .custom(let queue):
            return queue
        }
    }
}

public typealias SendCompletionHandler = () -> Void

/// A thread save message queue with a single input and multiple outputs. Coordinates a single input with a single output that has multiple listeners. Messages are delivered in send order.
public class MessageQueue<OutputType> {
    /// The input to the queue
    public private(set) var queueInput: MessageInput<OutputType>
    /// The output from the queue
    public private(set) var queueOutput: MessageOutput<OutputType>
    /// The depth of the queue
    public private(set) var depth: Int
    /// The actual queue
    var queue: [OutputType]

    /// Create a queue with a given depth and optional initial value
    ///
    /// - Parameters:
    ///   - depth: depth of queue, defaults to 1
    ///   - initial: initial value for queue, defaults to nil
    init(depth: Int = 1, initial: OutputType? = nil) {
        self.depth = depth
        self.queue = [OutputType]()
        self.queueInput = MessageInput<OutputType>()
        self.queueOutput = MessageOutput<OutputType>()
        queueInput.queue = self
        queueOutput.queue = self

        if let value = initial {
            send(value, sentContext: .main, sentHandler: nil)
        }
    }

    /// Used to create a queue with a given depth and optional initial value
    ///
    /// - Parameters:
    ///   - depth: depth of queue, defaults to 1
    ///   - initial: initial value for queue, defaults to nil
    /// - Returns: a tuple of the `MessageQueue` and its associated `MessageInput`
    public class func create(depth: Int = 1, initial: OutputType? = nil) -> (MessageQueue<OutputType>, MessageInput<OutputType>) {
        let me = MessageQueue<OutputType>(depth: depth, initial: initial)
        return (me, me.queueInput)
    }

    /// Send a value to the output. Called from `MessageInput`
    ///
    /// - Parameter value: the value to send
    func send(_ value: OutputType, sentContext: MessageContext, sentHandler: SendCompletionHandler?) {
        queueOutput.send(value, sentContext: sentContext, sentHandler: sentHandler)
    }
}

/// Represents the input to a `MessageQueue`
public class MessageInput<OutputType> {
    /// The `MessageQueue` this input belongs to
    weak var queue: MessageQueue<OutputType>?

    /// Send a value through the queue
    ///
    /// - Parameter value: the value to send
    public func send(_ value: OutputType, sentContext: MessageContext = .main, sentHandler: SendCompletionHandler? = nil) {
        if let obj = queue {
            obj.send(value, sentContext: sentContext, sentHandler: sentHandler)
        }
    }
}

/// A listener to a `MessageOutput`. Listens as long as it is retained
public class MessageListener<OutputType> {
    /// The DispatchQueue to send to call the `MessageListener`'s handler on
    var context: MessageContext
    /// The `MessageListener`'s handler
    var handler: (OutputType) -> Void

    /// Create a new listener
    ///
    /// - Parameters:
    ///   - context: The DispatchQueue to send to call the `MessageListener`'s handler on
    ///   - handler: The handler to call
    init(context: MessageContext, handler: @escaping (OutputType) -> Void) {
        self.context = context
        self.handler = handler
    }

    /// Send value to this listener's hander
    ///
    /// - Parameter value: the value to send
    func send(_ value: OutputType) {
        context.queue.sync {
            self.handler(value)
        }
    }
}

/// Helper to hold a weak reference to an object in an array
class Weak<T: AnyObject> {
    /// The weakly referenced object
    weak private(set) var value: T?

    /// Create a weak reference holder to an object
    ///
    /// - Parameter value: The object to hold a weak reference to
    init (_ value: T) {
        self.value = value
    }
}

/// Represents the output from a `MessageQueue`
public class MessageOutput<OutputType> {
/// The `MessageQueue` this output belongs to
    weak var queue: MessageQueue<OutputType>?
    /// The listeners to this output
    var listeners: [Weak<MessageListener<OutputType>>]
    /// The DispatchQueue used to make sure messages are delivered in order
    var dispatch: DispatchQueue

    /// Create a new `MessageOutput`
    init() {
        listeners = []
        dispatch = DispatchQueue(label: "MessageOutput DispatchQueue")
    }

    /// Add a subscriber (`MessageListener`) to this output. Subscribed as long as the returned `MessageListener` is retained. New listener will immediately receive any values in the queue.
    ///
    /// - Parameters:
    ///   - context: The DispatchQueue on which to call the handler
    ///   - handler: The handler to call to receive new values
    /// - Returns: A reference to the created `MessageListener`
    public func subscribe(context: MessageContext = .main, handler: @escaping (OutputType) -> Void) -> MessageListener<OutputType> {
        let listener = MessageListener<OutputType>(context: context, handler: handler)
        dispatch.async {
            self.listeners.append(Weak<MessageListener<OutputType>>(listener))
            self.sendQueue(to: listener)
        }
        return listener
    }

    /// Send value to all listeners. Serializes sends.
    ///
    /// - Parameter value: the value to send
    func send(_ value: OutputType, sentContext: MessageContext, sentHandler: SendCompletionHandler?) {
        dispatch.async {
            self.actualSend(value)
            if let handler = sentHandler {
                sentContext.queue.sync {
                    handler()
                }
            }
        }
    }

    /// Actaully send new value to all listeners. Clean up any listeners that have gone away.
    ///
    /// - Parameter value: the value to send
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

    /// Send current queue of values to a listener
    ///
    /// - Parameter listener: the listener to send the queue of values to
    func sendQueue(to listener: MessageListener<OutputType>) {
        if let qu = queue {
            let items = qu.queue
            for item in items {
                listener.send(item)
            }
        }
    }
}
