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
    
    private static let animationKey: String = "CBAnimationSelectionCellSelectAnimation"
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    
    private var snapshotView: UIImageView =  {
        let imageView = UIImageView()
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var overlayView: UIView = UIView()
    
    
    var csCenterX: NSLayoutConstraint?
    var csCenterY: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureOverlay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureOverlay()
    }
    
    private func configureOverlay() {
        addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        overlayView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        overlayView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        overlayView.isHidden = true
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
            self?.snapshotView.removeFromSuperview()
            self?.snapshotView.layer.removeAllAnimations()
            self?.snapshotView.layer.transform = CATransform3DIdentity
            self?.overlayView.isHidden = true
        }
        guard animated else {
            finishDeselection()
            return
        }
        let presentationLayer = snapshotView.layer.presentation() ?? snapshotView.layer
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
        
        let animations: [CAAnimation] = [translate, shadowOpacity, shadowOffset, shadowRadius]
        animationGroup.animations = animations
        animationGroup.isRemovedOnCompletion = false
        animationGroup.duration = animationDuration
        animationGroup.fillMode = .forwards
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            finishDeselection()
        }
        snapshotView.layer.add(animationGroup, forKey: type(of: self).animationKey)
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
        superview.addSubview(snapshotView)
        superview.bringSubviewToFront(snapshotView)
        snapshotView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        snapshotView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        if let csCenterX = csCenterX {
            snapshotView.superview?.removeConstraint(csCenterX)
        }
        if let csCenterY = csCenterY {
            snapshotView.superview?.removeConstraint(csCenterY)
        }
        csCenterX = snapshotView.centerXAnchor.constraint(equalTo: centerXAnchor)
        csCenterY = snapshotView.centerYAnchor.constraint(equalTo: centerYAnchor)
        csCenterX?.isActive = true
        csCenterY?.isActive = true
        snapshotView.layoutIfNeeded()
        
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
            
            let animations: [CAAnimation] = [translate, shadowOpacity, shadowOffset, shadowRadius]
            
            animationGroup.animations = animations
            animationGroup.isRemovedOnCompletion = false
            animationGroup.fillMode = .forwards
            animationGroup.duration =  animationDuration
            snapshotView.layer.add(animationGroup, forKey: type(of: self).animationKey)
        } else {
            snapshotView.layer.transform = CATransform3DTranslate(CATransform3DIdentity,
                                                                  horOffsetMultiplier * frame.width * 0.2,
                                                                  -frame.height * 0.2, 0)
            snapshotView.layer.shadowOpacity = 0.3
            snapshotView.layer.shadowOffset = CGSize(width: horOffsetMultiplier * -20.0, height: 20.0)
            snapshotView.layer.shadowRadius = 35.0
        }
    }
}
