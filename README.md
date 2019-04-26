Simple creation example:

private let (q, qi) = MessageQueue<Int>.create()
public private(set) lazy var qo = {
    return q.queueOutput
}()

Simple listen example:

var l: MessageQueueListener<Int>

l = qo.subscribe(context: .main) { (value: Int) in
    print("main: \(value)")
}

Simple send example:

qi.send(1)
