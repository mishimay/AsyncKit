# AsyncKit

Utilities for asynchronous code inspired by JavaScript module [async](https://github.com/caolan/async).

## Quick Example

```swift
let async = AsyncKit<String, NSError>()

async.parallel(
    [
        { done in done(.Success("1")) },
        { done in done(.Success("2")) }
    ]) { result in
        print(result) // -> Success(["1", "2"])
}

async.series(
    [
        { done in done(.Success("1")) },
        { done in done(.Success("2")) }
    ]) { result in
        print(result) // -> Success(["1", "2"])
}

var count = 0
async.whilst({ return count < 3 },
    process: { done in
        count += 1
        done(.Success(String(count)))
    }) { result in
        print(result) // -> Success(["1", "2", "3"])
}

async.waterfall(
    [
        { arguments, done in done(.Success(["1"])) },
        { arguments, done in done(.Success(arguments + ["2"])) }
    ]) { result in
        print(result) // -> Success(["1", "2"])
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
  - In the closure, call completion closure with success object or failure object.
  - e.g.

    ```swift
    let process: AsyncKit<String, NSError>.AsyncProcess = { done in
        request() { object, error in
            if error == nil {
                done(.Success(object))
            } else {
                done(.Failure(error))
            }
        }
    }
    ```

1. Pass the process closures to the AsyncKit function and receive callback closure
  - e.g.

    ```swift
    async.parallel([process1, process2]) { result in
        switch result {
        case .Success(let objects):
            print(objects)
        case .Failure(let error):
            print(error)
        }
    }
    ```

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

Yuki Mishima, atehamare@gmail.com

## License

AsyncKit is available under the MIT license. See the LICENSE file for more info.
