import Foundation

class DataManager {
    static let shared = DataManager()

    private init() { }

    
    private func sendData(to endpoint: String, body: [String: Any]) {
            APIManager.shared.sendPostRequestInBackground(to: "\(Config.baseURL)\(endpoint)", body: body)
        }

        // Handle heart rate
        func handleHeartRateData(heartRate: Double, timestamp: String) {
            let body: [String: Any] = ["measurement": heartRate, "timestamp": timestamp]
            sendData(to: Config.APIEndpoints.createHeartRate, body: body)
            print("Sent data from data manager")
        }

        // Handle high heart rate
        func handleHighHeartRateData(heartRate: Double, isConfirmed: Bool, timeOfConfirmation: String, timestamp: String) {
            let body: [String: Any] = [
                "measurement": heartRate,
                "confirm": isConfirmed,
                "timeOfConfirmation": timeOfConfirmation,
                "timestamp": timestamp
            ]
            sendData(to: Config.APIEndpoints.createHighHeartRate, body: body)
        }

        // Handle fall detection
        func handleFallDetectionData(event: [String: Any]) {
            sendData(to: Config.APIEndpoints.createSuddenMovement, body: event)
        }
    
    func sendBulkHeartRateData(_ heartRateData: [[String: Any]]) {
        APIManager.shared.sendPostRequestInBackground(to: "\(Config.baseURL)\(Config.APIEndpoints.bulkHeartRate)", body: heartRateData)
        print("Bulk heart rate data sent.")
    }


}

