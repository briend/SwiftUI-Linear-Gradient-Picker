//
//  LinearGradient.swift
//  LinearGradientPickerTutorial
//
//  Created by Kieran Brown on 2/21/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI
import simd

// MARK: Stop View

/// # Linear Gradient Stop View
///
/// A draggable view which is restricted to move only between the start and end points.
/// Makes use of a lookup table to map the drag gesture onto the line defined by the start and end points
///
/// - important: When implementing the picker, its useful to make a custom binding for the stops such that when the stops are
/// set, they sort in order of location rather than order in the array that stores them
/// ```
///     Binding(get: { self.stops },
///              set: { (stops: [Gradient.Stop]) in
///                         self.stops = stops.sorted(by: { (first, second)  in
///                                    second.location > first.location
///                 })
///             })
///
/// ```
struct LinearStop: View {
    @Binding var selection: Int? // Currently selected stop
    @Binding var stop: Gradient.Stop // Color and a unit location value scaled by the length of end-start
    @State private var dragState: CGSize = .zero
    
    var position: CGPoint { linearInterpolation(t: Float(stop.location), start: start, end: end) }
    var start: CGPoint // The start point of the gradient
    var end: CGPoint // The end point of the gradient
    var lookUpTable: [CGPoint] // Used to create a table of values on the line defined by the start and end
    var id: Int // the id used for the anchor preference key
    
    // MARK: Customization
    var backgroundColor: Color = Color(red: 0.8, green: 0.8, blue: 0.8)
    var size: CGSize = CGSize(width: 25, height: 25)
    
    
    init(selection: Binding<Int?>, start: CGPoint, end: CGPoint, lookUpTable: [CGPoint], id: Int, stop: Binding<Gradient.Stop>) {
        self._selection = selection
        self.start = start
        self.end = end
        self.id = id
        self._stop = stop
        self.lookUpTable = lookUpTable
    }
    
    // MARK: Convienience
    
    typealias Key = DictionaryPreferenceKey<Int, CGFloat> // Preference key for accessing the stops current location
    
    /// Selects/deselects the stop
    func select() {
        withAnimation(.easeIn) { () in
            if self.selection == self.id  {
                self.selection = nil
            } else {
                self.selection = self.id
            }
        }
    }
    
    /// Converts the stops position to a unit location between the start and end points
    func toUnitLocation(point: CGPoint) -> CGFloat {
        let segmentLength = sqrt((point - start).magnitudeSquared)
        let totalLength = sqrt((end-start).magnitudeSquared)
        return CGFloat((segmentLength/totalLength).clamped(to: 0...1))
    }
    
    
    /// Returns the approximate closest point on the line from the given point
    func getClosestPoint(fromPoint: CGPoint) -> CGPoint {
        let minimum = {
            (0..<lookUpTable.count).map {
                (distance: distance_squared(simd_double2(x: Double(fromPoint.x), y:Double(fromPoint.y)), simd_double2(x: Double(lookUpTable[$0].x), y: Double(lookUpTable[$0].y))), index: $0)
            }.min {
                $0.distance < $1.distance
            }
        }()
        
        return lookUpTable[minimum!.index]
    }
    
    
    /// Calculates the displacement offset from the dragGestures closest location on the lookup table to the stops original position
    func getDisplacement(closestPoint: CGPoint) -> CGSize {
        CGSize(width: closestPoint.x - position.x, height: closestPoint.y - position.y)
        
    }
    
