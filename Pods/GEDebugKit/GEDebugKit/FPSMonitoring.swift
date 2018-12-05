//
//  FPSMonitoring.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 17/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEUIKit
import FPSCounter
import Foundation

class FPSMonitor: NSObject, FPSCounterDelegate {
    
    lazy var fpsCounter = FPSCounter() … {
        
        $0.delegate = self
    }
    
    private lazy var label: UILabel = UILabel() … {
        
        $0.font = UIFont.boldSystemFont(ofSize: 12.0)
        $0.textAlignment = .center
        $0.text = stringToDisplayForFPS(99)
        $0.sizeToFit()
    }
    
    // MARK: -
    
    func show() {
        
        do {
            let application = UIApplication.shared
            
            let window = StatusBarOverlayWindow(view: label)
            let detachHandler = application.makeWindowOverlayStatusBar(window)
            
            scheduledForHide.append(detachHandler)
        }

        do {
            fpsCounter.startTracking()
            
            scheduledForHide.append {
                self.fpsCounter.stopTracking()
            }
        }
    }
    
    var scheduledForHide = ScheduledHandlers()
    
    func hide() {
        
        scheduledForHide.perform()
    }
    
    // MARK: - FPSCounterDelegate
    
    func stringToDisplayForFPS(_ fps: Int) -> String {
        
        return String.localizedStringWithFormat(
            NSLocalizedString("%d", comment: ""),
            fps
        )
    }

    func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        
        let colors: (background: UIColor, text: UIColor) = {
            
            if fps >= 45 {
                return (
                    background: .green,
                    text: .black
                )
            } else if fps >= 30 {
                return (
                    background: .orange,
                    text: .white
                )
            } else {
                return (
                    background: .red,
                    text: .white
                )
            }
        }()

        label … {
            
            $0.text = stringToDisplayForFPS(fps)
            $0.textColor = colors.text
            $0.backgroundColor = colors.background
        }
    }
}
