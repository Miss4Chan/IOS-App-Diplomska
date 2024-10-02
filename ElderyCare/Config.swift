//
//  Config.swift
//  ElderyCare
//
//  Created by Despina Misheva on 22.9.24.
//
import Foundation
import CoreBluetooth

struct Config {
    // Bluetooth UUIDs
    static let BLE_Service_UUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    static let BLE_Characteristic_uuid_Rx = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    static let BLE_Characteristic_uuid_Tx = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    
    // API URL
    static let baseURL = "http://192.168.100.9:5008"
    
    // API Endpoints
    struct APIEndpoints {
        static let createHeartRate = "/api/HeartRate/createHeartRate"
        static let createHighHeartRate = "/api/HeartRate/createHighHeartRate"
        static let createSuddenMovement = "/api/SuddenMovement/createSuddenMovement"
        static let getRecentHeartRate = "/api/HeartRate/getRecentHeartRate"
        static let login = "/api/Account/login"
        static let register = "/api/Account/register"
        static let bulkHeartRate = "/api/HeartRate/bulkHeartRate"
        static let markMedication = "/api/MedicationIntake/mark-intake"
        static let deleteMedication = "/api/Medication/deleteMedication"
        static let createMedication = "/api/Medication/createMedication"
        static let allMedication = "/api/Medication/getMedications"
        static let allDailyMedication = "/api/medication/getDailyMedications"
    }
    
    static let scanTimeoutInterval: TimeInterval = 10.0
}

