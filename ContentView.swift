//
//  ContentView.swift
//  LinearGradientPickerTutorial
//
//  Created by Kieran Brown on 2/21/20.
//  Copyright © 2020 BrownandSons. All rights reserved.
//

import SwiftUI


struct FullLinearGradientExample: View {
    @State var start: UnitPoint = .leading
    @State var end: UnitPoint = .trailing
    @State var stops: [Gradient.Stop] = [.init(color: .blue, location: 0), .init(color: .green, location: 0.4), .init(color: .purple, location: 0.7),   .init(color: .red, location: 1)]
    @State var hideControls: Bool = false
    @State var selection: Int? = nil
    @State var red: Double = 0.5
    @State var green: Double = 0.5
    @State var blue: Double = 0.5
    
    
    
    var body: some View {
        
    VStack {
        Spacer()
        LinearGradientPicker(selection: $selection, hideControls: $hideControls, start: $start, end: $end, stops: Binding(get: {
            return self.stops
        }, set: { (stops: [Gradient.Stop]) in
            self.stops = stops.sorted(by: { (first, second)  in
                second.location > first.location
            })
        })).padding(50)
        RGBColorPicker(red: $red, green: $green, blue: $blue) { (color) in
            RoundedRectangle(cornerRadius: 5).fill(color).frame(width: 300, height: 200).offset(x: 0, y: -50)
        }
        HStack {
            Button("Add Stop") {
                self.stops.append(.init(color: Color(red: self.red, green: self.green, blue: self.blue), location: 1))
            }
            Button("Delete Selected") {
                self.stops.remove(at: self.selection!)
            }.disabled(self.selection == nil)
        }
        Toggle(isOn: $hideControls) { ()  in
            Text("Hide Controls")
        }.padding()
    
    }
    .background(Color(red: 0.4, green: 0.45, blue: 0.45)).edgesIgnoringSafeArea(.all)
        
        
    }
}

struct ContentView: View {
    var body: some View {
        FullLinearGradientExample()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
