//
//  LineCard.swift
//  LineChart
//
//  Created by András Samu on 2019. 08. 31..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public enum GridLineSpecifier {
    case none
    case auto
    case specific(n: Int)
}

public enum xLabelType {
    case auto
    case specific(getXLabel: (Int) -> String)
}

public struct LineChartView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var data:ChartData
    public var title: String
    public var legend: String?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    
    public var formSize:CGSize
    public var dropShadow: Bool
    public var onCard: Bool
    public var getXLabel: ((Int)->String)?
    public var valueSpecifier:String
    
    public var animated:Bool = false
    public var yAxisGridlines: GridLineSpecifier = .none
    public var xAxisMarkings: GridLineSpecifier = .none
    public var xLabelSource: xLabelType = .auto
    
    @State private var touchLocation:CGPoint = .zero
    @State private var showIndicatorDot: Bool = false
    @State private var currentValue: Double = 2 {
        didSet{
            if (oldValue != self.currentValue && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    @State private var currentIndex: Int = 0
    var frame = CGSize(width: 180, height: 120)
    private var rateValue: Int?
    
    public var strictSize: Bool
    
    public init(data: [Double],
                title: String,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                form: CGSize? = ChartForm.medium,
                rateValue: Int? = nil,
                dropShadow: Bool = true,
                onCard: Bool = true,
                valueSpecifier: String? = "%.1f",
                getXLabel: ((Int)->String)? = nil,
                strictSize: Bool = false,
                animated: Bool = false,
                yAxisGridlines: GridLineSpecifier = .none,
                xAxisMarkings: GridLineSpecifier = .none,
                xLabelSource: xLabelType = .auto) {
        
        self.data = ChartData(points: data)
        self.title = title
        self.legend = legend
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.formSize = form!
        frame = CGSize(width: self.formSize.width, height: self.formSize.height/2)
        self.strictSize = strictSize
        self.dropShadow = dropShadow
        self.onCard = onCard
        self.valueSpecifier = valueSpecifier!
        self.rateValue = rateValue
        self.getXLabel = getXLabel
        self.animated = false
        self.yAxisGridlines = yAxisGridlines
        self.xAxisMarkings = xAxisMarkings
        self.xLabelSource = xLabelSource
    }
    
    public var body: some View {
        ZStack(alignment: .center){
            if (self.onCard) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                    .frame(width: frame.width, height: strictSize ? frame.height*2 : 240, alignment: .center)
                    .shadow(color: self.style.dropShadowColor, radius: self.dropShadow ? 8 : 0)
            }
            VStack(alignment: .leading){
                if(!self.showIndicatorDot){
                    VStack(alignment: .leading, spacing: 8){
                        Text(self.title)
                            .font(.title)
                            .bold()
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                        if (self.legend != nil){
                            Text(self.legend!)
                                .font(.callout)
                                .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor :self.style.legendTextColor)
                        }
                        HStack {
                            
                            if let rateValue = self.rateValue
                            {
                                if (rateValue >= 0){
                                    Image(systemName: "arrow.up")
                                }else{
                                    Image(systemName: "arrow.down")
                                }
                                Text("\(rateValue)%")
                            }
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.1))
                    .padding([.leading, .top])
                }else{
                    HStack{
                        Spacer()
                        VStack {
                            Text("\(self.currentValue, specifier: self.valueSpecifier)")
                                .font(.system(size: 41, weight: .bold, design: .default))
                                .offset(x: 0, y: 30)
                            if let xLabel = getXLabel {
                                Text(xLabel(self.currentIndex))
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                                    .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor :self.style.legendTextColor)
                                    .offset(x: 0, y: 30)
                            }
                        }
                        Spacer()
                    }
                    .transition(.scale)
                }
                Spacer()
                let yGridlines = { () -> Int in
                    switch yAxisGridlines {
                    case .none:
                        return 0
                    case .specific(let n):
                        return n
                    case .auto:
                        guard frame.width > 150 else { return 0 }
                        let v = Int(frame.height / 75) + 1
                        return v > 1 ? v : 0
                    }
                }()
                let xMarkings = { () -> Int in
                    switch xAxisMarkings {
                    case .none:
                        return 0
                    case .specific(let n):
                        return n
                    case .auto:
                        guard frame.height > 70 else { return 0 }
                        guard frame.width > 50 else { return 0 }
                        let possible = data.points.count.findNTiles()
                        let reasonable = Int(ceil((frame.width / 65) + 1))
                        return possible.first { x in
                            x <= reasonable
                        } ?? 0
                    }
                }()
                VStack {
                    GeometryReader{ geometry in
                        
                        Line(data: self.data,
                             frame: .constant(geometry.frame(in: .local)),
                             touchLocation: self.$touchLocation,
                             showIndicator: self.$showIndicatorDot,
                             minDataValue: .constant(nil),
                             maxDataValue: .constant(nil),
                             animate: animated,
                             displayYAxisGridLines: yGridlines,
                             displayXAxisLabels: xMarkings,
                             getXAxisLabel: {
                            let translateNTile: (Int) -> (Int) = { n in
                                let stride = (data.points.count - 1) / (xMarkings - 1)
                                return n * stride
                            }
                            switch xLabelSource {
                            case .auto:
                                if let f = getXLabel {
                                    return { x in
                                        f(translateNTile(x))
                                    }
                                }
                                return { i in
                                    "\(translateNTile(i))"
                                }
                            case .specific(let getXLabel):
                                return getXLabel
                            }
                        }(),
                             gradient: style.gradientColor,
                             backgroundColor: style.accentColor
                        )
                    }
                }
                .padding(.horizontal, xMarkings+yGridlines > 0 ? 20 : 0)
                .padding(.bottom, 2)
                .frame(width: frame.width, height: frame.height)
                .clipShape(self.onCard ? RoundedRectangle(cornerRadius: 20) : RoundedRectangle(cornerRadius: 0))
                .offset(x: 0, y: 0)
            }.frame(width: self.formSize.width, height: self.formSize.height)
        }
        .gesture(DragGesture()
        .onChanged({ value in
            self.touchLocation = value.location
            self.showIndicatorDot = true
            self.getClosestDataPoint(toPoint: value.location, width:self.frame.width, height: self.frame.height)
        })
            .onEnded({ value in
                self.showIndicatorDot = false
            })
        )
    }
    
    @discardableResult func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        
        let index:Int = Int(round((toPoint.x)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentIndex = index
            self.currentValue = points[index]
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineChartView(data: [8,23,54,32,12,37,7,23,43], title: "Line chart", legend: "Basic")
                .environment(\.colorScheme, .light)
            
            LineChartView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188], title: "Line chart", legend: "Basic")
            .environment(\.colorScheme, .light)
            
            LineChartView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.25, 284.652, 284.129, 284.188], title: "Line chart", legend: "Basic", onCard: false, getXLabel: {i in "point \(i)"})
            .environment(\.colorScheme, .light)

            LineChartView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188], title: "Line chart", legend: "Basic", form: CGSize(width: 150, height: 150), onCard: false, getXLabel: {i in "point \(i)"}, strictSize: true)
            .environment(\.colorScheme, .light)
            
            LineChartView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188], title: "Line chart", legend: "Basic", form: CGSize(width: 300, height: 300), onCard: false, getXLabel: {i in "point \(i)"}, strictSize: true, yAxisGridlines: .auto, xAxisMarkings: .auto)
            .environment(\.colorScheme, .light)
            
            LineChartView(data: [3,1,2,3,4,5,6,7,8,9], title: "Line chart", legend: "Basic", form: CGSize(width: 300, height: 300), onCard: false, getXLabel: {i in "\(i + 1) NOV"}, strictSize: true, yAxisGridlines: .auto, xAxisMarkings: .auto)
            .environment(\.colorScheme, .light)
        }
    }
}
