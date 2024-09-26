import Foundation

class APIManager: NSObject, URLSessionDelegate {
    static let shared = APIManager() // Singleton instance for APIManager

    // Background session declaration
    private var backgroundSession: URLSession!

    override init() {
        super.init()
        // Background session setup
        let config = URLSessionConfiguration.background(withIdentifier: "com.yourapp.backgroundSession")
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func sendPostRequestInBackground(to urlString: String, body: Any) {
        guard let request = createRequest(urlString: urlString, method: "POST", body: body) else { return }
        let task = backgroundSession.dataTask(with: request)
        task.resume()
    }


    // Logout function
    func logout() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    private func createRequest(urlString: String, method: String, body: Any? = nil) -> URLRequest? {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = APIManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("No token available")
        }

        // Serialize the body, which can be either an array or dictionary
        if let body = body {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                print("Failed to serialize request body")
                return nil
            }
            request.httpBody = jsonData
        }

        return request
    }




    // Handle response helper function
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<Data, Error>) -> Void) {
        if let error = error {
            print("API request failed with error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if let data = data {
                    print("API request successful with response code 200")
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "No data received", code: 204, userInfo: nil)))
                }
            } else {
                let responseData = String(data: data ?? Data(), encoding: .utf8) ?? "No response data"
                print("API request failed with status code: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "API Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseData])))
            }
        }
    }
    public func sendPostRequest(to urlString: String, body: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let request = createRequest(urlString: urlString, method: "POST", body: body) else {
            completion(.failure(NSError(domain: "Invalid Request", code: 400, userInfo: nil)))
            return
        }
        
        // Use a regular session for foreground tasks
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    // GET request
    func sendGetRequest(to urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let request = createRequest(urlString: urlString, method: "GET") else {
            completion(.failure(NSError(domain: "Invalid Request", code: 400, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }


    // Helper function to parse JSON data
    private func parseJSONData(_ data: Data, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                completion(.success(jsonArray))
            } else {
                let error = NSError(domain: "Invalid JSON structure", code: 500, userInfo: nil)
                completion(.failure(error))
            }
        } catch {
            completion(.failure(error))
        }
    }

    // Login and save user (username and token) on success
    func login(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let body = ["username": username, "password": password]

        sendPostRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.login)", body: body) { result in
            switch result {
            case .success(let data):
                if let token = self.extractToken(from: data) {
                    let user = User(username: username, token: token)
                    self.saveUser(user) // Save the user in UserDefaults
                    completion(.success(user))
                } else {
                    let error = NSError(domain: "Token parsing error", code: 400, userInfo: nil)
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    
    func getRecentHeartRate(from: String, to: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let urlString = "\(Config.baseURL)\(Config.APIEndpoints.getRecentHeartRate)?from=\(from)&to=\(to)"
        sendGetRequest(to: urlString) { result in
            switch result {
            case .success(let data):
                self.parseJSONData(data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    // Register and save user (username and token) on success
    func register(username: String, password: String, firstName: String, lastName: String, email: String, dateOfBirth: String, completion: @escaping (Result<User, Error>) -> Void) {
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "dateOfBirth": dateOfBirth
        ]

        sendPostRequest(to: "\(Config.baseURL)\(Config.APIEndpoints.register)", body: body) { result in
            switch result {
            case .success(let data):
                if let token = self.extractToken(from: data) {
                    let user = User(username: username, token: token)
                    self.saveUser(user) // Save the user in UserDefaults
                    completion(.success(user))
                } else {
                    let error = NSError(domain: "Token parsing error", code: 400, userInfo: nil)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                // Assume 'error' is an Error, try to extract data from the response (if available)
                if let nsError = error as NSError?, let responseData = nsError.userInfo["data"] as? Data {
                    // Try to extract the error message from responseData (if available)
                    if let errorMessage = self.extractErrorMessage(from: responseData) {
                        let customError = NSError(domain: "Server Error", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        completion(.failure(customError))
                    } else {
                        completion(.failure(nsError)) // Pass the original NSError
                    }
                } else {
                    completion(.failure(error)) // Generic failure
                }
            }
        }


    }

    // Function to extract the error message from the server response
    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonDict = json as? [String: Any],
           let message = jsonDict["message"] as? String {
            return message
        }
        return nil
    }

    // Save user to UserDefaults
    private func saveUser(_ user: User) {
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: "currentUser")
            UserDefaults.standard.set(user.token, forKey: "userToken") // Also save the token separately for easy access
        }
    }

    // Retrieve the user from UserDefaults
    public func getUser() -> User? {
        if let savedUserData = UserDefaults.standard.object(forKey: "currentUser") as? Data,
           let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
            return savedUser
        }
        return nil
    }

    // Retrieve the token from UserDefaults
    public func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "userToken")
    }

    // Extract token from response data
    private func extractToken(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonDict = json as? [String: Any],
           let token = jsonDict["token"] as? String {
            return token
        }
        return nil
    }

    // Save token to UserDefaults
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "userToken")
    }
}
