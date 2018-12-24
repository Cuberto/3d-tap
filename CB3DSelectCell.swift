//
//  CBAnimationSelectionCell.swift
//  AnimatedCollection
//
//  Created by Anton Skopin on 22/12/2018.
//  Copyright © 2018 cuberto. All rights reserved.
//

import UIKit

class CB3DSelectCell: UICollectionViewCell {
    
    enum OffsetDirection {
        case left
        case right
    }
    
    var offsetDirection: OffsetDirection = .right
    var animationDuration: CFTimeInterval = 0.2
    var maxCornerRadius: CGFloat = 14.0
    
    private static let animationKey: String = "CBAnimationSelectionCellSelectAnimation"
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    
    
    private var snapshotContainer: UIView =  {
        let view = UIView()
        view.layer.shadowColor = UIColor.black.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var snapshotView: UIImageView =  {
        let imageView = UIImageView()
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    private var overlayView: UIView = UIView()
    
    
    var csCenterX: NSLayoutConstraint?
    var csCenterY: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    private func configureViews() {
        addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        overlayView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        overlayView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        overlayView.isHidden = true
        
        snapshotContainer.addSubview(snapshotView)
        snapshotView.topAnchor.constraint(equalTo: snapshotContainer.topAnchor).isActive = true
        snapshotView.leadingAnchor.constraint(equalTo: snapshotContainer.leadingAnchor).isActive = true
        snapshotView.trailingAnchor.constraint(equalTo: snapshotContainer.trailingAnchor).isActive = true
        snapshotView.bottomAnchor.constraint(equalTo: snapshotContainer.bottomAnchor).isActive = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(snapshotTapped))
        snapshotContainer.addGestureRecognizer(gesture)
    }
    
    @objc private func snapshotTapped() {
        guard _selected else { return }
        deselect(animated: true)
        if let collectionView = superview as? UICollectionView,
           let indexPath = collectionView.indexPath(for: self) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    var _selected: Bool = false
    
    func deselect(animated: Bool) {
        guard _selected else { return }
        _selected = false
        let finishDeselection: ()->Void = { [weak self] in
            if let csCenterX = self?.csCenterX {
                self?.snapshotView.superview?.removeConstraint(csCenterX)
            }
            if let csCenterY = self?.csCenterY {
                self?.snapshotView.superview?.removeConstraint(csCenterY)
            }
            self?.csCenterX = nil
            self?.csCenterY = nil
            self?.overlayView.isHidden = true
            self?.snapshotContainer.removeFromSuperview()
            self?.snapshotContainer.layer.removeAllAnimations()
            self?.snapshotView.layer.removeAllAnimations()
            self?.snapshotContainer.layer.transform = CATransform3DIdentity
            self?.overlayView.isHidden = true
        }
        guard animated else {
            finishDeselection()
            return
        }
        let presentationLayer = snapshotContainer.layer.presentation() ?? snapshotContainer.layer
        let currentTransform: CGAffineTransform = CATransform3DGetAffineTransform(presentationLayer.transform)
        
        let animationGroup = CAAnimationGroup()
        let translate = CABasicAnimation(keyPath: "transform.translation")
        translate.fromValue = CGSize(width: currentTransform.tx, height: currentTransform.ty)
        translate.toValue = CGSize.zero
        
        let shadowOpacity = CABasicAnimation(keyPath: "shadowOpacity")
        shadowOpacity.fromValue = presentationLayer.shadowOpacity
        shadowOpacity.toValue = 0.0
        
        let shadowOffset = CABasicAnimation(keyPath: "shadowOffset")
        shadowOffset.fromValue = presentationLayer.shadowOffset
        shadowOffset.toValue = CGSize.zero
        
        let shadowRadius = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadius.fromValue = presentationLayer.shadowRadius
        shadowRadius.toValue = 0.0
        
        let cornerRadius = CABasicAnimation(keyPath: "cornerRadius")
        cornerRadius.fromValue = presentationLayer.shadowRadius
        cornerRadius.toValue = layer.cornerRadius
        cornerRadius.isRemovedOnCompletion = false
        cornerRadius.duration = animationDuration
        cornerRadius.fillMode = .forwards
        
        let animations: [CAAnimation] = [translate, shadowOpacity, shadowOffset, shadowRadius, cornerRadius]
        animationGroup.animations = animations
        animationGroup.isRemovedOnCompletion = false
        animationGroup.duration = animationDuration
        animationGroup.fillMode = .forwards
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            finishDeselection()
        }
        snapshotView.layer.add(cornerRadius, forKey: type(of: self).animationKey)
        snapshotContainer.layer.add(animationGroup, forKey: type(of: self).animationKey)
        CATransaction.commit()
    }
    
    func select(animated: Bool) {
        guard !_selected else { return }
        _selected = true
        guard let superview = superview else {
            return
        }
        let wasHidden = layer.isHidden
        layer.isHidden = false
        UIGraphicsBeginImageContextWithOptions(CGSize(width: frame.width, height: frame.height), false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        layer.isHidden = wasHidden
        overlayView.backgroundColor = superview.backgroundColor
        overlayView.isHidden = false
        bringSubviewToFront(overlayView)
        
        snapshotView.image = capturedImage
        superview.addSubview(snapshotContainer)
        superview.bringSubviewToFront(snapshotContainer)
        snapshotContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        snapshotContainer.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        if let csCenterX = csCenterX {
            snapshotContainer.superview?.removeConstraint(csCenterX)
        }
        if let csCenterY = csCenterY {
            snapshotContainer.superview?.removeConstraint(csCenterY)
        }
        csCenterX = snapshotContainer.centerXAnchor.constraint(equalTo: centerXAnchor)
        csCenterY = snapshotContainer.centerYAnchor.constraint(equalTo: centerYAnchor)
        csCenterX?.isActive = true
        csCenterY?.isActive = true
        snapshotContainer.layoutIfNeeded()
        
        let horOffsetMultiplier: CGFloat
        switch offsetDirection {
        case .left:
            horOffsetMultiplier = -1.0
        case .right:
            horOffsetMultiplier = 1.0
        }
        
        if animated {
            let animationGroup = CAAnimationGroup()
            let translate = CABasicAnimation(keyPath: "transform.translation")
            translate.fromValue = CGSize.zero
            translate.toValue = CGSize(width: horOffsetMultiplier * frame.width * 0.2,
                                       height: -frame.height * 0.2)
            
            let shadowOpacity = CABasicAnimation(keyPath: "shadowOpacity")
            shadowOpacity.fromValue = 0
            shadowOpacity.toValue = 0.3
            
            let shadowOffset = CABasicAnimation(keyPath: "shadowOffset")
            shadowOffset.fromValue = CGSize.zero
            shadowOffset.toValue = CGSize(width: horOffsetMultiplier * -20, height: 20)
            
            let shadowRadius = CABasicAnimation(keyPath: "shadowRadius")
            shadowRadius.fromValue = 0
            shadowRadius.toValue = 35.0
            
            let cornerRadius = CABasicAnimation(keyPath: "cornerRadius")
            cornerRadius.fromValue = layer.cornerRadius
            cornerRadius.toValue = maxCornerRadius
            cornerRadius.isRemovedOnCompletion = false
            cornerRadius.fillMode = .forwards
            cornerRadius.duration =  animationDuration
            
            let animations: [CAAnimation] = [translate, shadowOpacity, shadowOffset, shadowRadius, cornerRadius]
            
            animationGroup.animations = animations
            animationGroup.isRemovedOnCompletion = false
            animationGroup.fillMode = .forwards
            animationGroup.duration =  animationDuration
            snapshotContainer.layer.add(animationGroup, forKey: type(of: self).animationKey)
            snapshotView.layer.add(cornerRadius, forKey: type(of: self).animationKey)
        } else {
            snapshotContainer.layer.transform = CATransform3DTranslate(CATransform3DIdentity,
                                                                  horOffsetMultiplier * frame.width * 0.2,
                                                                  -frame.height * 0.2, 0)
            snapshotContainer.layer.shadowOpacity = 0.3
            snapshotContainer.layer.shadowOffset = CGSize(width: horOffsetMultiplier * -20.0, height: 20.0)
            snapshotContainer.layer.shadowRadius = 35.0
            snapshotContainer.layer.cornerRadius = maxCornerRadius
        }
    }
    
}
