## MessageQueue

Serial, asynchronous, thread safe, one-to-many message delivery

#### Simple creation example:

```swift
private let (q, qi) = MessageQueue<Int>.create()
public private(set) lazy var qo = {
    return q.queueOutput
}()
```

#### Simple listen example:

```swift
var l: MessageQueueListener<Int>

l = qo.subscribe(context: .main) { (value: Int) in
    print("main: \(value)")
}
```

#### Simple send example:

```swift
qi.send(1)
```


