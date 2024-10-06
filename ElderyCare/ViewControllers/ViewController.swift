import UIKit

class ViewController: UIViewController, BluetoothManagerDelegate {
    
    
    
    @IBOutlet weak var heartRateDataView: UIView!
    
    @IBOutlet weak var eventView: UIView!
    
    @IBOutlet weak var bluetoothConnectionView: UIView!
    
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
        
        
        eventView.layer.shadowOpacity = 0.7;
        eventView.layer.shadowOffset = CGSize(width: 3, height: 3);
        eventView.layer.shadowRadius = 15.0;
        eventView.layer.shadowColor = UIColor.darkGray.cgColor;
        
        bluetoothConnectionView.layer.shadowOpacity = 0.7;
        bluetoothConnectionView.layer.shadowOffset = CGSize(width: 3, height: 3);
        bluetoothConnectionView.layer.shadowRadius = 15.0;
        bluetoothConnectionView.layer.shadowColor = UIColor.darkGray.cgColor;
        
        heartRateDataView.layer.shadowOpacity = 0.7;
        heartRateDataView.layer.shadowOffset = CGSize(width: 3, height: 3);
        heartRateDataView.layer.shadowRadius = 15.0;
        heartRateDataView.layer.shadowColor = UIColor.darkGray.cgColor;
        
        
        eventView.layer.cornerRadius = 10.0
        eventView.layer.masksToBounds = false
        bluetoothConnectionView.layer.cornerRadius = 10.0
        bluetoothConnectionView.layer.masksToBounds = false
        heartRateDataView.layer.cornerRadius = 10.0
        heartRateDataView.layer.masksToBounds = false
        
        
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
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "NavigationController")
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = initialViewController
            window.makeKeyAndVisible()
        }
    }
    func didReceiveRegularHeartRate(_ heartRate: Double, timestamp: String) {
        DispatchQueue.global(qos: .background).async {

            let timestampString = timestamp

            let inputDateFormatter = DateFormatter()
            inputDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            inputDateFormatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = inputDateFormatter.date(from: timestampString) {
                let outputDateFormatter = DateFormatter()
                
                outputDateFormatter.dateFormat = "HH:mm:ss"
                let timeString = outputDateFormatter.string(from: date)
                
                outputDateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = outputDateFormatter.string(from: date)
                
                DispatchQueue.main.async {
                    self.dataLbl.text = "HR: \(heartRate), Time: \(timeString)\nDate: \(dateString)"
                    self.eventDataLbl.text = ""
                }
            } else {
                print("Failed to parse the timestamp string into Date.")
            }

        }
    }

    func didReceiveHighHeartRate(_ heartRate: Double, isConfirmed: Bool, timeOfConfirmation: String, timestamp: String) {
        let confirmationStatus = isConfirmed ? "Yes" : "No"
        
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        inputDateFormatter.locale = Locale(identifier: "en_US_POSIX")

        DispatchQueue.global(qos: .background).async {
            if let date = inputDateFormatter.date(from: timestamp) {
                let outputDateFormatter = DateFormatter()
                
                outputDateFormatter.dateFormat = "HH:mm:ss"
                let timeString = outputDateFormatter.string(from: date)
                
                outputDateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = outputDateFormatter.string(from: date)
                
                DispatchQueue.main.async {
                    self.dataLbl.text = "HR: \(heartRate), Time: \(timeString)\nDate: \(dateString)"
                    self.eventDataLbl.text = "High BPM -- Confirmed: \(confirmationStatus)"
                }
            } else {
                print("Failed to parse the timestamp string into Date.")
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
                self.eventDataLbl.text = "Fall Detected --  Confirmed: \(confirmed)"
            }
        }
    }

}
