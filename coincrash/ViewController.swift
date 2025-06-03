//
//  ViewController.swift
//  coincrash
//
//

import UIKit
import Metal
import MetalKit
import ARKit
import CoreLocation
import SceneKit
import GLTFSceneKit

extension MTKView : RenderDestinationProvider {
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var sceneView: ARSCNView!
    
    let worldMapManager = WorldMapManager()
    lazy var arSessionManager = ARSessionManager(sceneView: sceneView, delegate: self)
    let locationManager = LocationManager()
    lazy var coinPlacementManager = CoinPlacementManager(sceneView: sceneView, delegate: self)
    lazy var uiSetupManager = UISetupManager(viewController: self)
    
    var placeButton: UIButton!
    var modeButton: UIButton!
    var savedCoinsButton: UIButton!
    var catchButton: UIButton!
    var touchedNodes: [SCNNode] = []
    private var currentMode: ARObjectType = .indoor
    
    var nearbyCoins: Set<String> = []
    var currentCoinInRange: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI first (so sceneView is available for managers)
        setupARView()
        setupButtons()
        setupConstraints()
        setupGestureRecognizers()
        setupOverlayUI()
        
        // Setup managers (after sceneView is initialized)
        setupManagers()
        
        // Load saved data BEFORE starting AR session
        loadSavedData()
        
        // Start AR session
        startARSession()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene with ambient lighting
        setupScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure proximity checking is active when view appears
        coinPlacementManager.ensureProximityCheckingIsActive()
        print("DEBUG: View appeared, ensuring proximity checking is active")
    }
    
    private func setupManagers() {
        // Set up location manager
        locationManager.delegate = self
        locationManager.requestLocationPermission()
        
        // Set current mode for managers
        arSessionManager.setCurrentMode(currentMode)
        coinPlacementManager.setCurrentMode(currentMode)
    }
    
    private func setupScene() {
        // Create a new scene
        let scene = SCNScene()
        
        // Add ambient lighting to ensure GLB models are properly lit
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        ambientLightNode.light!.intensity = 300 // Increased intensity for better GLB visibility
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        sceneView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
        coinPlacementManager.handleTap(at: location)
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        arSessionManager.getCurrentWorldMap { worldMap, error in
            guard let worldMap = worldMap else {
                self.showAlert(title: "Error", message: "Could not get current world map: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.worldMapManager.saveWorldMapAndPositions(worldMap, coinPositions: self.coinPlacementManager.coinPositions)
            self.showAlert(title: "Success", message: "World map and coin positions saved!")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func setupARView() {
        sceneView = uiSetupManager.setupARView()
        view.addSubview(sceneView)
    }
    
    func setupButtons() {
        let buttons = uiSetupManager.setupButtons(in: view)
        placeButton = buttons.placeButton
        modeButton = buttons.modeButton
        savedCoinsButton = buttons.savedCoinsButton
        catchButton = buttons.catchButton
    }
    
    func setupConstraints() {
        uiSetupManager.setupConstraints(
            sceneView: sceneView,
            placeButton: placeButton,
            modeButton: modeButton,
            savedCoinsButton: savedCoinsButton,
            catchButton: catchButton,
            in: view
        )
    }
    
    func startARSession() {
        arSessionManager.startARSession()
        updateModeUI()
    }
    
    @objc func toggleMode() {
        currentMode = currentMode == .indoor ? .outdoor : .indoor
        modeButton.setTitle(currentMode == .indoor ? "Indoor Mode" : "Outdoor Mode", for: .normal)
        modeButton.backgroundColor = currentMode == .indoor ? .systemGreen : .systemOrange
        
        // Update managers with new mode
        arSessionManager.setCurrentMode(currentMode)
        coinPlacementManager.setCurrentMode(currentMode)
        
        // Show mode change feedback
        showModeChangeAlert()
        
        // Restart AR session with new configuration
        startARSession()
    }
    
    @objc func placeObjectTapped() {
        // This will be handled by the tap gesture recognizer
    }
    
    @objc func showSavedCoins() {
        let savedCoinsVC = SavedCoinsViewController()
        savedCoinsVC.arViewController = self // Pass reference to AR controller
        let navController = UINavigationController(rootViewController: savedCoinsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    @objc func catchCoinTapped() {
        print("DEBUG: catchCoinTapped called")
        // Use the current coin in range
        guard let coinID = currentCoinInRange else {
            print("DEBUG: No current coin in range")
            showAlert(title: "Error", message: "No coin found to catch!")
            return
        }
        
        print("DEBUG: Attempting to catch coin: \(coinID)")
        // Catch the coin using the placement manager
        coinPlacementManager.catchCoin(withID: coinID)
    }
    
    @objc func catchNearestCoin() {
        print("DEBUG: catchNearestCoin called")
        // Find the nearest coin to catch
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            showAlert(title: "Error", message: "Camera not available!")
            return
        }
        
        let cameraPosition = simd_float3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        var nearestCoin: (node: SCNNode, distance: Float, id: UUID)? = nil
        
        print("DEBUG: Checking \(coinPlacementManager.coinPositions.count) coins")
        
        // Check all coins in the scene
        for (coinID, _) in coinPlacementManager.coinPositions {
            if let coinNode = sceneView.scene.rootNode.childNode(withName: coinID.uuidString, recursively: true) {
                let coinPosition = simd_float3(coinNode.worldPosition.x, coinNode.worldPosition.y, coinNode.worldPosition.z)
                let distance = simd_length(coinPosition - cameraPosition)
                
                
                if nearestCoin == nil || distance < nearestCoin!.distance {
                    nearestCoin = (coinNode, distance, coinID)
                }
            }
        }
        
        if let nearest = nearestCoin {
            if nearest.distance <= 1.0 { // Allow catching within 2 meters for the manual button
                coinPlacementManager.catchCoin(withID: nearest.id)
            } else {
                let distanceText = String(format: "%.1f", nearest.distance)
                showAlert(title: "No nearby coins", message: ".")
            }
        } else {
            print("DEBUG: No coins found")
            showAlert(title: "No Coins", message: "No coins found in the scene!")
        }
    }
    
    // Add method to remove coin from AR scene
    func removeCoinFromScene(with coinID: UUID) {
        coinPlacementManager.removeCoinFromScene(with: coinID)
    }
    
    // MARK: - Overlay UI
    private func setupOverlayUI() {
        uiSetupManager.setupOverlayUI(in: view)
    }
    
    @objc func cancelTapped() {
        // Dismiss or handle cancel
        self.dismiss(animated: true, completion: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait    }

    func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "Please enable location access in Settings to save GPS coordinates with your coins.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateModeUI() {
        // Update button appearance based on mode
        modeButton.backgroundColor = currentMode == .indoor ? .systemGreen : .systemOrange
        
        // You could also update other UI elements here
        // For example, change instruction text or icons
    }
    
    private func showModeChangeAlert() {
        let message = currentMode == .indoor ? 
            "Indoor mode: Better for rooms and indoor spaces. Uses plane detection." :
            "Outdoor mode: Better for open areas. Uses world-scale tracking."
        
        let alert = UIAlertController(title: "Mode Changed", message: message, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    func showPlacementFeedback() {
        let message = currentMode == .indoor ? 
            "Point at a flat surface (table, floor, wall)" :
            "Point at the ground or move around to find a stable surface"
        
        let alert = UIAlertController(title: "Surface Not Found", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
