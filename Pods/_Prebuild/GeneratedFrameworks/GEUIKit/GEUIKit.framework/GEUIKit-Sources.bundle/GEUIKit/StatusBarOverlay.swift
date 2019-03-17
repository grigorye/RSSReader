//
//  StatusBarOverlay.swift
//  GEUIKit
//
//  Created by Grigorii Entin on 17/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

private class StatusBarInfoViewController : UIViewController {
    
    var scheduledForDeinit = ScheduledHandlers()
    
    deinit {
        scheduledForDeinit.perform()
    }
    
    var infoView: UIView
    
    override func loadView() {
        
        self.view = UIView()
        
        view.addSubview(infoView)
    }
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        updateInfoViewFrame()
    }
    
    func updateInfoViewFrame() {
        
        if let _ = UIApplication.shared.statusBarTimeLabelForX() {
            
            let superviewBoundsCenter = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - infoView.bounds.height / 2)
            
            infoView.center = superviewBoundsCenter
            
            return
        }
        
        if let timeLabel = UIApplication.shared.statusBarTimeLabelForNonX() {
            
            infoView.frame.origin.x = timeLabel.frame.maxX + 4
            infoView.center.y = timeLabel.center.y
        }
    }
    
    init(infoView: UIView) {
        
        self.infoView = infoView

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
}

public class StatusBarOverlayWindow : UIWindow {
    
    /// Returns window that is configured for overlaying the status bar with the given view.
    public convenience init(view infoView: UIView) {
        
        self.init()
        
        windowLevel = UIWindow.Level.statusBar
        alpha = 1
        backgroundColor = .clear
        rootViewController = StatusBarInfoViewController(infoView: infoView)
    }
	
	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		
		return false
	}
}

public extension UIApplication {
    
    private func fitWindowFrameIntoStatusBar(_ window: UIWindow) {
        
        var bounds = self.statusBarFrame
        if !(0 < bounds.size.height) {
            bounds.size.height = 44
        }
        if !(0 < bounds.size.width) {
            bounds.size.width = UIScreen.main.bounds.width
        }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        window.bounds = bounds
        window.center = center
    }
    
    func makeWindowOverlayStatusBar(_ window: UIWindow) -> () -> Void {
        
        var scheduledForDeattach = ScheduledHandlers()
        
        do {
            let notificationCenter = NotificationCenter.default
            
            let observer = notificationCenter.addObserver(forName: UIApplication.willChangeStatusBarFrameNotification, object: nil, queue: nil) { _ in
                
                DispatchQueue.main.async {
                    self.fitWindowFrameIntoStatusBar(window)
                }
            }
            
            scheduledForDeattach.append {
                notificationCenter.removeObserver(observer)
            }
        }
        
        fitWindowFrameIntoStatusBar(window)

        do {
            window.isHidden = false
            
            scheduledForDeattach.append {
                window.isHidden = true
            }
        }

        return {
            scheduledForDeattach.perform()
        }
    }
}
