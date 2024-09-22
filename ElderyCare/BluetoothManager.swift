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
    
    var centralManager: CBCentralManager!
    var curPeripheral: CBPeripheral?
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic?
    
    var receivedDataBuffer: String = "" // Buffer to accumulate data
    
    weak var delegate: BluetoothManagerDelegate?
    
    private let BLE_Service_UUID = Config.BLE_Service_UUID
    private let BLE_Characteristic_uuid_Rx = Config.BLE_Characteristic_uuid_Rx
    private let BLE_Characteristic_uuid_Tx = Config.BLE_Characteristic_uuid_Tx
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
            startScan()
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
            }
            if characteristic.uuid == BLE_Characteristic_uuid_Tx {
                txCharacteristic = characteristic
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == rxCharacteristic,
              let data = characteristic.value,
              let receivedString = String(data: data, encoding: .utf8) else {
            print("No data received or characteristic mismatch")
            return
        }
        
        receivedDataBuffer += receivedString
        print("Received partial data: \(receivedString)")
        
        if let validJsonData = receivedDataBuffer.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: validJsonData, options: []) {
            print("Processing accumulated data: \(receivedDataBuffer)")
            processReceivedData(receivedDataBuffer)
            receivedDataBuffer = ""
        } else {
            print("Waiting for more data...")
        }
    }


    private func processReceivedData(_ jsonString: String) -> Bool {
        print("Processing received data: \(jsonString)")
        
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            print("Failed to parse JSON from watch")
            return false
        }

        if jsonDict["event"] == nil {
            if let heartRate = jsonDict["bpm"] as? Double, let timestamp = jsonDict["timestamp"] as? String {
                print("Received regular heart rate data: bpm=\(heartRate), timestamp=\(timestamp)")
                
                delegate?.didReceiveRegularHeartRate(heartRate, timestamp: timestamp)
                print("Delegate method didReceiveRegularHeartRate called")
            } else {
                print("Invalid regular heart rate data: Missing bpm or timestamp")
            }
            return true
        }

        if let event = jsonDict["event"] as? String {
            if event == "Fall Detected" {
                print("Received Fall Detected event")
                let fallTime = jsonDict["fallTime"] as? String ?? "Unknown"
                let isConfirmed = jsonDict["confirm"] as? Bool ?? false
                let timeOfConfirmation = jsonDict["timeOfConfirmation"] as? String ?? ""

                print("Fall time: \(fallTime), Confirmed: \(isConfirmed), Time of Confirmation: \(timeOfConfirmation)")
                
                delegate?.didReceiveFallDetection(event: [
                    "event": event,
                    "confirm": isConfirmed,
                    "timeOfConfirmation": timeOfConfirmation,
                    "fallTime": fallTime
                ])
            } else if event == "High BPM" {
                print("Received High BPM event")
                let heartRate = jsonDict["bpm"] as? Double ?? 0.0
                let isConfirmed = jsonDict["confirm"] as? Bool ?? false
                let timeOfConfirmation = jsonDict["timeOfConfirmation"] as? String ?? ""
                let timestamp = jsonDict["timestamp"] as? String ?? ""

                print("BPM: \(heartRate), Confirmed: \(isConfirmed), Time of Confirmation: \(timeOfConfirmation)")
                
                delegate?.didReceiveHighHeartRate(heartRate, isConfirmed: isConfirmed, timeOfConfirmation: timeOfConfirmation, timestamp: timestamp)
            } else {
                print("Unknown event: \(event)")
            }
            return true
        }
        
        return false
    }
}
