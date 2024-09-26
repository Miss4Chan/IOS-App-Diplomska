import UIKit

class ViewController: UIViewController, BluetoothManagerDelegate {
    
    @IBOutlet weak var connectionLbl: UILabel!
    @IBOutlet weak var dataLbl: UILabel!
    @IBOutlet weak var eventDataLbl: UILabel!
    
    @IBAction func refreshBtn(_ sender: Any) {
        if let peripheral = BluetoothManager.shared.curPeripheral {
                   BluetoothManager.shared.centralManager.cancelPeripheralConnection(peripheral)
               }
               BluetoothManager.shared.startScan()
    }

    
    func didUpdateConnectionStatus(isConnected: Bool) {
        DispatchQueue.main.async {
            self.connectionLbl.text = isConnected ? "Connected!" : "Disconnected"
            self.connectionLbl.textColor = isConnected ? .blue : .red
            
            if !isConnected {
                self.dataLbl.text = "No Data"
                self.eventDataLbl.text = "No Event Data"
            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Elder Care"
        BluetoothManager.shared.delegate = self
        
        print("Starting Bluetooth scan...")
        BluetoothManager.shared.startScan()
    }

    @IBAction func logout(_ sender: Any) {
        APIManager.shared.logout()
        navigateToInitialViewController()
    }
    
    private func navigateToInitialViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "NavigationController") // Replace with your initial view controller identifier
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = initialViewController
            window.makeKeyAndVisible()
        }
    }
    func didReceiveRegularHeartRate(_ heartRate: Double, timestamp: String) {
        // Simulate parsing data from the background API call
        DispatchQueue.global(qos: .background).async {
            // Assume data is received from the background API and parsed here

            // Once parsed, update the UI on the main thread
            DispatchQueue.main.async {
                self.dataLbl.text = "HR: \(heartRate), Timestamp: \(timestamp)"
                self.eventDataLbl.text = ""
            }
        }
    }

    func didReceiveHighHeartRate(_ heartRate: Double, isConfirmed: Bool, timeOfConfirmation: String, timestamp: String) {
        let confirmationStatus = isConfirmed ? "Yes" : "No"
        
        // Simulate parsing data from the background API call
        DispatchQueue.global(qos: .background).async {
            // Assume data is received from the background API and parsed here
            
            // Once parsed, update the UI on the main thread
            DispatchQueue.main.async {
                self.dataLbl.text = "HR: \(heartRate), Timestamp: \(timestamp)"
                self.eventDataLbl.text = "High BPM: Confirmed: \(confirmationStatus)"
            }
        }
    }

        // Fall detection event received
    func didReceiveFallDetection(event: [String: Any]) {
        let confirmed = (event["confirm"] as? Bool ?? false) ? "Yes" : "No"
        
        // Simulate parsing data from the background API call
        DispatchQueue.global(qos: .background).async {
            // Assume data is received from the background API and parsed here
            
            // Once parsed, update the UI on the main thread
            DispatchQueue.main.async {
                self.eventDataLbl.text = "Fall Detected: Confirmed: \(confirmed)"
            }
        }
    }

}
