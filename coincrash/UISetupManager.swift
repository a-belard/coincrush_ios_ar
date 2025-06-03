//
//  UISetupManager.swift
//  coincrash
//
//

import UIKit
import ARKit

class UISetupManager {
    
    weak var viewController: ViewController?
    
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    
    func setupARView() -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.delegate = viewController
        sceneView.automaticallyUpdatesLighting = true
        
        // Enhanced lighting for better GLB model visibility
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        return sceneView
    }
    
    
    func setupButtons(in view: UIView) -> (placeButton: UIButton, modeButton: UIButton, savedCoinsButton: UIButton, catchButton: UIButton) {
        let placeButton = UIButton(type: .system)
        placeButton.setTitle("Place Object", for: .normal)
        placeButton.backgroundColor = .systemBlue
        placeButton.tintColor = .white
        placeButton.layer.cornerRadius = 8
        placeButton.addTarget(viewController, action: #selector(ViewController.placeObjectTapped), for: .touchUpInside)
        view.addSubview(placeButton)
        
        let modeButton = UIButton(type: .system)
        modeButton.setTitle("Indoor Mode", for: .normal)
        modeButton.backgroundColor = .systemGreen
        modeButton.tintColor = .white
        modeButton.layer.cornerRadius = 8
        modeButton.addTarget(viewController, action: #selector(ViewController.toggleMode), for: .touchUpInside)
        view.addSubview(modeButton)
        
        let savedCoinsButton = UIButton(type: .system)
        savedCoinsButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        savedCoinsButton.backgroundColor = .systemOrange
        savedCoinsButton.tintColor = .white
        savedCoinsButton.layer.cornerRadius = 25
        savedCoinsButton.addTarget(viewController, action: #selector(ViewController.showSavedCoins), for: .touchUpInside)
        view.addSubview(savedCoinsButton)
        
        let catchButton = UIButton(type: .system)
        view.addSubview(catchButton)
        
        return (placeButton, modeButton, savedCoinsButton, catchButton)
    }
    
    
    func setupConstraints(
        sceneView: ARSCNView,
        placeButton: UIButton,
        modeButton: UIButton,
        savedCoinsButton: UIButton,
        catchButton: UIButton,
        in view: UIView
    ) {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        placeButton.translatesAutoresizingMaskIntoConstraints = false
        modeButton.translatesAutoresizingMaskIntoConstraints = false
        savedCoinsButton.translatesAutoresizingMaskIntoConstraints = false
        catchButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            placeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            placeButton.widthAnchor.constraint(equalToConstant: 120),
            placeButton.heightAnchor.constraint(equalToConstant: 40),
            
            modeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeButton.bottomAnchor.constraint(equalTo: placeButton.topAnchor, constant: -10),
            modeButton.widthAnchor.constraint(equalToConstant: 120),
            modeButton.heightAnchor.constraint(equalToConstant: 40),
            
            savedCoinsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            savedCoinsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            savedCoinsButton.widthAnchor.constraint(equalToConstant: 50),
            savedCoinsButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Position catch button in center of screen (hidden by default)
            catchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            catchButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            catchButton.widthAnchor.constraint(equalToConstant: 150),
            catchButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    
    func setupOverlayUI(in view: UIView) {
        let topBar = UIView()
        topBar.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)
        
        let avatar = UIView()
        avatar.backgroundColor = .lightGray
        avatar.layer.cornerRadius = 16
        avatar.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(avatar)
        
        let nameLabel = UILabel()
        nameLabel.text = "Shishir K."
        nameLabel.textColor = .white
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(nameLabel)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(cancelButton)
        cancelButton.addTarget(viewController, action: #selector(ViewController.cancelTapped), for: .touchUpInside)
        
        // Center Hand+Phone Image (placeholder)
        let handPhone = UIImageView()
        handPhone.translatesAutoresizingMaskIntoConstraints = false
        handPhone.contentMode = .scaleAspectFit
        handPhone.image = UIImage(systemName: "hand.raised")
        handPhone.tintColor = UIColor(white: 1, alpha: 0.7)
        view.addSubview(handPhone)
        
        // Bottom Card
        let bottomCard = UIView()
        bottomCard.backgroundColor = .white
        bottomCard.layer.cornerRadius = 20
        bottomCard.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomCard.layer.shadowColor = UIColor.black.cgColor
        bottomCard.layer.shadowOpacity = 0.1
        bottomCard.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomCard.layer.shadowRadius = 8
        bottomCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomCard)
        
        setupBottomCard(bottomCard: bottomCard, in: view)
        setupConstraintsForOverlay(
            topBar: topBar,
            avatar: avatar,
            nameLabel: nameLabel,
            cancelButton: cancelButton,
            handPhone: handPhone,
            bottomCard: bottomCard,
            in: view
        )
    }
    
    private func setupBottomCard(bottomCard: UIView, in view: UIView) {
        // Walk in price label
        let priceLabel = UILabel()
        priceLabel.text = "Walk in $0.11"
        priceLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        priceLabel.textColor = .black
        priceLabel.backgroundColor = UIColor.yellow.withAlphaComponent(0.8)
        priceLabel.layer.cornerRadius = 10
        priceLabel.clipsToBounds = true
        priceLabel.textAlignment = .center
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(priceLabel)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Shishir's Resort"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Entertainment"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = .gray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(subtitleLabel)
        
        // Catch Now Button
        let catchNowButton = UIButton(type: .system)
        catchNowButton.setTitle("Catch Now", for: .normal)
        catchNowButton.setTitleColor(.white, for: .normal)
        catchNowButton.backgroundColor = .systemBlue
        catchNowButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        catchNowButton.layer.cornerRadius = 50 // Make it circular (100/2)
        catchNowButton.addTarget(viewController, action: #selector(ViewController.catchNearestCoin), for: .touchUpInside)
        catchNowButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(catchNowButton)
        
        NSLayoutConstraint.activate([
            // Price label
            priceLabel.topAnchor.constraint(equalTo: bottomCard.topAnchor, constant: 16),
            priceLabel.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 24),
            priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            priceLabel.heightAnchor.constraint(equalToConstant: 24),
            // Title
            titleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: priceLabel.leadingAnchor),
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            // Catch Now button
            catchNowButton.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -24),
            catchNowButton.centerYAnchor.constraint(equalTo: bottomCard.centerYAnchor),
            catchNowButton.widthAnchor.constraint(equalToConstant: 100),
            catchNowButton.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupConstraintsForOverlay(
        topBar: UIView,
        avatar: UIView,
        nameLabel: UILabel,
        cancelButton: UIButton,
        handPhone: UIImageView,
        bottomCard: UIView,
        in view: UIView
    ) {
        NSLayoutConstraint.activate([
            // Top bar
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),
            avatar.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            avatar.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),
            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            cancelButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            // Center hand+phone
            handPhone.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handPhone.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            handPhone.widthAnchor.constraint(equalToConstant: 120),
            handPhone.heightAnchor.constraint(equalToConstant: 120),
            // Bottom card
            bottomCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomCard.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
}
