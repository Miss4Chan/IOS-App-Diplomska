import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    func didReceiveRegularHeartRate(_ heartRate: Double, timestamp: String)
    func didReceiveHighHeartRate(_ heartRate: Double, isConfirmed: Bool, timeOfConfirmation: String, timestamp: String)
    func didReceiveFallDetection(event: [String: Any])
    func didUpdateConnectionStatus(isConnected: Bool)
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothManager()
    
    public var centralManager: CBCentralManager!
    public var curPeripheral: CBPeripheral?
    public var rxCharacteristic: CBCharacteristic?
    public var txCharacteristic: CBCharacteristic?
    
    private var receivedDataBuffer: String = ""
    
    weak var delegate: BluetoothManagerDelegate?
    
    private let BLE_Service_UUID = Config.BLE_Service_UUID
    private let BLE_Characteristic_uuid_Rx = Config.BLE_Characteristic_uuid_Rx
    private let BLE_Characteristic_uuid_Tx = Config.BLE_Characteristic_uuid_Tx
    
    
    private var heartRateDataBuffer: [(heartRate: Double, timestamp: String)] = []
    
    private var heartRateTimer: Timer?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }
    
    func startScan() {
        centralManager.scanForPeripherals(withServices: [BLE_Service_UUID], options: nil)
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on. Starting scan.")
            BluetoothManager.shared.startScan()
        } else {
            print("Bluetooth is not available.")
        }
    }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        curPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Successfully connected to peripheral: \(peripheral.name ?? "Unknown")")
        delegate?.didUpdateConnectionStatus(isConnected: true)
        peripheral.delegate = self
        peripheral.discoverServices([BLE_Service_UUID])
        startHeartRateBuffering()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        delegate?.didUpdateConnectionStatus(isConnected: false)
        stopHeartRateBuffering()
    }

    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == BLE_Service_UUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == BLE_Characteristic_uuid_Rx {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == BLE_Characteristic_uuid_Tx {
                txCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == rxCharacteristic, let data = characteristic.value, let receivedString = String(data: data, encoding: .utf8) else {
            print("No data or incorrect characteristic")
            return
        }
        
        receivedDataBuffer += receivedString

        while let jsonDataRange = receivedDataBuffer.range(of: "}") {
            let jsonString = String(receivedDataBuffer[..<jsonDataRange.upperBound])
            receivedDataBuffer = String(receivedDataBuffer[jsonDataRange.upperBound...])
        
            if let jsonData = jsonString.data(using: .utf8),
               let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                print("Processing received data: \(jsonString)")
                processReceivedData(jsonDict)
            } else {
                print("Failed to parse received JSON")
            }
        }
        
        print("Waiting for more data...")
    }


    private func processReceivedData(_ jsonDict: [String: Any]) {
        guard let heartRate = jsonDict["bpm"] as? Double,
              let timestamp = jsonDict["timestamp"] as? String else {
            print("Invalid data")
            return
        }

        if let event = jsonDict["event"] as? String {
            switch event {
            case "High BPM":
                let isConfirmed = jsonDict["confirm"] as? Bool ?? false
                let timeOfConfirmation = jsonDict["timeOfConfirmation"] as? String ?? ""
                DataManager.shared.handleHighHeartRateData(heartRate: heartRate, isConfirmed: isConfirmed, timeOfConfirmation: timeOfConfirmation, timestamp: timestamp)
                
                DispatchQueue.main.async {
                    self.delegate?.didReceiveHighHeartRate(heartRate, isConfirmed: isConfirmed, timeOfConfirmation: timeOfConfirmation, timestamp: timestamp)
                }
                
            case "Fall Detected":
                DataManager.shared.handleFallDetectionData(event: jsonDict)
                
                DispatchQueue.main.async {
                    self.delegate?.didReceiveFallDetection(event: jsonDict)
                }
                
            default:
                print("Unknown event")
            }
        } else {
            self.addHeartRateToBuffer(heartRate: heartRate, timestamp: timestamp)

            DispatchQueue.main.async {
                self.delegate?.didReceiveRegularHeartRate(heartRate, timestamp: timestamp)
            }
        }
    }


    func startHeartRateBuffering() {
        print("Attempting to start heart rate timer...")

        if heartRateTimer == nil {
            DispatchQueue.main.async {
                self.heartRateTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.sendBulkHeartRateData), userInfo: nil, repeats: true)
                RunLoop.main.add(self.heartRateTimer!, forMode: .common)
                print("Heart rate timer started successfully!")
            }
        } else {
            print("Timer already running")
        }
    }


       func addHeartRateToBuffer(heartRate: Double, timestamp: String) {
           heartRateDataBuffer.append((heartRate: heartRate, timestamp: timestamp))
           print("Added new measurement \((heartRate: heartRate, timestamp: timestamp))" );
       }

    @objc private func sendBulkHeartRateData() {
        print("Timer fired - sending bulk heart rate data...")
        guard !heartRateDataBuffer.isEmpty else {
            print("No heart rate data to send.")
            return
        }

        let bulkData: [[String: Any]] = heartRateDataBuffer.map { ["measurement": $0.heartRate, "timestamp": $0.timestamp] }
        DataManager.shared.sendBulkHeartRateData(bulkData)
        
        heartRateDataBuffer.removeAll()
    }

       
       func stopHeartRateBuffering() {
           heartRateTimer?.invalidate()
           heartRateTimer = nil
       }
}

