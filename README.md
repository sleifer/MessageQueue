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


This library was inspired by CwlSignal (https://github.com/mattgallagher/CwlSignal), but has only a subset of its features. I wrote it as a learning experience and to have something more stripped down. I only use it these days where Combine not an option.

Publishing in 2021 so I can share a few tools.

Released under the MIT License.