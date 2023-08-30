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
                }
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("Tap on an image to change it.")
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
                    logoImage: $logoImage, changingLogo: $changingLogo,
                    stripImage: $stripImage, changingStrip: $changingStrip,
                    thumbnailImage: $thumbnailImage, changingThumbnail: $changingThumbnail
                )
            }
            
            Spacer()
            
            HStack {
                // Apply Button
                Button(action: {
                    MainCardController.setImages(
                        cardID: cardPath,
                        logo: changingLogo ? logoImage : nil,
                        strip: changingStrip ? stripImage : nil,
                        thumbnail: changingThumbnail ? thumbnailImage : nil
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
                        .opacity((changingLogo || changingStrip || changingThumbnail) ? 1 : 0)
                        .disabled(!changingLogo && !changingStrip && !changingThumbnail)
//                        .animation(.spring().speed(1.5), value: $themeManager.preferedThemes.count)
                }
                
                // Reset Button
                Button(action: {
                    MainCardController.resetImages(cardID: cardPath)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(8)
                        .opacity(showReset ? 1 : 0)
                        .disabled(!showReset)
                }
                .padding(.trailing, 8)
            }
        }
        .padding()
        .onAppear {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                do {
                    // TrollStore method
                    try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/var/mobile/Library/Caches"), includingPropertiesForKeys: nil)
                } catch {
                    // MDC method
                    // grant r/w access
                    if #available(iOS 15, *) {
                        grant_full_disk_access() { error in
                            if (error != nil) {
                                UIApplication.shared.alert(title: "Access Error", body: "Error: \(String(describing: error?.localizedDescription))\nPlease close the app and retry.")
                            }
                        }
                    } else {
                        UIApplication.shared.alert(title: "MDC Not Supported", body: "Please install via TrollStore")
                    }
                }
                
                // get the cards
                let cards = MainCardController.getPasses()
                if cards.count > 0 {
                    cardPath = cards[0]
                    
                    // check if the user can reset
                    showReset = MainCardController.canReset(cardID: cardPath)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
