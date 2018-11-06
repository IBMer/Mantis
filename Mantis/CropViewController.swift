//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public protocol CropViewControllerProtocal {
    func didGetCroppedImage(image: UIImage)
}

public enum CropViewControllerMode {
    case embedded
    case normal
}

public class CropViewController: UIViewController {
    
    var delegate: CropViewControllerProtocal?
    
    var orientation: UIInterfaceOrientation = .unknown
    
    var cancelButton: UIButton?
    var setRatioButton: UIButton?
    var resetButton: UIButton?
    var anticlockRotateButton: UIButton?
    var cropButton: UIButton?
    
    var optionButtonStackView: UIStackView?
    var optionButtons: [UIButton?] = []
    
    var ratioPresenter: RatioPresenter?

    var cropViewTopConstraint: NSLayoutConstraint?
    var cropViewLandscapeBottomConstraint: NSLayoutConstraint?
    var cropViewPortraitBottomConstraint: NSLayoutConstraint?
    var cropViewLandscapeLeftLeftConstraint: NSLayoutConstraint?
    var cropViewLandscapeRightLeftConstraint: NSLayoutConstraint?
    var cropViewPortraitLeftConstraint: NSLayoutConstraint?
    var cropViewLandscapeLeftRightConstraint: NSLayoutConstraint?
    var cropViewLandscapeRightRightConstraint: NSLayoutConstraint?
    var cropViewPortaitRightConstraint: NSLayoutConstraint?
    
    var toolbarWidthConstraint: NSLayoutConstraint?
    var toolbarHeightConstraint: NSLayoutConstraint?
    var toolbarTopConstraint: NSLayoutConstraint?
    var toolbarBottomConstraint: NSLayoutConstraint?
    var toolbarLeftConstraint: NSLayoutConstraint?
    var toolbarRightConstraint: NSLayoutConstraint?
    
    var uiConstraints: [NSLayoutConstraint?] = []
    
    var cropView: CropView?
    var initialLayout = false
    
    var image: UIImage? {
        didSet {
            cropView?.adaptForCropBox()
        }
    }
    
    var mode: CropViewControllerMode = .normal
    
    init(image: UIImage) {
        self.image = image
        orientation = UIApplication.shared.statusBarOrientation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func initLayout() {
        initToolarAutoLayout()
        initCropViewAutoLayout()
        updateLayout()
        
        uiConstraints = [cropViewTopConstraint, cropViewLandscapeBottomConstraint, cropViewPortraitBottomConstraint, cropViewLandscapeLeftLeftConstraint, cropViewLandscapeRightLeftConstraint, cropViewPortraitLeftConstraint, cropViewLandscapeLeftRightConstraint, cropViewLandscapeRightRightConstraint, cropViewPortaitRightConstraint, toolbarWidthConstraint, toolbarHeightConstraint, toolbarTopConstraint, toolbarBottomConstraint, toolbarLeftConstraint, toolbarRightConstraint]
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
        
        if mode == .normal {
            createToolbarUI()
        } else {
            createBottomOpertions()
        }
        
        createCropView()
        initLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            cropView?.adaptForCropBox()
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cropView?.prepareForDeviceRotation()
    }    
    
    @objc func rotated() {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        
        guard statusBarOrientation != .unknown else {
            return
        }
        
        guard statusBarOrientation != orientation else {
            return
        }
        
        orientation = statusBarOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && statusBarOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        cropView?.handleRotate()
    }
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonRect = CGRect(x: 0, y: 0, width: 80, height: 30)
        let buttonColor = UIColor.white
        let buttonFont = UIFont.systemFont(ofSize: 20)

        let button = UIButton(frame: buttonRect)
        button.titleLabel?.font = buttonFont
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        return button
    }
    
