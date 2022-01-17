//
//  Extension.swift
//  
//
//  Created by Joseph Fergusson on 17/1/22.
//

import Foundation

extension Int {
    ///Find counts of points that can be distributed in an equidistant way on a line graph for a given number
    ///For instance, any odd number should be able to support 3 points, as there will be a bottom number, a number in the exact middle, and a top number
    func findNTiles() -> [Int] {
        var res = [self]
        var curr = Int(self / 2)
        let s = self - 1
        while curr > 1 {
            if s % (curr - 1) == 0 {
                res.append(curr)
            }
            curr -= 1
        }
        return res
    }
}
