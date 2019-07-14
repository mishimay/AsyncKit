public enum Result<T, U> {
    case success(T)
    case failure(U)
}

public struct AsyncKit<T, U> {

    public typealias Process = (@escaping (Result<T, U>) -> ()) -> ()
    public typealias ProcessWithArgument = (_ argument: T, @escaping (Result<T, U>) -> ()) -> ()

    public init() {
    }

    public func parallel(_ processes: [Process], completion: @escaping (Result<[T], U>) -> ()) {
        var hasFailed = false
        var successObjects = [T?](repeating: nil, count: processes.count)

        let group = DispatchGroup()
        for (index, process) in processes.enumerated() {
            group.enter()
            process { result in
                switch result {
                case .success(let object):
                    successObjects[index] = object
                    group.leave()
                case .failure(let object):
                    if !hasFailed {
                        hasFailed = true
                        completion(.failure(object))
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion(.success(successObjects.compactMap { $0 }))
        }
    }

    public func series(_ processes: [Process], completion: @escaping (Result<[T], U>) -> ()) {
        var successObjects = [T]()

        func execute(index: Int) {
            guard 0..<processes.count ~= index else {
                completion(.success(successObjects))
                return
            }

            let process = processes[index]
            process { result in
                switch result {
                case .success(let object):
                    successObjects.append(object)
                    execute(index: index + 1)
                case .failure(let object):
                    completion(.failure(object))
                }
            }
        }

        execute(index: 0)
    }

    public func whilst(_ test: @escaping () -> Bool, _ process: @escaping Process, completion: @escaping (Result<T?, U>) -> ()) {
        var successObject: T? = nil

        func execute() {
            guard test() else {
                completion(.success(successObject))
                return
            }

            process { result in
                switch result {
                case .success(let object):
                    successObject = object
                    execute()
                case .failure(let object):
                    completion(.failure(object))
                }
            }
        }

        execute()
    }

    public func waterfall(_ argument: T, _ processes: [ProcessWithArgument], completion: @escaping (Result<T, U>) -> ()) {
        func execute(argument: T, index: Int) {
            guard 0..<processes.count ~= index else {
                completion(.success(argument))
                return
            }

            let process = processes[index]
            process(argument) { result in
                switch result {
                case .success(let object):
                    execute(argument: object, index: index + 1)
                case .failure(let object):
                    completion(.failure(object))
                }
            }
        }

        execute(argument: argument, index: 0)
    }

}
