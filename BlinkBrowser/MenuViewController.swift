import UIKit

enum MenuAction {
    case bookmark, share, reload, findInPage, readerMode, desktopSite
    case bookmarks, history, settings, newIncognitoTab
}

protocol MenuDelegate: AnyObject {
    func menuDidSelectAction(_ action: MenuAction)
}

class MenuViewController: UIViewController {
    weak var delegate: MenuDelegate?
    var isBookmarked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
    }
    
    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        // Action grid
        let actions: [(String, String, MenuAction)] = [
            ("Share", "square.and.arrow.up", .share),
            (isBookmarked ? "Saved" : "Bookmark", isBookmarked ? "bookmark.fill" : "bookmark", .bookmark),
            ("Reload", "arrow.clockwise", .reload),
            ("Find", "doc.text.magnifyingglass", .findInPage),
            ("Reader", "doc.plaintext", .readerMode),
            ("Desktop", "desktopcomputer", .desktopSite),
        ]
        
        let gridStack = UIStackView()
        gridStack.axis = .horizontal
        gridStack.distribution = .fillEqually
        gridStack.spacing = 8
        
        for (i, action) in actions.enumerated() {
            let btn = makeGridButton(title: action.0, icon: action.1, tag: i)
            gridStack.addArrangedSubview(btn)
            if i == 2 {
                stack.addArrangedSubview(gridStack)
                let gridStack2 = UIStackView()
                gridStack2.axis = .horizontal
                gridStack2.distribution = .fillEqually
                gridStack2.spacing = 8
                for j in 3..<actions.count {
                    let a = actions[j]
                    let b = makeGridButton(title: a.0, icon: a.1, tag: j)
                    gridStack2.addArrangedSubview(b)
                }
                stack.addArrangedSubview(gridStack2)
                break
            }
        }
        
        // Navigation items
        let navItems: [(String, String, MenuAction)] = [
            ("Bookmarks", "book", .bookmarks),
            ("History", "clock", .history),
            ("Settings", "gearshape", .settings),
            ("Private Tab", "eye.slash", .newIncognitoTab),
        ]
        
        let navCard = UIView()
        navCard.backgroundColor = .secondarySystemGroupedBackground
        navCard.layer.cornerRadius = 12
        navCard.clipsToBounds = true
        
        let navStack = UIStackView()
        navStack.axis = .vertical
        navStack.translatesAutoresizingMaskIntoConstraints = false
        navCard.addSubview(navStack)
        
        for (i, item) in navItems.enumerated() {
            let row = makeNavRow(title: item.0, icon: item.1, tag: 100 + i)
            navStack.addArrangedSubview(row)
            if i < navItems.count - 1 {
                let sep = UIView()
                sep.backgroundColor = .separator
                sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                navStack.addArrangedSubview(sep)
            }
        }
        
        NSLayoutConstraint.activate([
            navStack.topAnchor.constraint(equalTo: navCard.topAnchor),
            navStack.leadingAnchor.constraint(equalTo: navCard.leadingAnchor),
            navStack.trailingAnchor.constraint(equalTo: navCard.trailingAnchor),
            navStack.bottomAnchor.constraint(equalTo: navCard.bottomAnchor),
        ])
        
        stack.addArrangedSubview(navCard)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    private func makeGridButton(title: String, icon: String, tag: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.tag = tag
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(label)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(gridTapped(_:)))
        container.addGestureRecognizer(tap)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 70),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])
        
        return container
    }
    
    private func makeNavRow(title: String, icon: String, tag: Int) -> UIView {
        let row = UIView()
        row.tag = tag
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        
        row.addSubview(iconView)
        row.addSubview(label)
        row.addSubview(chevron)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(navTapped(_:)))
        row.addGestureRecognizer(tap)
        
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 48),
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
        ])
        
        return row
    }
    
    @objc private func gridTapped(_ gesture: UITapGestureRecognizer) {
        let actions: [MenuAction] = [.share, .bookmark, .reload, .findInPage, .readerMode, .desktopSite]
        guard let tag = gesture.view?.tag, tag < actions.count else { return }
        delegate?.menuDidSelectAction(actions[tag])
    }
    
    @objc private func navTapped(_ gesture: UITapGestureRecognizer) {
        let actions: [MenuAction] = [.bookmarks, .history, .settings, .newIncognitoTab]
        guard let tag = gesture.view?.tag else { return }
        let index = tag - 100
        guard index >= 0 && index < actions.count else { return }
        delegate?.menuDidSelectAction(actions[index])
    }
}