    var gesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("follow"))
            .onChanged { (value) in
                // Find closest point to the drags location on the line defined by the start and end point
                let closestPoint = self.getClosestPoint(fromPoint: value.location)
                // set the drag state to the displacement from the original position to the closest point
                self.dragState = self.getDisplacement(closestPoint: closestPoint)
                
        }.onEnded { (value) in
            // Find closest point to the drags location on the line defined by the start and end point
            let closestPoint = self.getClosestPoint(fromPoint: value.location)
            // set the drag state to the displacement from the original position to the closest point
            let displacement = self.getDisplacement(closestPoint: closestPoint)
            // Update the stops location
            self.stop.location = self.toUnitLocation(point: self.position + displacement.toPoint() )
            self.dragState = .zero
        }
    }
    
    // MARK: Views
    
    // Overlays the stop point with a smaller circle filled with the stop color
    var colorOverlay: some View { Circle().foregroundColor(self.stop.color).frame(width: size.width*0.7, height: size.height*0.7) }
    
    var body: some View {
        GeometryReader { proxy in
            Circle()
                .foregroundColor(self.selection == self.id ? .yellow : self.backgroundColor)
                .anchorPreference(key: Key.self, value: .center,
                                  transform: { [self.id : self.toUnitLocation(point: proxy[$0])] })
                .frame(width: self.size.width, height: self.size.height)
                .shadow(radius: 3)
                .overlay( self.colorOverlay )
                .position(self.position)
                .offset(self.dragState)
                .coordinateSpace(name: "follow")
                .gesture(self.gesture)
                .simultaneousGesture(TapGesture().onEnded({ () in
                    self.select()
                }))
            
        }
    }
}

// MARK: Picker

/// # Linear Gradient Picker
///
/// Used to create weighted linear gradients
/// Has 2 types of draggable views
/// 1.  the `startPoint` and `endPoint` thumbs are shaped like capsules and rotate according to the angle of the gradient
/// 2. `LinearStop`s a circular view with a colored center corresponding the the color of the stop.
///
/// The `LinearStop`s make use of a preference key to share their current location data with the LinearGradient view.
/// By making the `LinearStops` the main view and the `LinearGradient` the background, the gradient
/// updates seemlessly when a stop is dragged.
struct LinearGradientPicker: View {
    @Binding var selection: Int? // The id of the currently selected stop if one is selected
    @Binding var hideControls: Bool // Boolean for hiding/showing the control overlay
    @Binding var startPoint: UnitPoint // Start Point of The Gradient
    @Binding var endPoint: UnitPoint // End Point of The Gradient
    @Binding var stops: [Gradient.Stop] // Gradient Stops
    
    
    @GestureState private var startState: DragState = .inactive // Gesture state for the start point thumb
    @GestureState private var endState: DragState = .inactive // Gesture state for the end point thumb
    
    
    init(selection: Binding<Int?>, hideControls: Binding<Bool>, start: Binding<UnitPoint>, end: Binding<UnitPoint>, stops: Binding<[Gradient.Stop]>) {
        self._selection = selection
        self._startPoint = start
        self._endPoint = end
        self._stops = stops
        self._hideControls = hideControls
    }
    
    
    // MARK: Customization
    var thumbColor: Color = .white // Color of the start/end point thumbs
    var thumbSize: CGSize = CGSize(width: 100, height: 15) // size of the start/end point thumbs
    
    
    // MARK: Convenience Values
    
    typealias Key = DictionaryPreferenceKey<Int, CGFloat> // Preference key for accessing the stops current location
    
    /// The start thumbs current location in unit point form
    func currentUnitStart(_ proxy: GeometryProxy) -> UnitPoint {
        if proxy.size.width == 0 || proxy.size.height == 0 { return UnitPoint.zero }
        return UnitPoint(x: self.startPoint.x + self.startState.translation.width/proxy.size.width,
                         y: self.startPoint.y + self.startState.translation.height/proxy.size.height)
    }
    /// The end thumbs current location in unit point form
    func currentUnitEnd(_ proxy: GeometryProxy) -> UnitPoint {
        if proxy.size.width == 0 || proxy.size.height == 0 { return UnitPoint.zero}
        return UnitPoint(x: self.endPoint.x + self.endState.translation.width/proxy.size.width,
                         y: self.endPoint.y + self.endState.translation.height/proxy.size.height)
    }
    /// The start thumbs current location
    func currentStartPoint(_ proxy: GeometryProxy) -> CGPoint {
        if proxy.size.width == 0 || proxy.size.height == 0 { return .zero }
        return CGPoint(x: self.startPoint.x*proxy.size.width + self.startState.translation.width,
                       y: self.startPoint.y*proxy.size.height + self.startState.translation.height)
    }
    /// The endthumbs current location
    func currentEndPoint(_ proxy: GeometryProxy) -> CGPoint {
        if proxy.size.width == 0 || proxy.size.height == 0 { return .zero }
        return CGPoint(x: self.endPoint.x*proxy.size.width + self.endState.translation.width,
                       y: self.endPoint.y*proxy.size.height + self.endState.translation.height)
    }

    
    /// Here the angle is calculated using the actual sizes of the Rectangle rather than the UnitPoint values
    /// This is because UnitPoints represent perfect squares with a side length of 1, therefore any angle calculated
    /// would be for a square region rather than a rectangular
    func angle(_ proxy: GeometryProxy) -> Angle {
        let diff = currentEndPoint(proxy)-currentStartPoint(proxy)
        return Angle(radians: diff.x == 0 ? Double.pi/2 : atan(Double(diff.y/diff.x)) +  .pi/2)
    }
    
