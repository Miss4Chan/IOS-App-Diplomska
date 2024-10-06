import UIKit

class DaysPickerView: UIView {
    
    private var selectedDays: Set<Day> = []
    
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
        
        for day in Day.allCases {
            let button = createDayButton(for: day)
            stackView.addArrangedSubview(button)
        }
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
    }
    
    private func createDayButton(for day: Day) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(String(day.fullName.prefix(1)), for: .normal)
        
        button.backgroundColor = UIColor(red: 0.57, green: 0.74, blue: 0.68, alpha: 1.0)
        button.setTitleColor(.black, for: .normal)
        
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.layer.shadowColor = UIColor.lightGreen.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 5
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        button.tag = day.rawValue
        button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        guard let day = Day(rawValue: sender.tag) else { return }
        
        if selectedDays.contains(day) {
            selectedDays.remove(day)
            sender.backgroundColor = UIColor(red: 0.57, green: 0.74, blue: 0.68, alpha: 1.0)
            sender.setTitleColor(.black, for: .normal)
            sender.layer.shadowColor = UIColor.lightGreen.cgColor
        } else {
            selectedDays.insert(day)
            sender.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
            sender.setTitleColor(.white, for: .normal)
            sender.layer.shadowColor = UIColor.darkGreen.cgColor
        }
    }

    func getSelectedDays() -> [Day] {
        return Array(selectedDays)
    }
}

extension UIColor {
    static let lightGreen = UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 1.0)
    static let darkGreen = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
}

