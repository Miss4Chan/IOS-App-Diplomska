import UIKit

protocol AddMedicationDelegate: AnyObject {
    func didAddMedication()
}

class AddMedicationController: UIViewController {

    // Create instances of the UI elements
    weak var delegate: AddMedicationDelegate?

    private let daysPickerView = DaysPickerView()
    private let medicationNameTextField = UITextField()
    
    
    private let timePicker = UIDatePicker()
    private let timeLabel = UILabel()


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           view.addGestureRecognizer(tapGesture)

        // Set a background color to system's selected background
        view.backgroundColor = UIColor.systemBackground

        // Setup the UI
        setupUI()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true) // Dismiss the keyboard
    }
    
    private func setupUI() {
        // Create a container view to hold all elements
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Configure the medication name text field
        medicationNameTextField.placeholder = "Enter medication name"
        medicationNameTextField.borderStyle = .roundedRect
        medicationNameTextField.backgroundColor = UIColor.lightGray
        medicationNameTextField.font = UIFont.systemFont(ofSize: 24)
        medicationNameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Configure the DaysPickerView for day selection
        daysPickerView.translatesAutoresizingMaskIntoConstraints = false

        // Configure time label
        timeLabel.text = "Choose Time"
        timeLabel.font = UIFont.systemFont(ofSize: 16)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure time picker
        timePicker.datePickerMode = .time
        timePicker.translatesAutoresizingMaskIntoConstraints = false

        // Configure the Save button (the green one)
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Medication", for: .normal)
        saveButton.tintColor = .white
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0) // Green background
        saveButton.layer.cornerRadius = 10
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(saveMedication), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        // Add the elements to the container view
        containerView.addSubview(medicationNameTextField)
        containerView.addSubview(daysPickerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(timePicker)
        containerView.addSubview(saveButton)

        // Set up constraints for the containerView to be centered vertically and horizontally
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Medication Name Text Field
            medicationNameTextField.topAnchor.constraint(equalTo: containerView.topAnchor),
            medicationNameTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            medicationNameTextField.widthAnchor.constraint(equalToConstant: 350),
            medicationNameTextField.heightAnchor.constraint(equalToConstant: 40),

            // Days Picker View
            daysPickerView.topAnchor.constraint(equalTo: medicationNameTextField.bottomAnchor, constant: 20),
            daysPickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            daysPickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            daysPickerView.heightAnchor.constraint(equalToConstant: 50),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: daysPickerView.bottomAnchor, constant: 20),
            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor), // Center the label horizontally

            // Time picker directly below the time label, matching width and height
            timePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10), // 10 points below the timeLabel
            timePicker.widthAnchor.constraint(equalTo: saveButton.widthAnchor), // Match width of the timeLabel
            timePicker.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor, constant: -40),



            // Save Button
            saveButton.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20), // Adjusted to be below the time picker
            saveButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor), // Center the button horizontally
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 44),

            // Bottom anchor of the containerView (Optional, based on layout)
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }


    
    @objc private func saveMedication() {
        // Get the medication name and selected days
        let medicationName = medicationNameTextField.text ?? ""
        let selectedDays = daysPickerView.getSelectedDays()

        // Ensure that both fields are filled with proper feedback
        guard !medicationName.isEmpty else {
            showAlert(message: "Medication name is required")
            return
        }

        guard !selectedDays.isEmpty else {
            showAlert(message: "At least one day must be selected")
            return
        }

        // Convert selected days to repeating pattern (array of 7 values: 0 or 1)
        let repeatingPattern = convertDaysToRepeatingPattern(selectedDays)
        
        let timeFormatter = DateFormatter()
              timeFormatter.dateFormat = "HH:mm"
              let selectedTime = timeFormatter.string(from: timePicker.date)

        // Call DataManager to save medication
        DataManager.shared.createMedication(name: medicationName, repeatingPattern: repeatingPattern,timeOfDay: selectedTime) { result in
            switch result {
            case .success(_):
                // Notify the delegate (MedicationController) that a medication has been added
                self.delegate?.didAddMedication()

                // Return to the MedicationController after successfully saving the medication
                DispatchQueue.main.async {
                               self.dismiss(animated: true, completion: nil) // Dismiss the view controller
                           }

            case .failure(let error):
                // Handle failure (e.g., show error message)
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
