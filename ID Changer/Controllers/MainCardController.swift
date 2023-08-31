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
        if #available(iOS 16.2, *) {
            restartFrontboard()
        } else if UserDefaults.standard.string(forKey: "RespringType") ?? "Backboard" == "Backboard" {
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
    
    static var folderVnode: UInt64 = 0;
    
    // MARK: General Card Methods
    
    static func clearMountedDir() {
        let fm = FileManager.default
        do {
            let folders = try fm.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/mounted").filter {
                $0.hasSuffix("pkpass");
            }
            
            for folder in folders {
                try FileManager.default.removeItem(atPath: folder)
            }
        } catch {
            print(error.localizedDescription)
        }
        do {
            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/mounted/Cards")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func getPasses(fullPath: String) -> [String]
    {
        let fm = FileManager.default
        var path = fullPath + "/"
        if #available(iOS 16.2, *) {
            path += "Cards/"
        }
        var data = [String]()
        
        do {
            let passes = try fm.contentsOfDirectory(atPath: path).filter {
                $0.hasSuffix("pkpass");
            }
            
            for pass in passes {
                var vnode: UInt64 = 0
                if #available(iOS 16.2, *) {
                    // kfd need to redirect
                    vnode = redirectCardFolder(pass + "/")
                }
                let files = try fm.contentsOfDirectory(atPath: fullPath + "/" + pass)
                
                if (files.contains(ChangingFile.logo.rawValue) && files.contains(ChangingFile.strip.rawValue) && files.contains(ChangingFile.thumbnail.rawValue))
                {
                    data.append(pass)
                    folderVnode = vnode
                } else {
                    if #available(iOS 16.2, *) {
                        UnRedirectAndRemoveFolder(vnode, path + pass)
                    }
                }
            }
            print(data)
            return data
            
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    static func canReset(cardID: String, fullPath: String) -> Bool {
        let fm = FileManager.default
        
        for f in ChangingFile.allCases {
            if fm.fileExists(atPath: "\(fullPath)/\(cardID)/\(f.rawValue).backup") {
                return true
            }
        }
        
        return false
    }
    
    // general function to set all changes
    static func setChanges(_ kfd: UInt64, vnodeOrig: UInt64, cardID: String, fullPath: String, logo: UIImage? = nil, strip: UIImage? = nil, thumbnail: UIImage? = nil, holderName: String? = nil, originalName: String? = nil, holderStatus: String? = nil, originalStatus: String? = nil) {
        let fm = FileManager.default
        
        // set all the images
        setImages(cardID: cardID, fullPath: fullPath, logo: logo, strip: strip, thumbnail: thumbnail)
        
        // set the card info
        setCardInfo(cardID: cardID, fullPath: fullPath, holderName: holderName, originalName: originalName, holderStatus: holderStatus, originalStatus: originalStatus)
        
        if #available(iOS 16.2, *) {
            // kfd fallback
            try? fm.removeItem(atPath: "\(fullPath)/Cards/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        } else {
            // do not force delete in case it is already not there
            try? fm.removeItem(atPath: "\(fullPath)/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        }
        
        // for kfd, kclose
        if #available(iOS 16.2, *) {
            UnRedirectAndRemoveFolder(folderVnode, fullPath + "/\(cardID)/")
            UnRedirectAndRemoveFolder(vnodeOrig, fullPath + "/Cards/");
            do_kclose(kfd)
        }
        
        // respring to apply changes
        respring()
    }
    
    // general function to reset all changes
    static func resetChanges(_ kfd: UInt64, vnodeOrig: UInt64, cardID: String, fullPath: String, images: Bool = true, cardInfo: Bool = true) {
        let fm = FileManager.default
        
        if images {
            resetImages(cardID: cardID, fullPath: fullPath)
        }
        if cardInfo {
            resetCardInfo(cardID: cardID, fullPath: fullPath)
        }
        
        // do not force delete in case it is already not there
        do {
            try fm.removeItem(atPath: "\(fullPath)/" + cardID.replacingOccurrences(of: "pkpass", with: "cache"))
        } catch {
            print(error.localizedDescription)
        }
        
        // for kfd, kclose
        if #available(iOS 16.2, *) {
            UnRedirectAndRemoveFolder(vnodeOrig, fullPath);
            do_kclose(kfd)
        }
        
        // respring to apply changes
        respring()
    }
    
    
    // MARK: Image Methods
    
    static func resetImages(cardID: String, fullPath: String) {
        let fm = FileManager.default
        
        for f in ChangingFile.allCases {
            let imgPath = "\(fullPath)/\(cardID)/\(f.rawValue)"
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
    
    static func setImages(cardID: String, fullPath: String, logo: UIImage?, strip: UIImage?, thumbnail: UIImage?) {
        // set the logo
        if logo != nil {
            setImage(cardID: cardID, fullPath: fullPath, image: logo!, fileType: .logo)
        }
        // set the strip
        if strip != nil {
            setImage(cardID: cardID, fullPath: fullPath, image: strip!, fileType: .strip)
        }
        // set the thumbnail
        if thumbnail != nil {
            setImage(cardID: cardID, fullPath: fullPath, image: thumbnail!, fileType: .thumbnail)
        }
    }
    
    static func setImage(cardID: String, fullPath: String, image: UIImage, fileType: ChangingFile) {
        if let data = image.pngData() {
            do {
                let fm = FileManager.default
                
                let path = "\(fullPath)/\(cardID)/\(fileType.rawValue)"
                
                if #available(iOS 16.2, *) {
                    // use kfd method
                    kfdOverwriteImage(filePath: path, image: data)
                    usleep(500)
                    return
                }
                
                if !fm.fileExists(atPath: path + ".backup") {
                    try fm.moveItem(atPath: path, toPath: path + ".backup")
                }
                try data.write(to: URL(fileURLWithPath: path))
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    static func kfdOverwriteImage(filePath: String, image: Data) {
        do {
            let imgPath = NSHomeDirectory() + "/Documents/temp.png"
            if FileManager.default.fileExists(atPath: imgPath) {
                try? FileManager.default.removeItem(atPath: imgPath)
            }
            try image.write(to: URL(fileURLWithPath: imgPath))
            
            overwritePath(filePath, imgPath)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: Card Info Methods
    
    static func getCardInfo(cardID: String, fullPath: String) -> [String: String] {
        // gets info such as the name and labels
        // format:
        // [
        //      "CardHolderName":   Name on Card
        //      "CardHolderStatus": Status of Card Holder (ie. Student)
        // ]
        let jsonPath = "\(fullPath)/\(cardID)/pass.json"
        
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
    
    static func setCardInfo(cardID: String, fullPath: String, holderName: String?, originalName: String?, holderStatus: String?, originalStatus: String?) {
        // skip the rest of the function if both are nil
        if (holderName == nil || originalName == nil) && (holderStatus == nil || originalStatus == nil) { return }
        
        let fm = FileManager.default
        let jsonPath = "\(fullPath)/\(cardID)/pass.json"
        
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
                if #available(iOS 16.2, *) {
                    // kfd fallback
                    kfdOverwriteInfo(filePath: jsonPath, data: data)
                    return
                }
                if !fm.fileExists(atPath: jsonPath + ".backup") {
                    try fm.moveItem(atPath: jsonPath, toPath: jsonPath + ".backup")
                }
                try data.write(to: URL(fileURLWithPath: jsonPath))
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func kfdOverwriteInfo(filePath: String, data: Data) {
        do {
            let jsonPath = NSHomeDirectory() + "/Documents/temp.json"
            if FileManager.default.fileExists(atPath: jsonPath) {
                try? FileManager.default.removeItem(atPath: jsonPath)
            }
            try data.write(to: URL(fileURLWithPath: jsonPath))
            
            overwritePath(filePath, jsonPath)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func resetCardInfo(cardID: String, fullPath: String) {
        let fm = FileManager.default
        let jsonPath = "\(fullPath)/\(cardID)/pass.json"
        
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
