//
//  SerialCodeView.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/17/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit

// Designable class so we can build out the ui in interface builder
@IBDesignable class SerialCodeView: UIButton {
    
    // Inspectible so you play with the formating in the interface builder
    @IBInspectable var insets: CGFloat = 3
   
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += insets * 4
        size.height += insets * 4
        return size
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Don't draw anything if the context has not been initilized or there is no text in the label
        guard let ctx = UIGraphicsGetCurrentContext(), self.titleLabel?.text?.count ?? 0 > 0 else { return }
        
        ctx.clear(rect)
        // Drawing code
        let padding = UIEdgeInsets(
            top: self.insets * 2,
            left: self.insets * 2,
            bottom: self.insets * 2,
            right: self.insets * 2
        )
        super.titleLabel?.drawText(in: rect.inset(by: padding))
        
        let suroundingFrame = CGRect(
            x: insets / 2,
            y: insets / 2,
            width: self.frame.width - insets,
            height: self.frame.height - insets
        )
        
        ctx.beginPath()
        ctx.setLineWidth(self.insets)
        ctx.setStrokeColor(self.titleLabel!.textColor.cgColor)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addLines(between: [
            CGPoint(x: suroundingFrame.minX, y: suroundingFrame.minX),
            CGPoint(x: suroundingFrame.maxX, y: suroundingFrame.minY),
            CGPoint(x: suroundingFrame.maxX, y: suroundingFrame.maxY),
            CGPoint(x: suroundingFrame.minX, y: suroundingFrame.maxY),
            CGPoint(x: suroundingFrame.minX, y: suroundingFrame.minY)
            ])
        ctx.drawPath(using: .stroke)
    }

}
