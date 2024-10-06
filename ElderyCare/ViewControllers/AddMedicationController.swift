import UIKit

protocol AddMedicationDelegate: AnyObject {
    func didAddMedication()
}

class AddMedicationController: UIViewController {

    weak var delegate: AddMedicationDelegate?

    private let daysPickerView = DaysPickerView()
    private let medicationNameTextField = UITextField()
    
    
    private let timePicker = UIDatePicker()
    private let timeLabel = UILabel()


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           view.addGestureRecognizer(tapGesture)

        view.backgroundColor = UIColor.systemBackground

        setupUI()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        medicationNameTextField.placeholder = "Enter medication name"
        medicationNameTextField.borderStyle = .roundedRect
        medicationNameTextField.backgroundColor = UIColor.lightGray
        medicationNameTextField.font = UIFont.systemFont(ofSize: 24)
        medicationNameTextField.translatesAutoresizingMaskIntoConstraints = false

        daysPickerView.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.text = "Choose Time"
        timeLabel.font = UIFont.systemFont(ofSize: 16)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        timePicker.datePickerMode = .time
        timePicker.translatesAutoresizingMaskIntoConstraints = false

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Medication", for: .normal)
        saveButton.tintColor = .white
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        saveButton.layer.cornerRadius = 10
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(saveMedication), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(medicationNameTextField)
        containerView.addSubview(daysPickerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(timePicker)
        containerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            medicationNameTextField.topAnchor.constraint(equalTo: containerView.topAnchor),
            medicationNameTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            medicationNameTextField.widthAnchor.constraint(equalToConstant: 350),
            medicationNameTextField.heightAnchor.constraint(equalToConstant: 40),

            daysPickerView.topAnchor.constraint(equalTo: medicationNameTextField.bottomAnchor, constant: 20),
            daysPickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            daysPickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            daysPickerView.heightAnchor.constraint(equalToConstant: 50),

            
            timeLabel.topAnchor.constraint(equalTo: daysPickerView.bottomAnchor, constant: 20),
            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            timePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            timePicker.widthAnchor.constraint(equalTo: saveButton.widthAnchor),
            timePicker.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor, constant: -40),



            saveButton.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 44),

            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }


    
    @objc private func saveMedication() {
        let medicationName = medicationNameTextField.text ?? ""
        let selectedDays = daysPickerView.getSelectedDays()

        guard !medicationName.isEmpty else {
            showAlert(message: "Medication name is required")
            return
        }

        guard !selectedDays.isEmpty else {
            showAlert(message: "At least one day must be selected")
            return
        }

        let repeatingPattern = convertDaysToRepeatingPattern(selectedDays)
        
        let timeFormatter = DateFormatter()
              timeFormatter.dateFormat = "HH:mm"
              let selectedTime = timeFormatter.string(from: timePicker.date)


        DataManager.shared.createMedication(name: medicationName, repeatingPattern: repeatingPattern,timeOfDay: selectedTime) { result in
            switch result {
            case .success(_):
                self.delegate?.didAddMedication()


                DispatchQueue.main.async {
                               self.dismiss(animated: true, completion: nil)
                           }

            case .failure(let error):
                self.showAlert(message: "Failed to save medication: \(error.localizedDescription)")
            }
        }
    }
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }


       private func convertDaysToRepeatingPattern(_ selectedDays: [Day]) -> [Int] {
           var pattern = [0, 0, 0, 0, 0, 0, 0]
           for day in selectedDays {
               let dayIndex = day.rawValue
               pattern[dayIndex] = 1
           }
           return pattern
       }
}
