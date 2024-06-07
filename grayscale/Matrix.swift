//
//  Matrix.swift
//  grayscale
//
//  Created by sithum sandeepa on 2024-06-07.
//

class Matrix<T> {
    var w: Int
    var h: Int
    var d: Int
    var data: [T]?
    
    init(w: Int, h: Int, d: Int) {
        self.w = w
        self.h = h
        self.d = d
    }
    
    func populate() {
        if data != nil {
            return
        }
        data = [T](repeating: Float(0) as! T, count: w * h * d)
    }
    
    func index(x: Int, y: Int, z: Int) -> Int {
        var i = 0
        i += z * w * h
        i += y * w
        i += x
        return i
    }
    
    func set(x: Int, y: Int, z: Int, v: T) {
        populate()
        data?[index(x: x, y: y, z: z)] = v
    }
    
    func get(x: Int, y: Int, z: Int) -> T {
        populate()
        return data![index(x: x, y: y, z: z)]
    }
    
    func size() -> Int {
        return w * h * d
    }
}
