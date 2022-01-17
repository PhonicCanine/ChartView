//
//  Line.swift
//  LineChart
//
//  Created by András Samu on 2019. 08. 30..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct Line: View {
    @ObservedObject var data: ChartData
    @Binding var frame: CGRect
    @Binding var touchLocation: CGPoint
    @Binding var showIndicator: Bool
    @Binding var minDataValue: Double?
    @Binding var maxDataValue: Double?
    @State private var showFull: Bool = false
    @State var showBackground: Bool = true
    
    var animate: Bool = true
    var displayYAxisGridLines = 0
    var displayXAxisLabels = 0
    var getXAxisLabel: (Int) -> String = {i in "\(i)"}
    
    var gradient: GradientColor = GradientColor(start: Colors.GradientPurple, end: Colors.GradientNeonBlue)
    var backgroundColor = Colors.GradientUpperBlue
    var index:Int = 0
    let padding:CGFloat = 30
    var curvedLines: Bool = true
    var stepWidth: CGFloat {
        if data.points.count < 2 {
            return 0
        }
        return frame.size.width / CGFloat(data.points.count-1)
    }
    var stepHeight: CGFloat {
        var min: Double?
        var max: Double?
        let points = self.data.onlyPoints()
        if minDataValue != nil && maxDataValue != nil {
            min = minDataValue!
            max = maxDataValue!
        }else if let minPoint = points.min(), let maxPoint = points.max(), minPoint != maxPoint {
            min = minPoint
            max = maxPoint
        }else {
            return 0
        }
        if let min = min, let max = max, min != max {
            if (min <= 0){
                return (frame.size.height-padding) / CGFloat(max - min)
            }else{
                return (frame.size.height-padding) / CGFloat(max - min)
            }
        }
        return 0
    }
    var path: Path {
        let points = self.data.onlyPoints()
        return curvedLines ? Path.quadCurvedPathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: minDataValue) : Path.linePathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight))
    }
    var closedPath: Path {
        let points = self.data.onlyPoints()
        return curvedLines ? Path.quadClosedCurvedPathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: minDataValue) : Path.closedLinePathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight))
    }
    
    
    
    
    func drawGridLine(min: Double, step: Double, i: Int, nums: Bool = false) -> some View {
        HStack {
            let hasdp = step*Double(i)+min != floor(step*Double(i)+min)
            Text(String(format: hasdp ? "%.1f" : "%.0f", step*Double(i)+min))
                .font(Font.system(size: 10))
                .foregroundColor(nums ? .gray : .clear)
                .padding(.horizontal,3)
                .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(nums ? .gray : .clear)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.white)))
            Rectangle().fill(nums ? .clear : .gray).frame(height: 1)
                .animation(animate ? .easeIn(duration: 1.6) : .linear(duration: 0))
        }.frame(height: 1)
    }
    
    func drawGridLines(min: Double, step: Double, nums: Bool = false) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<displayYAxisGridLines, id: \.self) { i in
                drawGridLine(min: min, step: step, i: i, nums: nums)
                if i < displayYAxisGridLines - 1 {
                    Spacer()
                }
            }
        }.frame(height: frame.height - padding).padding(.top, padding/2)
    }
    
    func drawXLabels() -> some View {
        HStack {
            ForEach(0..<displayXAxisLabels, id: \.self) { i in
                HStack {
                    Text(getXAxisLabel(i))
                        .font(Font.custom("Futura", size: 9))
                        .foregroundColor(.gray)
                        .frame(width: 100)
                }.frame(width:1)
                if i < displayXAxisLabels - 1 {
                    Spacer()
                }
            }
        }
    }
    
    public var body: some View {
        VStack {
            ZStack {
                let min = data.points.min { a, b in
                    a.1 > b.1
                }?.1 ?? 0
                let max = data.points.max { a, b in
                    a.1 > b.1
                }?.1 ?? 0
                let range = max-min
                let step = range / Double((displayYAxisGridLines - 1))
                if displayYAxisGridLines > 1 {
                    drawGridLines(min: min, step: step)
                }
                ZStack {
                    if(self.showFull && self.showBackground){
                        self.closedPath
                            .fill(LinearGradient(gradient: Gradient(colors: [backgroundColor.opacity(0.5), .white.opacity(0.5)]), startPoint: .bottom, endPoint: .top))
                            .rotationEffect(.degrees(180), anchor: .center)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .transition(.opacity)
                            .animation(animate ? .easeIn(duration: 1.6) : .linear(duration: 0))
                    }
                    self.path
                        .trim(from: 0, to: self.showFull ? 1:0)
                        .stroke(LinearGradient(gradient: gradient.getGradient(), startPoint: .leading, endPoint: .trailing) ,style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                        .rotationEffect(.degrees(180), anchor: .center)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .animation(animate ? Animation.easeOut(duration: 1.2).delay(Double(self.index)*0.4) : .linear(duration: 0))
                        .onAppear {
                            self.showFull = true
                    }
                    .onDisappear {
                        self.showFull = false
                    }
                    if(self.showIndicator) {
                        IndicatorPoint()
                            .position(self.getClosestPointOnPath(touchLocation: self.touchLocation))
                            .rotationEffect(.degrees(180), anchor: .center)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    }
                }
                if displayYAxisGridLines > 1 {
                    drawGridLines(min: min, step: step, nums: true)
                }
            }
            if displayXAxisLabels > 1 {
                drawXLabels()
            }
        }
    }
    
    func getClosestPointOnPath(touchLocation: CGPoint) -> CGPoint {
        let closest = self.path.point(to: touchLocation.x)
        return closest
    }
    
}

struct Line_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GeometryReader{ geometry in
                Line(data: ChartData(points: [12,-230,10,54]), frame: .constant(geometry.frame(in: .local)), touchLocation: .constant(CGPoint(x: 100, y: 12)), showIndicator: .constant(true), minDataValue: .constant(nil), maxDataValue: .constant(nil))
            }.frame(width: 320, height: 160)
            GeometryReader{ geometry in
                Line(data: ChartData(points: [12,-230,10,54,42]), frame: .constant(geometry.frame(in: .local)), touchLocation: .constant(CGPoint(x: 100, y: 12)), showIndicator: .constant(true), minDataValue: .constant(nil), maxDataValue: .constant(nil),
                    displayYAxisGridLines: 3,
                    displayXAxisLabels: 3)
            }.frame(width: 320, height: 160)
        }
    }
}
