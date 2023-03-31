//
//  CHIPageControlIsot.swift
//  CHIPageControl
//
//  Created by Egemen Türk on 31.03.2023.
//  Copyright © 2023 chi.lv. All rights reserved.
//


import UIKit

import UIKit

open class CHIPageControlIsot: CHIBasePageControl {
    
    internal var lastPage:Int = 0
    
    fileprivate var diameter: CGFloat {
        return radius * 2
    }
    
    fileprivate var inactive = [CHILayer]()
    
    fileprivate var active: CHILayer = CHILayer()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func updateNumberOfPages(_ count: Int) {
        inactive.forEach { $0.removeFromSuperlayer() }
        inactive = [CHILayer]()
        inactive = (0..<count).map {_ in
            let layer = CHILayer()
            self.layer.addSublayer(layer)
            return layer
        }

        self.layer.addSublayer(active)
        setNeedsLayout()
        self.invalidateIntrinsicContentSize()
    }
    
    override func update(for progress: Double) {
        guard progress >= 0 && progress <= Double(numberOfPages - 1),
            let firstFrame = self.inactive.first?.frame,
            numberOfPages > 1 else {
                return
        }
        let left = firstFrame.origin.x
        let normalized = progress * Double(diameter + padding)
        
        let currentPage = Int(progress)
        let stepSize = (diameter + padding)
        var leftX = CGFloat(currentPage)*stepSize+left
        var rightX = CGFloat(normalized)+left
        let stepProgress = progress - Double(currentPage)
        
        if abs(self.lastPage - currentPage) > 1 {
            self.lastPage = currentPage + (self.lastPage > currentPage ? 1 : -1)
        }
        
        var middleX = CGFloat(normalized)
        if stepProgress > 0.5 {
            if self.lastPage > currentPage {
                rightX = CGFloat(self.lastPage)*stepSize + left
                leftX = leftX + ((CGFloat(stepProgress)-0.5)*stepSize*2)
                middleX = leftX
            } else {
                leftX = leftX + ((CGFloat(stepProgress)-0.5)*stepSize*2)
                rightX = CGFloat(self.currentPage)*stepSize + left
                middleX = rightX
            }
        } else if self.lastPage > currentPage {
            rightX = CGFloat(self.lastPage)*stepSize - ((0.5-CGFloat(stepProgress))*stepSize*2) + left
            middleX = leftX
        } else {
            rightX = rightX + (CGFloat(stepProgress)*stepSize)
            middleX = rightX
        }
        
        let top = (self.bounds.size.height - self.diameter)*0.5
        
        let points:[CGPoint] = [
            CGPoint(x:leftX, y:radius + top),
            CGPoint(x:middleX+radius, y:top),
            CGPoint(x:rightX+radius*2, y:radius + top),
            CGPoint(x:middleX+radius, y:radius*2 + top)
        ]
        
        let offset: CGFloat = radius*0.55
        
        let path = UIBezierPath(ovalIn: CGRect(x: leftX - offset, y: top - offset, width: 12, height: 12))
        path.move(to: points[0])
        self.active.path = path.cgPath
        
        if progress.truncatingRemainder(dividingBy: 1) == 0 {
            self.lastPage = Int(progress)
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let floatCount = CGFloat(inactive.count)
        let x = (self.bounds.size.width - self.diameter*floatCount - self.padding*(floatCount-1))*0.5
        let y = (self.bounds.size.height - self.diameter)*0.5
        var frame = CGRect(x: x, y: y, width: self.diameter, height: self.diameter)
        
        inactive.enumerated().forEach() { index, layer in
            layer.backgroundColor = self.tintColor(position: index).withAlphaComponent(self.inactiveTransparency).cgColor
            if self.borderWidth > 0 {
                layer.borderWidth = self.borderWidth
                layer.borderColor = self.tintColor(position: index).cgColor
            }
            layer.cornerRadius = self.radius
            layer.frame = frame
            frame.origin.x += self.diameter + self.padding
        }
        self.active.fillColor = (self.currentPageTintColor ?? self.tintColor)?.cgColor
        update(for: progress)
    }
    
    override open var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: CGFloat(inactive.count) * self.diameter + CGFloat(inactive.count - 1) * self.padding,
                      height: self.diameter)
    }
    
    override open func didTouch(gesture: UITapGestureRecognizer) {
        let point = gesture.location(ofTouch: 0, in: self)
        if let touchIndex = inactive.enumerated().first(where: { $0.element.hitTest(point) != nil })?.offset {
            delegate?.didTouch(pager: self, index: touchIndex)
        }
    }
}
