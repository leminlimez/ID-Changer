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
    
    // MARK: General Card Methods
    
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
            if fm.fileExists(atPath: "/var/mobile/Library/Passes/Cards/\(cardID)/\(f.rawValue).backup") {
                return true
            }
        }
        
        return false
    }
    
    // general function to set all changes
    static func setChanges(cardID: String, logo: UIImage? = nil, strip: UIImage? = nil, thumbnail: UIImage? = nil, holderName: String? = nil, originalName: String? = nil, holderStatus: String? = nil, originalStatus: String? = nil) {
        let fm = FileManager.default
        
        // set all the images
        setImages(cardID: cardID, logo: logo, strip: strip, thumbnail: thumbnail)
        
        // set the card info
        setCardInfo(cardID: cardID, holderName: holderName, originalName: originalName, holderStatus: holderStatus, originalStatus: originalStatus)
        
        // do not force delete in case it is already not there
        try? fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        
        // respring to apply changes
        respring()
    }
    
    // general function to reset all changes
    static func resetChanges(cardID: String, images: Bool = true, cardInfo: Bool = true) {
        let fm = FileManager.default
        
        if images {
            resetImages(cardID: cardID)
        }
        if cardInfo {
            resetCardInfo(cardID: cardID)
        }
        
        // do not force delete in case it is already not there
        try? fm.removeItem(atPath: "/var/mobile/Library/Passes/Cards/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        
        // respring to apply changes
        respring()
    }
    
    
    // MARK: Image Methods
    
    static func resetImages(cardID: String) {
        let fm = FileManager.default
        
        for f in ChangingFile.allCases {
            let imgPath = "/var/mobile/Library/Passes/Cards/\(cardID)/\(f.rawValue)"
            if fm.fileExists(atPath: imgPath + ".backup") {
                do {
                    try? fm.removeItem(atPath: imgPath)
                    try fm.moveItem(atPath: imgPath + ".backup", toPath: imgPath)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    static func setImages(cardID: String, logo: UIImage?, strip: UIImage?, thumbnail: UIImage?) {
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
    }
    
    static func setImage(cardID: String, image: UIImage, fileType: ChangingFile) {
        if let data = image.pngData() {
            do {
                let fm = FileManager.default
                
                let path = "/var/mobile/Library/Passes/Cards/\(cardID)/\(fileType.rawValue)"
                
                if !fm.fileExists(atPath: path + ".backup") {
                    try fm.moveItem(atPath: path, toPath: path + ".backup")
                }
                try data.write(to: URL(fileURLWithPath: path))
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    // MARK: Card Info Methods
    
    static func getCardInfo(cardID: String) -> [String: String] {
        // gets info such as the name and labels
        // format:
        // [
        //      "CardHolderName":   Name on Card
        //      "CardHolderStatus": Status of Card Holder (ie. Student)
        // ]
        let jsonPath = "/var/mobile/Library/Passes/Cards/\(cardID)/pass.json"
        
        var infoDict: [String: String] = [:]
        
        do {
            // get the json data
            let contents = try String(contentsOfFile: jsonPath)
            let data: Data? = contents.data(using: .utf8)
            
            if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                if let accessCard = json["accessCard"] as? [String: Any] {
                    // primary field values
                    if let primaryFieldsArray = accessCard["primaryFields"] as? [[String: Any]], let primaryFields = primaryFieldsArray.first {
                        if let name = primaryFields["value"] as? String {
                            infoDict["CardHolderName"] = name
                        }
                        if let status = primaryFields["label"] as? String {
                            infoDict["CardHolderStatus"] = status
                        }
                    } else if let backFieldsArray = accessCard["backFields"] as? [[String: Any]], let backFields = backFieldsArray.first {
                        // back field values
                        if let name = backFields["value"] as? String {
                            infoDict["CardHolderName"] = name
                        }
                        if let status = backFields["label"] as? String {
                            infoDict["CardHolderStatus"] = status
                        }
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return infoDict
    }
    
    static func setCardInfo(cardID: String, holderName: String?, originalName: String?, holderStatus: String?, originalStatus: String?) {
        // skip the rest of the function if both are nil
        if (holderName == nil || originalName == nil) && (holderStatus == nil || originalStatus == nil) { return }
        
        let fm = FileManager.default
        let jsonPath = "/var/mobile/Library/Passes/Cards/\(cardID)/pass.json"
        
        do {
            let contents = try String(contentsOfFile: jsonPath)
            var newContents = contents
            
            // replace the original name
            if let og = originalName, let hn = holderName {
                newContents = newContents.replacingOccurrences(of: og, with: hn)
            }
            
            // replace the original status
            if let og = originalStatus, let hs = holderStatus {
                newContents = newContents.replacingOccurrences(of: og, with: hs)
            }
            
            // write to the file
            if let data = newContents.data(using: .utf8) {
                if !fm.fileExists(atPath: jsonPath + ".backup") {
                    try fm.moveItem(atPath: jsonPath, toPath: jsonPath + ".backup")
                }
                try data.write(to: URL(fileURLWithPath: jsonPath))
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func resetCardInfo(cardID: String) {
        let fm = FileManager.default
        let jsonPath = "/var/mobile/Library/Passes/Cards/\(cardID)/pass.json"
        
        if fm.fileExists(atPath: jsonPath + ".backup") {
            do {
                try? fm.removeItem(atPath: jsonPath)
                try fm.moveItem(atPath: jsonPath + ".backup", toPath: jsonPath)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
