import Foundation

class APIManager {
    static let shared = APIManager()
    
    private func sendRequest(to urlString: String, body: [String: Any], completion: @escaping (Error?) -> Void) {
        print("Sending API request to URL: \(urlString)")
        print("Request body: \(body)")
        
        guard let url = URL(string: urlString),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("Failed to serialize request body or invalid URL")
            completion(NSError(domain: "Invalid URL or Data", code: 400, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API request failed with error: \(error.localizedDescription)")
                completion(error)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("API request successful with response code 200")
                    completion(nil)
                } else {
                    print("API request failed with status code: \(httpResponse.statusCode)")
                    let responseData = String(data: data ?? Data(), encoding: .utf8) ?? "No response data"
                    print("Response Data: \(responseData)")
                    completion(NSError(domain: "API Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseData]))
                }
            }
        }.resume()
    }
    
    func sendHeartRate(heartRate: Double, timestamp: String, completion: @escaping (Error?) -> Void) {
        let body: [String: Any] = ["measurement": heartRate, "timestamp": timestamp]
        sendRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.createHeartRate)", body: body, completion: completion)
    }
    
    func sendHighHeartRate(heartRate: Double, confirm: Bool, timeOfConfirmation: String, timestamp: String, completion: @escaping (Error?) -> Void) {
        let body: [String: Any] = [
            "measurement": heartRate,
            "confirm": confirm,
            "timeOfConfirmation": timeOfConfirmation,
            "timestamp": timestamp
        ]
        sendRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.createHighHeartRate)", body: body, completion: completion)
    }
    
    func sendSuddenMovement(event: [String: Any], completion: @escaping (Error?) -> Void) {
        let body: [String: Any] = [
            "timestamp": event["fallTime"] ?? event["timestamp"] ?? "",
            "confirm": event["confirm"] as? Bool ?? false,
            "timeOfConfirmation": event["timeOfConfirmation"] as? String ?? ""
        ]
        sendRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.createSuddenMovement)", body: body, completion: completion)
    }
}

