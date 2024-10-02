import UIKit

protocol AddMedicationDelegate: AnyObject {
    func didAddMedication()
}

class AddMedicationController: UIViewController {

    // Create instances of the UI elements
    weak var delegate: AddMedicationDelegate?

    private let daysPickerView = DaysPickerView()
    private let medicationNameTextField = UITextField()


    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set a background color to system's selected background
        view.backgroundColor = UIColor.systemBackground

        // Setup the UI
        setupUI()
    }

    private func setupUI() {
        // Configure the medication name text field
        medicationNameTextField.placeholder = "Enter medication name"
        medicationNameTextField.borderStyle = .roundedRect
        medicationNameTextField.backgroundColor = UIColor.lightGray // Set background to gray
        medicationNameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Configure the DaysPickerView for day selection
        daysPickerView.translatesAutoresizingMaskIntoConstraints = false

        // Configure the Save button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Medication", for: .normal)
        saveButton.tintColor = .systemBlue // Set tint color to system blue
        saveButton.setTitleColor(.systemBlue, for: .normal) // Set title text color to system blue
        saveButton.backgroundColor = .clear // Ensure background is clear
        saveButton.addTarget(self, action: #selector(saveMedication), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        // Add the views to the main view
        view.addSubview(medicationNameTextField)
        view.addSubview(daysPickerView)
        view.addSubview(saveButton)

        // Set up constraints for layout
        NSLayoutConstraint.activate([
            // Medication Name Text Field
            medicationNameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            medicationNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            medicationNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            medicationNameTextField.heightAnchor.constraint(equalToConstant: 40),

            // Days Picker View
            daysPickerView.topAnchor.constraint(equalTo: medicationNameTextField.bottomAnchor, constant: 20),
            daysPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            daysPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            daysPickerView.heightAnchor.constraint(equalToConstant: 50),

            // Save Button
            saveButton.topAnchor.constraint(equalTo: daysPickerView.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    @objc private func saveMedication() {
           // Get the medication name and selected days
           let medicationName = medicationNameTextField.text ?? ""
           let selectedDays = daysPickerView.getSelectedDays()

           // Ensure that both fields are filled
           guard !medicationName.isEmpty else {
               print("Medication name is required")
               return
           }
           
           guard !selectedDays.isEmpty else {
               print("At least one day must be selected")
               return
           }

           // Convert selected days to repeating pattern (array of 7 values: 0 or 1)
           let repeatingPattern = convertDaysToRepeatingPattern(selectedDays)

           // Call DataManager to save medication
           DataManager.shared.createMedication(name: medicationName, repeatingPattern: repeatingPattern) { result in
               switch result {
               case .success(_):
                   // Notify the delegate (MedicationController) that a medication has been added
                   self.delegate?.didAddMedication()

                   // Return to the MedicationController after successfully saving the medication
                   DispatchQueue.main.async {
                       self.navigationController?.popViewController(animated: true)
                   }

               case .failure(let error):
                   // Handle failure (e.g., show error message)
                   print("Failed to save medication: \(error)")
               }
           }
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
