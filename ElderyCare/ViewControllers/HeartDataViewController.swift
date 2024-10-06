//
//  HeartDataViewController.swift
//  ElderyCare
//
//  Created by Despina Misheva on 26.9.24.
//

import UIKit
import Charts
import DGCharts

class HeartDataViewController: UIViewController {
    
    
    @IBOutlet weak var chartView: LineChartView!
    
    
    @IBOutlet weak var fromDatePicker: UIDatePicker!
    
    @IBOutlet weak var toDatePicker: UIDatePicker!
    
    
    @IBOutlet weak var fetchButton: UIButton!
    
    
    override func viewDidLoad() {
            super.viewDidLoad()
        
            chartView.xAxis.valueFormatter = TimeAxisValueFormatter()
            
            chartView.xAxis.labelPosition = .bottom
            chartView.xAxis.granularity = 1

            let today = Date()
            fromDatePicker.date = Calendar.current.startOfDay(for: today)
            toDatePicker.date = today

            fetchHeartRateData()
        }

        @IBAction func fetchButtonTapped(_ sender: UIButton) {
            fetchHeartRateData()
        }

    func fetchHeartRateData() {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fromDate = fromDatePicker.date
        let toDate = toDatePicker.date

        let fromDateString = dateFormatter.string(from: fromDate)
        let toDateString = dateFormatter.string(from: toDate)

        APIManager.shared.getRecentHeartRate(from: fromDateString, to: toDateString) { result in
            switch result {
            case .success(let heartRateData):
                self.updateChart(with: heartRateData)
            case .failure(let error):
                print("Error fetching data: \(error.localizedDescription)")
            }
        }
    }

    func updateChart(with heartRateData: [[String: Any]]) {
        var chartEntries: [ChartDataEntry] = []

        let customDateFormatter = DateFormatter()
        customDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        customDateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        for dataPoint in heartRateData {
            if let bpm = dataPoint["measurement"] as? Double,
               let timestampOfBpm = dataPoint["timestamp"] as? String,
               let date = customDateFormatter.date(from: timestampOfBpm) {
                
                let timeInterval = date.timeIntervalSince1970
                let entry = ChartDataEntry(x: timeInterval, y: bpm)
                chartEntries.append(entry)
                print("Parsed date: \(date), bpm: \(bpm)")
            }
        }

        print("Chart entries: \(chartEntries)")

        guard !chartEntries.isEmpty else {
            DispatchQueue.main.async {
                self.chartView.clear()
                self.chartView.noDataText = "No data available for the selected period"
            }
            return
        }

        DispatchQueue.main.async {
            self.chartView.data = nil
            let dataSet = LineChartDataSet(entries: chartEntries, label: "Heart Rate")
            dataSet.colors = [.blue]
            dataSet.circleColors = [.red]
            dataSet.circleRadius = 4.0

            let chartData = LineChartData(dataSet: dataSet)

            self.chartView.data = chartData
            self.chartView.notifyDataSetChanged()
        }
    }

}


