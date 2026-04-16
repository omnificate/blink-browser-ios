import UIKit

protocol URLBarDelegate: AnyObject {
    func urlBarDidTapBack()
    func urlBarDidTapForward()
    func urlBarDidTapReload()
    func urlBarDidSubmit(_ text: String)
    func urlBarDidTapTabs()
    func urlBarDidTapMenu()
    func urlBarTabCount() -> Int
}

class URLBarView: UIView {
    weak var delegate: URLBarDelegate?
    
    private let backButton = UIButton(type: .system)
    private let urlField = UITextField()
    private let tabsButton = UIButton(type: .system)
    private let menuButton = UIButton(type: .system)
    private let lockIcon = UIImageView()
    private let reloadButton = UIButton(type: .system)
    private var tabCountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 20
        clipsToBounds = true
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .systemBlue
        backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        backButton.isEnabled = false
        
        // Lock icon
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = .systemGreen
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.isHidden = true
        
        // URL field
        urlField.placeholder = "Search or enter URL"
        urlField.font = .systemFont(ofSize: 14, weight: .medium)
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.keyboardType = .webSearch
        urlField.returnKeyType = .go
        urlField.clearButtonMode = .whileEditing
        urlField.delegate = self
        urlField.backgroundColor = .tertiarySystemBackground
        urlField.layer.cornerRadius = 10
        urlField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        urlField.leftViewMode = .always
        
        // Reload button
        reloadButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        reloadButton.tintColor = .secondaryLabel
        reloadButton.addTarget(self, action: #selector(tapReload), for: .touchUpInside)
        reloadButton.isHidden = true
        
        // Tabs button
        tabCountLabel.text = "1"
        tabCountLabel.font = .systemFont(ofSize: 11, weight: .heavy)
        tabCountLabel.textAlignment = .center
        tabCountLabel.layer.borderWidth = 1.5
        tabCountLabel.layer.borderColor = UIColor.label.cgColor
        tabCountLabel.layer.cornerRadius = 5
        tabCountLabel.clipsToBounds = true
        tabsButton.addSubview(tabCountLabel)
        tabsButton.addTarget(self, action: #selector(tapTabs), for: .touchUpInside)
        
        // Menu button
        menuButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        menuButton.tintColor = .label
        menuButton.addTarget(self, action: #selector(tapMenu), for: .touchUpInside)
        
        // Layout
        let stack = UIStackView(arrangedSubviews: [backButton, urlField, tabsButton, menuButton])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            
            backButton.widthAnchor.constraint(equalToConstant: 36),
            tabsButton.widthAnchor.constraint(equalToConstant: 36),
            menuButton.widthAnchor.constraint(equalToConstant: 36),
            urlField.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        tabCountLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabCountLabel.centerXAnchor.constraint(equalTo: tabsButton.centerXAnchor),
            tabCountLabel.centerYAnchor.constraint(equalTo: tabsButton.centerYAnchor),
            tabCountLabel.widthAnchor.constraint(equalToConstant: 22),
            tabCountLabel.heightAnchor.constraint(equalToConstant: 22),
        ])
    }
    
    // MARK: - Public
    func updateURL(_ url: URL?) {
        guard let url = url else {
            urlField.text = ""
            lockIcon.isHidden = true
            reloadButton.isHidden = true
            return
        }
        urlField.text = url.host?.replacingOccurrences(of: "www.", with: "")
        lockIcon.isHidden = url.scheme != "https"
        lockIcon.tintColor = url.scheme == "https" ? .systemGreen : .systemOrange
        reloadButton.isHidden = false
    }
    
    func updateTitle(_ title: String) {
        // Could show title in compact mode
    }
    
    func updateNavState(canGoBack: Bool, canGoForward: Bool) {
        backButton.isEnabled = canGoBack
    }
    
    func updateTabCount(_ count: Int) {
        tabCountLabel.text = count > 99 ? ":D" : "\(count)"
    }
    
    // MARK: - Actions
    @objc private func tapBack() { delegate?.urlBarDidTapBack() }
    @objc private func tapReload() { delegate?.urlBarDidTapReload() }
    @objc private func tapTabs() { delegate?.urlBarDidTapTabs() }
    @objc private func tapMenu() { delegate?.urlBarDidTapMenu() }
}

extension URLBarView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else { return false }
        delegate?.urlBarDidSubmit(text)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Show full URL when editing
        textField.selectAll(nil)
    }
}
