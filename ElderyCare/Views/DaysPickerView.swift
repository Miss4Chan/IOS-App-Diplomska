import UIKit

class DaysPickerView: UIView {
    
    private var selectedDays: Set<Day> = [] // Store selected days (e.g., .monday, .tuesday)
    
    // Stack view to hold the day buttons
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        
        // Add day buttons to the stack view
        for day in Day.allCases {
            let button = createDayButton(for: day)
            stackView.addArrangedSubview(button)
        }
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add layout constraints for stack view
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func createDayButton(for day: Day) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(String(day.fullName.prefix(1)), for: .normal) // Display the first letter of the day
        button.backgroundColor = .green
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.tag = day.rawValue // Use the raw value (0 = Sunday, 1 = Monday, etc.) as the tag
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        guard let day = Day(rawValue: sender.tag) else { return } // Create a Day enum from the raw value (tag)
        
        if selectedDays.contains(day) {
            selectedDays.remove(day) // Deselect day
            sender.backgroundColor = .green
        } else {
            selectedDays.insert(day) // Select day
            sender.backgroundColor = .cyan
        }
    }
    
    // Function to get selected days
    func getSelectedDays() -> [Day] {
        return Array(selectedDays)
    }
}
