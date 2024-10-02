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
    
    // Fetch daily medications
    func fetchDailyMedications(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        APIManager.shared.sendGetRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.allDailyMedication)") { result in
            switch result {
            case .success(let data):
                APIManager.shared.parseJSONData(data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // Fetch all medications
    func fetchAllMedications(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        APIManager.shared.sendGetRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.allMedication)") { result in
            switch result {
            case .success(let data):
                APIManager.shared.parseJSONData(data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func createMedication(name: String, repeatingPattern: [Int], completion: @escaping (Result<Void, Error>) -> Void) {
            let body: [String: Any] = [
                "medicationName": name,
                "repeatingPattern": repeatingPattern
            ]

        APIManager.shared.sendPostRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.createMedication)", body: body) { result in
                switch result {
                case .success(_):
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

    func markMedicationAsTaken(medicationId: Int, taken: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
           let dateFormatter = ISO8601DateFormatter()
           dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
           let body: [String: Any] = ["medicationId": medicationId, "taken": taken, "timestamp": dateFormatter.string(from: Date())]
        APIManager.shared.sendPostRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.markMedication)", body: body) { result in
               switch result {
               case .success(_):
                   completion(.success(()))
               case .failure(let error):
                   completion(.failure(error))
               }
           }
       }
    // Delete medication
    func deleteMedication(medicationId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        APIManager.shared.sendPostRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.deleteMedication)/\(medicationId)", body: [:]) { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }



}