    /// Creates an array of points that lie  on the line between the start and end points of the gradient
    func makeLookUpTable(_ proxy: GeometryProxy) ->  [CGPoint] {
        (0...50).map({linearInterpolation(t: Float($0)/Float(50), start: self.currentStartPoint(proxy), end: self.currentEndPoint(proxy))})
    }
    
    /// Makes the stops for the gradient using the locations from the preference key data
    /// Maps the stored stops colors to the locations from the preference key and then sorts them based on location,
    /// So that if a stop is dragged passed another the gradient is adjusted properly.
    func makeStops(locations: [Int: CGFloat]) -> [Gradient.Stop] {
        stops.enumerated()
            .map({ Gradient.Stop(color: $0.element.color, location: locations[$0.offset] ?? 0) })
            .sorted { (first, second)  in
            second.location > first.location
        }
    }
    
    // MARK: Views
    
    /// Creates a the views to be used as either the start point thumb or end point thumb
    func makeThumb(_ proxy: GeometryProxy, _ point: Binding<UnitPoint>, _ state: GestureState<DragState>) -> some View {
        let offsetX = point.x.wrappedValue*proxy.size.width + state.wrappedValue.translation.width - proxy.size.width/2
        let offsetY = point.y.wrappedValue*proxy.size.height + state.wrappedValue.translation.height - proxy.size.height/2
        
        let longPressDrag = LongPressGesture(minimumDuration: 0.05)
            .sequenced(before: DragGesture())
            .updating(state) { value, state, transaction in
                switch value {
                // Long press begins.
                case .first(true):
                    state = .pressing
                // Long press confirmed, dragging may begin.
                case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                }
        }
        .onEnded { value in
            guard case .second(true, let drag?) = value else { return }
            
            point.wrappedValue = UnitPoint(x: drag.translation.width/proxy.size.width + point.wrappedValue.x,
                                           y: drag.translation.height/proxy.size.height + point.wrappedValue.y)
        }
        
        return Capsule()
            .foregroundColor(thumbColor)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .rotationEffect(angle(proxy))
            .shadow(radius: 3)
            .offset(x: offsetX, y: offsetY)
            .gesture(longPressDrag)
            .animation(.none) // if animation is on the views spin around when angle reaches 360
            .opacity(self.hideControls ? 0 : 1)
            .animation(.easeIn)
        
    }
    
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ForEach(self.stops.indices, id: \.self) { (i)  in
                    LinearStop(selection: self.$selection,
                               start: self.currentStartPoint(proxy),
                               end: self.currentEndPoint(proxy),
                               lookUpTable: self.makeLookUpTable(proxy),
                               id: i,
                               stop: self.$stops[i])
                        .animation(.none)
                        .opacity(self.hideControls ? 0 : 1)
                        .animation(.easeIn)
                }
            }
            
        }.backgroundPreferenceValue(Key.self, { (locations: [Int: CGFloat])  in
            GeometryReader { proxy in
                ZStack {
                    Rectangle() // Gradient
                        .fill(LinearGradient(gradient: Gradient(stops: self.makeStops(locations: locations)),
                                             startPoint: self.currentUnitStart(proxy),
                                             endPoint: self.currentUnitEnd(proxy)))
                        .border(Color.white)
                        .animation(.interactiveSpring())
                    self.makeThumb(proxy, self.$startPoint, self.$startState) // Start Point Thumb
                    self.makeThumb(proxy, self.$endPoint, self.$endState) // End Point Thumb
                }
            }
        })
    }
}


