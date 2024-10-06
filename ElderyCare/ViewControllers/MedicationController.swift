//
//  MedicationController.swift
//  ElderyCare
//
//  Created by Despina Misheva on 26.9.24.
//

import UIKit

class MedicationController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddMedicationDelegate {
    func didAddMedication() {
        fetchDailyMedications()
        fetchAllMedications()
    }
    

    
    
    
    @IBOutlet weak var DailyMedicationTable: UITableView!
    
    
    @IBOutlet weak var MedicationTable: UITableView!
    
    var dailyMedications: [Medication] = []
        var allMedications: [Medication] = []

        override func viewDidLoad() {
            super.viewDidLoad()

            DailyMedicationTable.delegate = self
            DailyMedicationTable.dataSource = self
            MedicationTable.delegate = self
            MedicationTable.dataSource = self

            // Set a default row height
            DailyMedicationTable.rowHeight = UITableView.automaticDimension
            DailyMedicationTable.estimatedRowHeight = 60
            MedicationTable.rowHeight = UITableView.automaticDimension
            MedicationTable.estimatedRowHeight = 60

            // Register cells if not using Storyboard-provided cells
            DailyMedicationTable.register(UITableViewCell.self, forCellReuseIdentifier: "DailyMedicationCell")
            MedicationTable.register(UITableViewCell.self, forCellReuseIdentifier: "MedicationCell")

            // Add the "Add Medication" button to the navigation bar
            let addMedicationButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMedicationButtonTapped))
            navigationItem.rightBarButtonItem = addMedicationButton

            fetchDailyMedications()
            fetchAllMedications()
        }

        @objc private func addMedicationButtonTapped() {
            performSegue(withIdentifier: "addMedicationSegue", sender: self)
        }

        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "addMedicationSegue", let destinationVC = segue.destination as? AddMedicationController {
                destinationVC.delegate = self
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            fetchDailyMedications()
            fetchAllMedications()
        }

        private func fetchDailyMedications() {
            DataManager.shared.fetchDailyMedications { result in
                switch result {
                case .success(let jsonData):
                    DispatchQueue.main.async {
                        self.dailyMedications = jsonData.compactMap { dict -> Medication? in
                            if let id = dict["medicationId"] as? Int,
                               let name = dict["medicationName"] as? String,
                               let timeOfDay = dict["timeOfDay"] as? String {
                                return Medication(medicationId: id, medicationName: name, timeOfDay: timeOfDay)
                            }
                            return nil
                        }
                        self.DailyMedicationTable.reloadData()
                    }
                case .failure(let error):
                    print("Failed to fetch daily medications: \(error)")
                }
            }
        }

        private func fetchAllMedications() {
            DataManager.shared.fetchAllMedications { result in
                switch result {
                case .success(let jsonData):
                    DispatchQueue.main.async {
                        self.allMedications = jsonData.compactMap { dict -> Medication? in
                            if let id = dict["medicationId"] as? Int,
                               let name = dict["medicationName"] as? String,
                               let timeOfDay = dict["timeOfDay"] as? String {
                                return Medication(medicationId: id, medicationName: name, timeOfDay: timeOfDay)
                            }
                            return nil
                        }
                        self.MedicationTable.reloadData()
                    }
                case .failure(let error):
                    print("Failed to fetch all medications: \(error)")
                }
            }
        }

        // MARK: - TableView DataSource and Delegate
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return (tableView == DailyMedicationTable) ? dailyMedications.count : allMedications.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if tableView == DailyMedicationTable {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DailyMedicationCell", for: indexPath)
                let medication = dailyMedications[indexPath.row]
                
                let nameLabel = UILabel()
                nameLabel.text = medication.medicationName
                nameLabel.font = UIFont.systemFont(ofSize: 16)
                nameLabel.translatesAutoresizingMaskIntoConstraints = false
                
                let timeLabel = UILabel()
                timeLabel.text = medication.timeOfDay
                timeLabel.font = UIFont.systemFont(ofSize: 16)
                timeLabel.translatesAutoresizingMaskIntoConstraints = false

                let takenButton = UIButton(type: .system)
                takenButton.setTitle("Taken", for: .normal)
                takenButton.tag = indexPath.row
                takenButton.addTarget(self, action: #selector(markAsTaken(_:)), for: .touchUpInside)

                let skippedButton = UIButton(type: .system)
                skippedButton.setTitle("Skipped", for: .normal)
                skippedButton.tag = indexPath.row
                skippedButton.addTarget(self, action: #selector(markAsSkipped(_:)), for: .touchUpInside)

                let buttonStack = UIStackView(arrangedSubviews: [takenButton, skippedButton])
                buttonStack.axis = .horizontal
                buttonStack.spacing = 10
                buttonStack.translatesAutoresizingMaskIntoConstraints = false

                for view in cell.contentView.subviews {
                    view.removeFromSuperview()
                }

                cell.contentView.addSubview(nameLabel)
                cell.contentView.addSubview(timeLabel)
                cell.contentView.addSubview(buttonStack)

                NSLayoutConstraint.activate([
                    nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
                    nameLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

                    timeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
                    timeLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

                    buttonStack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
                    buttonStack.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    buttonStack.heightAnchor.constraint(equalToConstant: 30),
                    cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
                ])

                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MedicationCell", for: indexPath)
                let medication = allMedications[indexPath.row]
                
                let nameLabel = UILabel()
                nameLabel.text = medication.medicationName
                nameLabel.font = UIFont.systemFont(ofSize: 16)
                nameLabel.translatesAutoresizingMaskIntoConstraints = false
                
                let timeLabel = UILabel()
                timeLabel.text = medication.timeOfDay
                timeLabel.font = UIFont.systemFont(ofSize: 16)
                timeLabel.translatesAutoresizingMaskIntoConstraints = false

                for view in cell.contentView.subviews {
                    view.removeFromSuperview()
                }

                cell.contentView.addSubview(nameLabel)
                cell.contentView.addSubview(timeLabel)
                
                let deleteButton = UIButton(type: .system)
                deleteButton.setTitle("Delete", for: .normal)
                deleteButton.tag = indexPath.row
                deleteButton.addTarget(self, action: #selector(deleteMedication(_:)), for: .touchUpInside)

                cell.contentView.addSubview(deleteButton)
                deleteButton.translatesAutoresizingMaskIntoConstraints = false
                timeLabel.translatesAutoresizingMaskIntoConstraints = false
                nameLabel.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
                    nameLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

                    timeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
                    timeLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    
                    deleteButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
                    deleteButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    deleteButton.heightAnchor.constraint(equalToConstant: 30),
                    deleteButton.widthAnchor.constraint(equalToConstant: 80)
                ])

                return cell
            }
        }

        @objc private func markAsTaken(_ sender: UIButton) {
            let index = sender.tag
            let medication = dailyMedications[index]

            let alert = UIAlertController(title: "Confirm Action", message: "Are you sure you want to mark \(medication.medicationName) as taken?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                let medicationId = medication.medicationId
                DataManager.shared.markMedicationAsTaken(medicationId: medicationId, taken: true) { result in
                    switch result {
                    case .success(_):
                        print("Medication marked as taken.")
                        DispatchQueue.main.async {
                            self.fetchDailyMedications()
                        }
                    case .failure(let error):
                        print("Failed to mark medication as taken: \(error)")
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }

        @objc private func markAsSkipped(_ sender: UIButton) {
            let index = sender.tag
            let medication = dailyMedications[index]

            let alert = UIAlertController(title: "Confirm Action", message: "Are you sure you want to mark \(medication.medicationName) as skipped?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                let medicationId = medication.medicationId
                DataManager.shared.markMedicationAsTaken(medicationId: medicationId, taken: false) { result in
                    switch result {
                    case .success(_):
                        print("Medication marked as skipped.")
                        DispatchQueue.main.async {
                            self.fetchDailyMedications()
                        }
                    case .failure(let error):
                        print("Failed to mark medication as skipped: \(error)")
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }

        @objc private func deleteMedication(_ sender: UIButton) {
            let indexPathRow = sender.tag
            let medication = allMedications[indexPathRow]

            let alert = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete \(medication.medicationName)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                DataManager.shared.deleteMedication(medicationId: medication.medicationId) { result in
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async {
                            self.allMedications.remove(at: indexPathRow)
                            self.MedicationTable.reloadData()
                            self.fetchAllMedications()
                        }
                    case .failure(let error):
                        print("Failed to delete medication: \(error)")
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
}

