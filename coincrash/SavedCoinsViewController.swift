import UIKit
import ARKit

class SavedCoinsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var coinPositions: [UUID: simd_float3] = [:]
    private let worldMapManager = WorldMapManager()
    
    // Add delegate to communicate with AR view
    weak var arViewController: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedCoins()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation setup
        title = "Saved Coins"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Back to AR",
            style: .done,
            target: self,
            action: #selector(backToAR)
        )
        
        // Table view setup
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SavedCoinCell.self, forCellReuseIdentifier: "SavedCoinCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add empty state view
        setupEmptyStateView()
    }
    
    private func setupEmptyStateView() {
        let emptyView = UIView()
        
        // Create a custom "C" label instead of bitcoin icon
        let coinLabel = UILabel()
        coinLabel.text = "C"
        coinLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        coinLabel.textColor = .systemGray3
        coinLabel.textAlignment = .center
        coinLabel.backgroundColor = UIColor.systemGray5
        coinLabel.layer.cornerRadius = 30
        coinLabel.clipsToBounds = true
        
        let label = UILabel()
        label.text = "No saved coins"
        label.textColor = .systemGray2
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Place coins in AR view to see them here"
        subtitleLabel.textColor = .systemGray3
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textAlignment = .center
        
        [emptyView, coinLabel, label, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        emptyView.addSubview(coinLabel)
        emptyView.addSubview(label)
        emptyView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            coinLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            coinLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -40),
            coinLabel.widthAnchor.constraint(equalToConstant: 60),
            coinLabel.heightAnchor.constraint(equalToConstant: 60),
            
            label.topAnchor.constraint(equalTo: coinLabel.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -20)
        ])
        
        tableView.backgroundView = emptyView
    }
    
    private func loadSavedCoins() {
        let (_, positions) = worldMapManager.loadWorldMapAndPositions()
        coinPositions = positions ?? [:]
        
        tableView.backgroundView?.isHidden = !coinPositions.isEmpty
        tableView.reloadData()
    }
    
    @objc private func backToAR() {
        dismiss(animated: true)
    }
    
    private func deleteCoin(at indexPath: IndexPath) {
        let coinKeys = Array(coinPositions.keys)
        let coinToDelete = coinKeys[indexPath.row]
        
        // Remove from AR environment first
        arViewController?.removeCoinFromScene(with: coinToDelete)
        
        // Remove GPS location data
        worldMapManager.removeGPSLocation(for: coinToDelete)
        
        // Remove from local dictionary
        coinPositions.removeValue(forKey: coinToDelete)
        
        // Save updated data
        saveCoinPositions()
        
        // Update UI
        tableView.deleteRows(at: [indexPath], with: .fade)
        tableView.backgroundView?.isHidden = !coinPositions.isEmpty
    }
    
    private func saveCoinPositions() {
        // Load current world map and save with updated coin positions
        let (worldMap, _) = worldMapManager.loadWorldMapAndPositions()
        if let map = worldMap {
            worldMapManager.saveWorldMapAndPositions(map, coinPositions: coinPositions)
        }
    }
    
    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Coin Deleted",
            message: "The coin has been removed from your saved collection.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SavedCoinsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coinPositions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCoinCell", for: indexPath) as! SavedCoinCell
        
        let coinKeys = Array(coinPositions.keys)
        let coinID = coinKeys[indexPath.row]
        let position = coinPositions[coinID]!
        
        cell.configure(with: coinID, position: position, index: indexPath.row + 1)
        return cell
    }
}

extension SavedCoinsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteCoin(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
}

class SavedCoinCell: UITableViewCell {
    
    private let coinLabel = UILabel()
    private let titleLabel = UILabel()
    private let positionLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        // Coin label with "C"
        coinLabel.text = "C"
        coinLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        coinLabel.textColor = .white
        coinLabel.backgroundColor = UIColor(red: 0.15, green: 0.35, blue: 0.8, alpha: 1.0)
        coinLabel.textAlignment = .center
        coinLabel.layer.cornerRadius = 20
        coinLabel.clipsToBounds = true
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        // Position label
        positionLabel.font = UIFont.systemFont(ofSize: 14)
        positionLabel.textColor = .secondaryLabel
        positionLabel.numberOfLines = 1
        
        // Date label
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .tertiaryLabel
        
        [coinLabel, titleLabel, positionLabel, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            coinLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coinLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coinLabel.widthAnchor.constraint(equalToConstant: 40),
            coinLabel.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: coinLabel.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            positionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            positionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            positionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: positionLabel.bottomAnchor, constant: 2),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with coinID: UUID, position: simd_float3, index: Int) {
        titleLabel.text = "Coin #\(index)"
        positionLabel.text = String(format: "Position: (%.2f, %.2f, %.2f)", position.x, position.y, position.z)
        
        // Show GPS coordinates if available
        let worldMapManager = WorldMapManager()
        if let gpsLocation = worldMapManager.getGPSLocation(for: coinID) {
            let lat = gpsLocation.coordinate.latitude
            let lon = gpsLocation.coordinate.longitude
            dateLabel.text = String(format: "GPS: %.6f, %.6f", lat, lon)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateLabel.text = "Saved: \(dateFormatter.string(from: Date()))"
        }
    }
}