    private func createFlexibleSpace() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    }
    
    private func createToolbarUI() {
        cancelButton = createOptionButton(withTitle: "Cancel", andAction: #selector(cancel))
        
        anticlockRotateButton = createOptionButton(withTitle: nil, andAction: #selector(rotate))
        anticlockRotateButton?.setImage(ToolBarButtonImageBuilder.rotateCCWImage(), for: .normal)
        
        resetButton = createOptionButton(withTitle: "Reset", andAction: #selector(reset))
        
        setRatioButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        setRatioButton?.setImage(ToolBarButtonImageBuilder.clampImage(), for: .normal)
        
        cropButton = createOptionButton(withTitle: "Done", andAction: #selector(crop))
        
        optionButtonStackView = UIStackView()
        optionButtonStackView?.distribution = .fillEqually
        optionButtonStackView?.addArrangedSubview(cancelButton!)
        optionButtonStackView?.addArrangedSubview(anticlockRotateButton!)
        optionButtonStackView?.addArrangedSubview(resetButton!)
        optionButtonStackView?.addArrangedSubview(setRatioButton!)
        optionButtonStackView?.addArrangedSubview(cropButton!)
        
        optionButtons = [cancelButton, anticlockRotateButton, resetButton, setRatioButton, cropButton]
    }
    
    private func createBottomOpertions() {
    }
    
    private func createCropView() {
        guard let image = image else { return }
        
        cropView = CropView(image: image)
        guard let cropView = cropView else { return }
        
        cropView.delegate = self
        cropView.clipsToBounds = true
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func setRatio() {
        guard let cropView = cropView else { return }
        
        if cropView.aspectRatioLockEnabled {
            cropView.aspectRatioLockEnabled = false
            setRatioButton?.setTitleColor(.white, for: .normal)
            return
        }
        
        guard let image = image else { return }
        
        func didSet(fixedRatio ratio: Double) {
            setRatioButton?.setTitleColor(.blue, for: .normal)
            cropView.aspectRatioLockEnabled = true
            cropView.imageStatus.aspectRatio = CGFloat(ratio)
            
            UIView.animate(withDuration: 0.5) {
                cropView.setFixedRatioCropBox()
            }            
        }
        
        let type: RatioType = image.isHoritontal() ? .horizontal : .vertical
        let ratio = Double(image.ratio())
        ratioPresenter = RatioPresenter(type: type, originalRatio: ratio)
        ratioPresenter?.didGetRatio = { ratio in
            didSet(fixedRatio: ratio)
        }
        ratioPresenter?.present(by: self, in: setRatioButton!)
    }

    @objc private func reset(_ sender: Any) {
        cropView?.reset()
    }
    
    @objc private func rotate(_ sender: Any) {
        cropView?.anticlockwiseRotate90()
    }
    
    @objc private func crop(_ sender: Any) {
        guard let image = cropView?.crop() else {
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.didGetCroppedImage(image: image)
        }
    }
}

// Auto layout
extension CropViewController {
    fileprivate func initCropViewAutoLayout() {
        guard let cropView = cropView, let stackView = optionButtonStackView else { return }
        
        view.addSubview(cropView)
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        
        cropViewTopConstraint = cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        cropViewLandscapeBottomConstraint = cropView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        cropViewLandscapeLeftLeftConstraint = cropView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        cropViewLandscapeLeftRightConstraint = cropView.rightAnchor.constraint(equalTo: stackView.leftAnchor)
        
        cropViewLandscapeRightLeftConstraint = cropView.leftAnchor.constraint(equalTo: stackView.rightAnchor)
        cropViewLandscapeRightRightConstraint = cropView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        
        cropViewPortraitBottomConstraint = cropView.bottomAnchor.constraint(equalTo: stackView.topAnchor)
        cropViewPortraitLeftConstraint = cropView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        cropViewPortaitRightConstraint = cropView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    fileprivate func initToolarAutoLayout() {
        guard let stackView = optionButtonStackView else { return }
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: 80)
        toolbarHeightConstraint = stackView.heightAnchor.constraint(equalToConstant: 44)
        toolbarTopConstraint = stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        toolbarBottomConstraint = stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        toolbarLeftConstraint = stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        toolbarRightConstraint = stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    fileprivate func updateLayout() {
        uiConstraints.forEach{ $0?.isActive = false }
        
        if UIApplication.shared.statusBarOrientation.isPortrait {
            toolbarHeightConstraint?.isActive = true
            toolbarLeftConstraint?.isActive = true
            toolbarRightConstraint?.isActive = true
            toolbarBottomConstraint?.isActive = true
            
            cropViewTopConstraint?.isActive = true
            cropViewPortraitBottomConstraint?.isActive = true
            cropViewPortraitLeftConstraint?.isActive = true
            cropViewPortaitRightConstraint?.isActive = true
            
            optionButtonStackView?.axis = .horizontal
            
        } else if UIApplication.shared.statusBarOrientation.isLandscape {
            toolbarWidthConstraint?.isActive = true
            toolbarTopConstraint?.isActive = true
            toolbarBottomConstraint?.isActive = true
            
            cropViewTopConstraint?.isActive = true
            cropViewLandscapeBottomConstraint?.isActive = true
            
            optionButtonStackView?.axis = .vertical
            
            if UIApplication.shared.statusBarOrientation == .landscapeLeft {
                toolbarRightConstraint?.isActive = true
                cropViewLandscapeLeftLeftConstraint?.isActive = true
                cropViewLandscapeLeftRightConstraint?.isActive = true
            } else {
                toolbarLeftConstraint?.isActive = true
                cropViewLandscapeRightLeftConstraint?.isActive = true
                cropViewLandscapeRightRightConstraint?.isActive = true
            }
        }
    }
}

extension CropViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}

extension CropViewController {
    public func confirmCrop() -> UIImage? {
        return cropView?.crop()
    }
}
