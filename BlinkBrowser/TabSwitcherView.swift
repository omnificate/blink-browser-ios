import UIKit

protocol TabSwitcherDelegate: AnyObject {
    func tabSwitcherDidSelectTab(at index: Int)
    func tabSwitcherDidCloseTab(at index: Int)
    func tabSwitcherDidRequestNewTab()
}

class TabSwitcherViewController: UIViewController {
    weak var delegate: TabSwitcherDelegate?
    private let tabManager: TabManager
    private var collectionView: UICollectionView!
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        // Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneBtn.addTarget(self, action: #selector(tapDone), for: .touchUpInside)
        
        let titleLabel = UILabel()
        titleLabel.text = "\(tabManager.tabs.count) Tabs"
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textAlignment = .center
        
        let addBtn = UIButton(type: .system)
        addBtn.setImage(UIImage(systemName: "plus"), for: .normal)
        addBtn.addTarget(self, action: #selector(tapAdd), for: .touchUpInside)
        
        headerStack.addArrangedSubview(doneBtn)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(addBtn)
        
        // Collection view
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.bounds.width - 48) / 2, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: "TabCell")
        
        view.addSubview(headerStack)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    @objc private func tapDone() { dismiss(animated: true) }
    @objc private func tapAdd() { delegate?.tabSwitcherDidRequestNewTab() }
}

extension TabSwitcherViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tabManager.tabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath) as! TabCell
        let tab = tabManager.tabs[indexPath.item]
        let isActive = indexPath.item == tabManager.activeIndex
        cell.configure(tab: tab, isActive: isActive)
        cell.onClose = { [weak self] in
            self?.delegate?.tabSwitcherDidCloseTab(at: indexPath.item)
            self?.collectionView.reloadData()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.tabSwitcherDidSelectTab(at: indexPath.item)
    }
}

class TabCell: UICollectionViewCell {
    var onClose: (() -> Void)?
    private let titleLabel = UILabel()
    private let domainLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let iconView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 14
        contentView.clipsToBounds = true
        
        // Header
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)
        
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
        header.addSubview(closeButton)
        
        // Body
        iconView.image = UIImage(systemName: "globe")
        iconView.tintColor = .tertiaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        
        domainLabel.font = .systemFont(ofSize: 11, weight: .medium)
        domainLabel.textColor = .secondaryLabel
        domainLabel.textAlignment = .center
        domainLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(domainLabel)
        
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 36),
            
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            
            closeButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -6),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 6),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            domainLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            domainLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            domainLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(tab: WebViewTab, isActive: Bool) {
        titleLabel.text = tab.title
        domainLabel.text = tab.url?.host?.replacingOccurrences(of: "www.", with: "") ?? "New Tab"
        contentView.layer.borderWidth = isActive ? 2.5 : 0
        contentView.layer.borderColor = UIColor.systemBlue.cgColor
        iconView.image = UIImage(systemName: tab.isIncognito ? "eye.slash" : "globe")
    }
    
    @objc private func tapClose() { onClose?() }
}
