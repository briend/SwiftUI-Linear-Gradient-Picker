//
//  Utilities.swift
//  LinearGradientPickerTutorial
//
//  Created by Kieran Brown on 2/21/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI
import simd


let formatter: NumberFormatter = {
    let f = NumberFormatter()
    f.maximum = 1
    f.minimum = 0
    
    f.maximumFractionDigits = 3
    return f
}()

/// Preference Key creates a dictionary from the values given 
struct DictionaryPreferenceKey<Key: Hashable, Value>: PreferenceKey {
    static var defaultValue: [Key:Value] { [:] }
    static func reduce(value: inout [Key:Value], nextValue: () -> [Key:Value]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

enum DragState {
    case inactive
    case pressing
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive, .pressing:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
    
    var isActive: Bool {
        switch self {
        case .inactive:
            return false
        case .pressing, .dragging:
            return true
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .inactive, .pressing:
            return false
        case .dragging:
            return true
        }
    }
}


/// Prevent the draggable element from going over its limit
func limitValue(_ value: Double, _ limit: CGFloat, _ state: CGFloat) -> CGFloat {
    let v = Double(CGFloat(value)*limit + state)
    return CGFloat(v.clamped(to: 0...Double(limit)))
}

/// Prevent values like hue, saturation and brightness from being greater than 1 or less than 0
func limitUnitValue(_ value: Double, _ limit: CGFloat, _ state: CGFloat) -> Double {
    let v = value + Double(state/limit)
    return v.clamped(to: 0...1)
}


/// # Linear Interpolation
///
/// Calculates and returns the point at the value `t` on the line defined by the start and end points
///
/// - parameters:
///     - t: parametric variable of some value on [0,1]
///     - start: The starting location of the line
///     - end: The ending location of the line
func linearInterpolation(t: Float, start: CGPoint, end: CGPoint) -> CGPoint {
    let p0 = start.tosimd()
    let p1 = end.tosimd()
    let point = mix(p0, p1, t: t)
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}




// MARK: Clamping
extension FloatingPoint {
func clamped(to range: ClosedRange<Self>) -> Self {
return max(min(self, range.upperBound), range.lowerBound)
    }
}
extension BinaryInteger {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}

// MARK: CGSize Convienience
extension CGSize {
    func toPoint() -> CGPoint {
        CGPoint(x: width, y: height)
    }
}
// MARK: CGSize VectorArithmetic Conformance
extension CGSize: VectorArithmetic {
    public static func -= (lhs: inout CGSize, rhs: CGSize) {
        lhs.width -= rhs.width
        lhs.height -= rhs.height
    }
    
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width+rhs.width, height: lhs.height+rhs.height)
    }
    
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width-rhs.width, height: lhs.height-rhs.height)
    }
    
    public mutating func scale(by rhs: Double) {
        width *= CGFloat(rhs)
        height *= CGFloat(rhs)
    }
    
    public var magnitudeSquared: Double {
        Double(width*width+height*height)
    }
    
    public static func += (lhs: inout CGSize, rhs: CGSize) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }
    
}

// MARK: CGPoint Convienience Extension
extension CGPoint {
    func toSize() -> CGSize {
        CGSize(width: x, height: y)
    }
    
    func tosimd() -> simd_float2 {
        simd_float2(Float(x), Float(y))
    }
}




// MARK: CGPoint VectorArithmetic Conformance
extension CGPoint: VectorArithmetic {
    public static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
    
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }
    
    public mutating func scale(by rhs: Double) {
        x *= CGFloat(rhs)
        y *= CGFloat(rhs)
    }
    
    public var magnitudeSquared: Double {
        Double(x*x+y*y)
    }
    
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
