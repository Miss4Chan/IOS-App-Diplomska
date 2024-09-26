//
//  TimeAxisValueFormatter.swift
//  ElderyCare
//
//  Created by Despina Misheva on 26.9.24.
//

import DGCharts
import ObjectiveC
import Foundation


class TimeAxisValueFormatter: NSObject, AxisValueFormatter {
    private let dateFormatter = DateFormatter()

    override init() {
        super.init()
        // Format time as HH:mm (hours and minutes)
        dateFormatter.dateFormat = "HH:mm"
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        // Convert time interval to Date and then to time string
        let date = Date(timeIntervalSince1970: value)
        return dateFormatter.string(from: date)
    }
}
