// https://github.com/Quick/Quick

import Quick
import Nimble
import AsyncKit

class AsySpec: QuickSpec {
    override func spec() {
        let async = AsyncKit<String, NSError>()

        describe("parallel") {
            it("can be done") {
                waitUntil { done in
                    async.parallel(
                        [
                            { done in done(.Success("1")) },
                            { done in done(.Success("2")) }
                        ]) { result in
                            switch result {
                            case .Success(let objects):
                                expect(objects) == ["1", "2"]
                                done()
                            case .Failure(_):
                                fail()
                            }
                    }
                }
            }
        }

        describe("series") {
            it("can be done") {
                waitUntil { done in
                    async.series(
                        [
                            { done in done(.Success("1")) },
                            { done in done(.Success("2")) }
                        ]) { result in
                            switch result {
                            case .Success(let objects):
                                expect(objects) == ["1", "2"]
                                done()
                            case .Failure(_):
                                fail()
                            }
                    }
                }
            }
        }

        describe("whilst") {
            it("can be done") {
                waitUntil { done in
                    var count = 0
                    async.whilst({ return count < 3 },
                        { done in
                            count += 1
                            done(.Success(String(count)))
                        }) { result in
                            switch result {
                            case .Success(let object):
                                expect(object) == "3"
                                done()
                            case .Failure(_):
                                fail()
                            }
                    }
                }
            }
        }

        describe("waterfall") {
            it("can be done") {
                waitUntil { done in
                    async.waterfall("0",
                        [
                            { argument, done in
                                expect(argument) == "0"
                                done(.Success("1"))
                            },
                            { argument, done in
                                expect(argument) == "1"
                                done(.Success("2"))
                            }
                        ]) { result in
                            switch result {
                            case .Success(let objects):
                                expect(objects) == "2"
                                done()
                            case .Failure(_):
                                fail()
                            }
                    }
                }
            }
        }
    }
}
