//
//  RGBColorPicker.swift
//  LinearGradientPickerTutorial
//
//  Created by Kieran Brown on 2/21/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI


/// # Red Green Or Blue Color Picker
///
/// Creates a custom slider for either red, green, or blue
struct ColorSlider: View {
    @State private var dragState: CGSize = .zero
    @Binding var value: Double
    
    typealias Key = DictionaryPreferenceKey<ColorType, CGFloat>
    
    var type: ColorType
    var colors: [Color] {
        switch type {
            
        case .red:
            return [Color(red: 0, green: 0, blue: 0), Color(red: 1, green: 0, blue: 0)]
        case .green:
            return [Color(red: 0, green: 0, blue: 0), Color(red: 0, green: 1, blue: 0)]
        case .blue:
            return [Color(red: 0, green: 0, blue: 0), Color(red: 0, green: 0, blue: 1)]
            
        }
    }
    enum ColorType: String, CaseIterable {
        case red
        case green
        case blue
    }
    
    
    // MARK: Customization
    var thumbBackgroundColor: Color = Color(red: 0.7, green: 0.7, blue: 0.7)
    

    
    func getThumb(proxy: GeometryProxy) -> some View {
        
        let dragGesture = DragGesture().onChanged { value in
            self.dragState = value.translation
        }.onEnded { value in
            self.value = limitUnitValue(self.value, proxy.size.width, self.dragState.width)
            self.dragState = .zero
        }
        
        let currentColor: Color =  {
            switch type {
                
            case .red:
                return Color(red: limitUnitValue(self.value, proxy.size.width, dragState.width), green: 0, blue: 0)
            case .green:
                return Color(red: 0, green: limitUnitValue(self.value, proxy.size.width, dragState.width), blue: 0)
            case .blue:
                return Color(red: 0, green: 0, blue: limitUnitValue(self.value, proxy.size.width, dragState.width))
            }
        }()
        
        
        
        let overlay = RoundedRectangle(cornerRadius: 2)
            .foregroundColor(currentColor)
            .frame(width: proxy.size.width/20, height: proxy.size.height)
        
        
        // MARK: Customize Thumb Here
        
        // Add the gestures and visuals to the thumb
        return Capsule()
            .foregroundColor(thumbBackgroundColor)
            .anchorPreference(key: Key.self, value: .center, transform: { [self.type : proxy[$0].x/proxy.size.width] })
            .frame(width: proxy.size.width/12, height: proxy.size.height*1.66, alignment: .center)
            .shadow(radius: 3)
            .overlay( overlay )
            .position(x: limitValue(self.value, proxy.size.width, dragState.width),
                      y: proxy.size.height/2)
            .gesture(dragGesture)
    }
    
    
    var body: some View {
        
        Capsule()
            .fill(LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing))
            .overlay(
                GeometryReader { (proxy: GeometryProxy) in
                    ZStack {
                        Capsule().stroke(Color.gray)
                        self.getThumb(proxy: proxy)
                    }
                    
                }
        )
    }
    
    
}

/// # RGB Color Picker
///
/// Provide values for each of the color components and a view that will be used to test out the color
/// The `testView` parameter gives access to the current color, so that you can use any view you want
struct RGBColorPicker<V: View>: View {
    @Binding var red: Double
    @Binding var green: Double
    @Binding var blue: Double
    var testView: (Color) -> V

    typealias Key = DictionaryPreferenceKey<ColorSlider.ColorType, CGFloat>
    
    func getCurrentColor(_ values: [ColorSlider.ColorType : CGFloat]) -> Color {
        Color(red: Double(values[.red]!), green: Double(values[.green]!), blue: Double(values[.blue]!))
    }
    var redSlider: some View {
        HStack {
            TextField("", value: $red, formatter: formatter).frame(width: 50)
            ColorSlider(value: $red, type: .red)
        }
    }
    
    var greenSlider: some View {
        HStack {
            TextField("", value: $green, formatter: formatter).frame(width: 50)
            ColorSlider(value: $green, type: .green)
        }
    }
    
    var blueSlider: some View {
        HStack {
            TextField("", value: $blue, formatter: formatter).frame(width: 50)
            ColorSlider(value: $blue, type: .blue)
        }
    }

    
    var body: some View {
        VStack(spacing: 5) {
            Spacer().frame(minWidth: 150, minHeight: 150)
            Group {
                redSlider
                greenSlider
                blueSlider
            }
            .frame(minWidth: 150, maxWidth: 300, minHeight: 7, idealHeight: 30, maxHeight: 30)
            .padding(.all, 10)
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlayPreferenceValue(Key.self) { (values: [ColorSlider.ColorType: CGFloat])  in
                GeometryReader { proxy in
                    self.testView(self.getCurrentColor(values))
                        .position(CGPoint(x: proxy.size.width/2, y: proxy.size.height/3))
                }
                
        }
    }
}
