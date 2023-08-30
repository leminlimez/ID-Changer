//
//  ContentView.swift
//  ID Changer
//
//  Created by lemin on 8/29/23.
//

import SwiftUI
import MacDirtyCowSwift

struct ContentView: View {
    @State var cardPath = ""
    
    @State private var originalName: String = "Your Name"
    @State private var originalStatus: String = "Your Status"
    
    @State private var holderName: String = "Your Name"
    @State private var holderStatus: String = "Your Status"
    
    @State private var logoImage = UIImage()
    @State private var changingLogo = false
    
    @State private var stripImage = UIImage()
    @State private var changingStrip = false
    
    @State private var thumbnailImage = UIImage()
    @State private var changingThumbnail = false
    
    @State private var showReset: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("ID Changer")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button(action: {
                    UIApplication.shared.alert(title: "Default Image Sizes", body: "- Logo: 858x150\n- Strip: 1146x333\n- Thumbnail: 300x400?\n\nThese image sizes are not required, the card should automatically crop them.\n\nDevice will respring after applying/resetting.")
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                }
            }
            .padding(.bottom, 10)
            
            HStack {
                Spacer()
                Text("Tap on an image or text field to change it.")
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 5)
            
            Spacer()
            
            // Card View
            if cardPath == "" {
                Text("Error! Card not found!")
                    .foregroundColor(.red)
            } else {
                CardView(
                    cardPath: cardPath,
                    holderName: $holderName, holderStatus: $holderStatus,
                    logoImage: $logoImage, changingLogo: $changingLogo,
                    stripImage: $stripImage, changingStrip: $changingStrip,
                    thumbnailImage: $thumbnailImage, changingThumbnail: $changingThumbnail
                )
            }
            
            Spacer()
            
            HStack {
                // Apply Button
                Button(action: {
                    print("Applying Card...")
                    MainCardController.setChanges(
                        cardID: cardPath,
                        logo: changingLogo ? logoImage : nil,
                        strip: changingStrip ? stripImage : nil,
                        thumbnail: changingThumbnail ? thumbnailImage : nil,
                        holderName: holderName, originalName: originalName,
                        holderStatus: holderStatus, originalStatus: originalStatus
                    )
                }) {
                    Text("Apply")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .opacity((changingLogo || changingStrip || changingThumbnail || holderName != originalName || holderStatus != originalStatus) ? 1 : 0)
                }
                .disabled(!changingLogo && !changingStrip && !changingThumbnail && holderName == originalName && holderStatus == originalStatus)
                
                // Reset Button
                if showReset {
                    Button(action: {
                        print("Resetting Card...")
                        MainCardController.resetChanges(cardID: cardPath)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 8)
                }
            }
        }
        .padding()
        .onAppear {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                if #available(iOS 16.2, *) {
                    UIApplication.shared.alert(title: "Device Not Supported", body: "Your device is not supported by the MDC exploit, the app will not function, sorry.")
                } else {
                    do {
                        // TrollStore method
                        try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/var/mobile/Library/Caches"), includingPropertiesForKeys: nil)
                        
                        // succeeded, get the cards
                        getCards()
                    } catch {
                        // MDC method
                        // grant r/w access
                        if #available(iOS 15, *) {
                            grant_full_disk_access() { error in
                                if (error != nil) {
                                    UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error?.localizedDescription))\nPlease close the app and retry.")
                                } else {
                                    // succeeded, get the cards
                                    getCards()
                                }
                            }
                        } else {
                            UIApplication.shared.alert(title: "MDC Not Supported", body: "Please install via TrollStore")
                        }
                    }
                }
            }
        }
    }
    
    func getCards() {
        // get the cards
        let cards = MainCardController.getPasses()
        if cards.count > 0 {
            cardPath = cards[0]
            
            // check if the user can reset
            showReset = MainCardController.canReset(cardID: cardPath)
            
            // get the card info
            let cardInfo = MainCardController.getCardInfo(cardID: cardPath)
            if let name = cardInfo["CardHolderName"] {
                originalName = name
                holderName = name
            }
            if let status = cardInfo["CardHolderStatus"] {
                originalStatus = status
                holderStatus = status
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
