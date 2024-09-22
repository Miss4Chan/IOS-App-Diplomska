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
            if isConnected {
                self.connectionLbl.text = "Connected!"
                self.connectionLbl.textColor = UIColor.blue
            } else {
                self.connectionLbl.text = "Disconnected"
                self.connectionLbl.textColor = UIColor.red
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

    
    func didReceiveRegularHeartRate(_ heartRate: Double, timestamp: String) {
        print("UI: Updating regular heart rate label.")
        DispatchQueue.main.async {
            self.dataLbl.text = "HR: \(heartRate), Timestamp: \(timestamp)"
            self.eventDataLbl.text = "" // Clear event label for regular heart rate
        }

        print("Sending regular heart rate to API: \(heartRate), \(timestamp)")
        
        APIManager.shared.sendHeartRate(heartRate: heartRate, timestamp: timestamp) { error in
            if let error = error {
                print("Error sending heart rate: \(error)")
            } else {
                print("Successfully sent heart rate to API")
            }
        }
    }


      func didReceiveHighHeartRate(_ heartRate: Double, isConfirmed: Bool, timeOfConfirmation: String, timestamp: String) {
          print("UI: Updating high BPM label.")
          DispatchQueue.main.async {
              self.dataLbl.text = "HR: \(heartRate), Timestamp: \(timestamp)"
              self.eventDataLbl.text = "High BPM: Confirmed: \(isConfirmed ? "Yes" : "No")"
          }

          APIManager.shared.sendHighHeartRate(heartRate: heartRate, confirm: isConfirmed, timeOfConfirmation: timeOfConfirmation, timestamp: timestamp) { error in
              if let error = error {
                  print("Error sending high heart rate: \(error)")
              }
          }
      }

      func didReceiveFallDetection(event: [String: Any]) {
          print("UI: Updating fall detection label.")
          DispatchQueue.main.async {
              self.eventDataLbl.text = "Fall Detected: Confirmed: \(event["confirm"] as? Bool ?? false ? "Yes" : "No")"
          }

          APIManager.shared.sendSuddenMovement(event: event) { error in
              if let error = error {
                  print("Error sending fall detection: \(error)")
              } else {
                  print("Fall detection event sent successfully.")
              }
          }
      }
}
