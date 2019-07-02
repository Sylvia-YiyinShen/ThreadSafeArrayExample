import Foundation

var unsafeArray: [Int] = []

//  Stimulate race condition
//for index in 1...50 {
//    DispatchQueue.global().async {
//        unsafeArray.append(index)
//    }
//}
//
//DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
//    for element in unsafeArray {
//        print("element: \(element)")
//    }
//    print("\(unsafeArray.count) element in unsafeArray")
//})
//
//



// Synchronization Case one
var safeArray: [Int] = []
let serialQueue = DispatchQueue(label: "Atomic serial queue", attributes: .concurrent)

for index in 1...50 {
    DispatchQueue.global().async {
        serialQueue.sync(flags: .barrier) {
            safeArray.append(index)
            print("---")
        }
    }
}

DispatchQueue.main.async {
//    print("\(safeArray.count) element in safeArray")
    print("\(serialQueue.sync(flags: .barrier){ safeArray }.count) element in safeArray")
}



// Synchronization Case Two
let dispatchGroup = DispatchGroup()

dispatchGroup.notify(queue: .main) {
//    print("\(safeArray.count) element in safeArray")
    print("\(serialQueue.sync(flags: .barrier){ safeArray }.count) element in safeArray")
}

for index in 1...50 {
    dispatchGroup.enter()
    DispatchQueue(label: "updating array").async(group: dispatchGroup) {
        serialQueue.sync(flags: .barrier) {
            safeArray.append(index)
            print("---")
        }
        dispatchGroup.leave()
    }
}


// Synchronization via Atomic class warpping a value

final class Atomic<A> {
    private let queue = DispatchQueue(label: "Atomic serial queue", attributes: .concurrent)
    private var _value: A
    init(_ value: A) {
        self._value = value
    }

    var value: A {
        get {
            return queue.sync { self._value }
        }
    }

    func mutate(_ transform: (inout A) -> ()) {
        queue.sync(flags: .barrier) { transform(&self._value) }
    }
}

var atomicArray = Atomic<Array<Int>>(Array())

for index in 1...50 {
    DispatchQueue.global().async {
        atomicArray.mutate { $0.append(index) }
    }
}

DispatchQueue.main.async {
    print("\(atomicArray.value.count) element in atomicArray")
}
