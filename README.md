# AsyncKit

Utilities for asynchronous code inspired by JavaScript module [async](https://github.com/caolan/async).

AsyncKit is
- written in Swift
- generic
- less code

## Quick Example

```swift
let async = AsyncKit<String, NSError>()

async.parallel(
    [
        { done in done(.success("one")) },
        { done in done(.success("two")) }
    ]) { result in
        print(result) // -> success(["one", "two"])
        // the success array will equal ["one", "two"] even though
        // the second closure had a shorter timeout.
}

async.series(
    [
        { done in done(.success("one")) },
        { done in done(.success("two")) }
    ]) { result in
        print(result) // -> success(["one", "two"])
}

var count = 0
async.whilst({ return count < 2 },
    { done in
        count += 1
        done(.success(String(count)))
    }) { result in
        print(result) // -> success(Optional("2"))
}

async.waterfall("one",
    [
        // argument is "one"
        { argument, done in done(.success("two")) },
        // argument is "two"
        { argument, done in done(.success("three")) }
    ]) { result in
        print(result) // -> success("three")
}
```

## Usage

1. Instantiate AsyncKit
  - You need to specify success object type and failure object type.
  - e.g.

    ```swift
    let async = AsyncKit<String, NSError>()
    ```

1. Prepare process closures
  - In the closure, call a passed closure with a success object or a failure object.
  - e.g.

    ```swift
    let process: AsyncKit<String, NSError>.Process = { done in
        request() { object, error in
            if error == nil {
                done(.success(object))
            } else {
                done(.failure(error))
            }
        }
    }
    ```

1. Pass the process closures to the AsyncKit function and receive a result
  - e.g.

    ```swift
    async.parallel([process1, process2]) { result in
        switch result {
        case .success(let objects):
            print(objects)
        case .failure(let error):
            print(error)
        }
    }
    ```

***

### parallel
```swift
func parallel(processes: [Process], completion: Result<[T], U> -> ())
```
Run the processes in parallel, without waiting until the previous process has completed. If any of the processes pass an error, the completion closure is immediately run with a failure result. Once the processes have completed successfully, the completion closure is run with a success result with an array of success objects.

#### Parameters
- `processes`: An array containing closures whose type is `AsyncKit<T, U>.Process`. Each closure is passed a closure which it must execute with a success object or a failure object.
- `completion`: A closure to run once all the processes have succeeded or any process has failed. This closure gets a result containing either all the success objects or a failure object.

#### Example
```swift
AsyncKit<String, NSError>().parallel([
    { done in
        if arc4random_uniform(4) == 0 {
            done(.failure(NSError(domain: "AsyncKit", code: 0, userInfo: nil)))
        } else {
            done(.success("one"))
        }
    }, { done in
        if arc4random_uniform(4) == 0 {
            done(.failure(NSError(domain: "AsyncKit", code: 1, userInfo: nil)))
        } else {
            done(.success("two"))
        }
    }
    ]) { result in
        switch result {
        case .success(let objects):
            print(objects) // -> success(["one", "two"])
            // the success array will equal ["one", "two"] even though
            // the second closure had a shorter timeout.
        case .failure(let error):
            print(error)
        }
}
```

***

### series
```swift
func series(processes: [Process], completion: Result<[T], U> -> ())
```
Run the processes in series, each one will run once the previous process has completed. If any processes in the series pass an error, no more processes are run, and the completion closure is immediately run with a failure result. Otherwise, the completion closure receives a success result with an array of success objects when processes have completed successfully.

#### Parameters
- `processes`: An array containing closures whose type is `AsyncKit<T, U>.Process`. Each closure is passed a closure which it must execute with a success object or a failure object.
- `completion`: A closure to run once all the processes have succeeded or any process has failed. This closure gets a result containing either all the success objects or a failure object.

#### Example
```swift
AsyncKit<String, NSError>().series([
    { done in
        if arc4random_uniform(4) == 0 {
            done(.failure(NSError(domain: "AsyncKit", code: 0, userInfo: nil)))
        } else {
            done(.success("one"))
        }
    }, { done in
        if arc4random_uniform(4) == 0 {
            done(.failure(NSError(domain: "AsyncKit", code: 1, userInfo: nil)))
        } else {
            done(.success("two"))
        }
    }
    ]) { result in
        switch result {
        case .success(let objects):
            print(objects) // -> success(["one", "two"])
        case .failure(let error):
            print(error)
        }
}
```

***

### whilst
```swift
func whilst(test: () -> Bool, _ process: Process, completion: Result<T?, U> -> ())
```
Repeatedly call `process`, while `test` returns true. Calls completion when stopped, or an error occurs.

#### Parameters
- `test`: A test before each execution of process.
- `process`: A closure which is called each time test passes. The closure is passed a closure, which must be called once it has completed with a result.
- `completion`: A closure which is run after the test closure has failed and repeated execution of process has stopped. This closure gets a result containing either a optional success object passed to the final process's closure or a failure object.

#### Example
```swift
var count = 0
AsyncKit<String, NSError>().whilst({
        return count < 2
    },
    { done in
        count += 1
        if arc4random_uniform(4) == 0 {
            done(.failure(NSError(domain: "AsyncKit", code: count, userInfo: nil)))
        } else {
            done(.success(String(count)))
        }
    }) { result in
        switch result {
        case .success(let object):
            print(object) // -> Optional("2")
        case .failure(let error):
            print(error)
        }
}
```

***

### waterfall
```swift
func waterfall(argument: T, _ processes: [ProcessWithArgument], completion: Result<T, U> -> ())
```
Runs the tasks array of processes in series, each passing their result to the next. However, if any of the processes pass an error, the next process is not executed, and the completion closure is immediately run with the error.

#### Parameters
- `argument`: A first argument.
- `process`: An array containing closures whose type is `AsyncKit<T, U>.ProcessWithArgument`. Each closure is passed a argument and a closure which it must call on completion with a success object or a failure object. The success object will be the next process's argument.
- `completion`: A closure to run once all the processes have succeeded or any process has failed. This closure gets a result containing either the final process's success object or a failure object.

#### Example
```swift
AsyncKit<String, NSError>().waterfall("one",
    [
        // argument is "one"
        { argument, done in
            if arc4random_uniform(4) == 0 {
                done(.failure(NSError(domain: "AsyncKit", code: 0, userInfo: nil)))
            } else {
                done(.success("two"))
            }
        },
        // argument is "two"
        { argument, done in
            if arc4random_uniform(4) == 0 {
                done(.failure(NSError(domain: "AsyncKit", code: 1, userInfo: nil)))
            } else {
                done(.success("three"))
            }
        }
    ]) { result in
        switch result {
        case .success(let object):
            print(object)
        case .failure(let error):
            print(error)
        }
}
```

***


## Requirements

Swift 3.0


## Installation

### CocoaPods
- AsyncKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following lines to your *Podfile*:

```ruby
use_frameworks!
pod "AsyncKit"
```

- Run `pod install`

### Carthage

- Add the following to your *Cartfile*:

```bash
github "mishimay/AsyncKit"
```

- Run `carthage update`
- Add the framework as described.
<br> See more Details: [Carthage Readme](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)


## Author

Yuki Mishima, mishimaybe@gmail.com

## License

AsyncKit is available under the MIT license. See the LICENSE file for more info.
