public enum Result<T, U> {
    case Success(T)
    case Failure(U)
}

public struct AsyncKit<T, U> {

    public typealias AsyncProcess = (Result<T, U> -> ()) -> ()
    public typealias AsyncProcessWithArguments = (arguments: [T], Result<[T], U> -> ()) -> ()

    public init() {
    }

    public func parallel(acyncProcesses: [AsyncProcess], completion: Result<[T], U> -> ()) {
        var hasFailed = false
        var successObjects = [T?](count: acyncProcesses.count, repeatedValue: nil)

        let group = dispatch_group_create()
        for (index, acyncProcess) in acyncProcesses.enumerate() {
            dispatch_group_enter(group)
            acyncProcess { result in
                switch result {
                case .Success(let object):
                    successObjects[index] = object
                    dispatch_group_leave(group)
                case .Failure(let object):
                    if !hasFailed {
                        hasFailed = true
                        completion(.Failure(object))
                    }
                }
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(.Success(successObjects.flatMap { $0 }))
        }
    }

    public func series(acyncProcesses: [AsyncProcess], completion: Result<[T], U> -> ()) {
        var successObjects = [T]()

        func execute(index: Int) {
            if 0..<acyncProcesses.count ~= index {
                let acyncProcess = acyncProcesses[index]
                acyncProcess { result in
                    switch result {
                    case .Success(let object):
                        successObjects.append(object)
                        execute(index + 1)
                    case .Failure(let object):
                        completion(.Failure(object))
                    }
                }
            } else {
                completion(.Success(successObjects))
            }
        }

        execute(0)
    }

    public func waterfall(acyncProcesses: [AsyncProcessWithArguments], completion: Result<[T], U> -> ()) {
        func execute(arguments: [T], index: Int) {
            if 0..<acyncProcesses.count ~= index {
                let acyncProcess = acyncProcesses[index]
                acyncProcess(arguments: arguments) { result in
                    switch result {
                    case .Success(let objects):
                        execute(objects, index: index + 1)
                    case .Failure(let object):
                        completion(.Failure(object))
                    }
                }
            } else {
                completion(.Success(arguments))
            }
        }

        execute([], index: 0)
    }

}
