//
//  MainCardController.swift
//  ID Changer
//
//  Created by lemin on 8/29/23.
//

import Foundation
import SwiftUI
import MacDirtyCowSwift

enum ChangingFile: String, CaseIterable {
    case logo = "logo@3x.png"
    case strip = "strip@2x.png"
    case thumbnail = "thumbnail@2x.png"
}

func respring() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    
    let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
        let windows: [UIWindow] = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        
        for window in windows {
            window.alpha = 0
            window.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    animator.addCompletion { _ in
        if UserDefaults.standard.string(forKey: "RespringType") ?? "Backboard" == "Backboard" {
            restartBackboard()
        } else {
            restartFrontboard()
        }
        
        sleep(2) // give the springboard some time to restart before exiting
        exit(0)
    }
    
    animator.startAnimation()
}

class MainCardController {
    // Code adapted from Cowabunga
    static func getPasses() -> [String]
    {
        let fm = FileManager.default
        let path = "/var/mobile/Library/Passes/Cards/"
        var data = [String]()
        
        do {
            let passes = try fm.contentsOfDirectory(atPath: path).filter {
                $0.hasSuffix("pkpass");
            }
            
            for pass in passes {
                let files = try fm.contentsOfDirectory(atPath: path + pass)
                
                if (files.contains(ChangingFile.logo.rawValue) && files.contains(ChangingFile.strip.rawValue) && files.contains(ChangingFile.thumbnail.rawValue))
                {
                    data.append(pass)
                }
            }
            print(data)
            return data
            
        } catch {
            return []
        }
    }
    
    static func canReset(cardID: String) -> Bool {
        let fm = FileManager.default
        
        for f in ChangingFile.allCases {
            if fm.fileExists(atPath: "\(cardID)/\(f.rawValue).backup") {
                return true
            }
        }
        
        return false
    }
    
    static func resetImages(cardID: String) {
        let fm = FileManager.default
        
        for f in ChangingFile.allCases {
            let imgPath = "\(cardID)/\(f.rawValue)"
            if fm.fileExists(atPath: imgPath + ".backup") {
                do {
                    try? fm.removeItem(atPath: imgPath)
                    try fm.moveItem(atPath: imgPath + ".backup", toPath: imgPath)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        // do not force delete in case it is already not there
        try? fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        
        // respring to apply changes
        respring()
    }
    
    static func setImages(cardID: String, logo: UIImage?, strip: UIImage?, thumbnail: UIImage?) {
        let fm = FileManager.default
        
        // set the logo
        if logo != nil {
            setImage(cardID: cardID, image: logo!, fileType: .logo)
        }
        // set the strip
        if strip != nil {
            setImage(cardID: cardID, image: strip!, fileType: .strip)
        }
        // set the thumbnail
        if thumbnail != nil {
            setImage(cardID: cardID, image: thumbnail!, fileType: .thumbnail)
        }
        
        // do not force delete in case it is already not there
        try? fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        
        // respring to apply changes
        respring()
    }
    
    static func setImage(cardID: String, image: UIImage, fileType: ChangingFile) {
        if let data = image.pngData() {
            do {
                let fm = FileManager.default
                
                let path = "/var/mobile/Library/Passes/Cards/\(cardID)/\(fileType.rawValue)"
                
                try fm.moveItem(atPath: path, toPath: path + ".backup")
                try data.write(to: URL(fileURLWithPath: path))
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
