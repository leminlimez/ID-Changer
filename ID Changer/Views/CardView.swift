//
//  CardView.swift
//  ID Changer
//
//  Created by lemin on 8/29/23.
//

import Foundation
import SwiftUI

struct CardView: View {
    @State var cardPath: String
    
    @Binding var logoImage: UIImage
    @Binding var changingLogo: Bool
    
    @Binding var stripImage: UIImage
    @Binding var changingStrip: Bool
    
    @Binding var thumbnailImage: UIImage
    @Binding var changingThumbnail: Bool
    
    @State var showSheet = false
    @State var changingType: ChangingFile = .logo
    @State var changingImage = UIImage()
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .foregroundColor(.black)
                .frame(width: 358, height: 448)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray, lineWidth: 1)
                )
            
            // Main Card Stuff
            VStack {
                // Top Logo
                HStack {
                    Button(action: {
                        // Change Image
                        changingType = .logo
                        showSheet = true
                    }) {
                        Image(uiImage: changingLogo ? logoImage : UIImage(contentsOfFile: "/var/mobile/Library/Passes/Cards/\(cardPath)/\(ChangingFile.logo.rawValue)")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 286, height: 50)
                            .contentShape(Rectangle())
                            .clipped()
                            .padding(.horizontal, 5)
                    }
                    Spacer()
                }
                
                ZStack {
                    // Strip
                    Button(action: {
                        // Change Image
                        changingType = .strip
                        showSheet = true
                    }) {
                        Image(uiImage: changingStrip ? stripImage : UIImage(contentsOfFile: "/var/mobile/Library/Passes/Cards/\(cardPath)/\(ChangingFile.strip.rawValue)")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 358, height: 111)
                            .contentShape(Rectangle())
                            .clipped()
                    }
                    
                    // Profile Picture
                    Button(action: {
                        // Change Image
                        changingType = .thumbnail
                        showSheet = true
                    }) {
                        Image(uiImage: changingThumbnail ? thumbnailImage : UIImage(contentsOfFile: "/var/mobile/Library/Passes/Cards/\(cardPath)/\(ChangingFile.thumbnail.rawValue)")!)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                    }
                    .offset(y: 56)
                }
                .padding(.bottom, 50)
                
                // Name
                Text("Your Name")
                    .foregroundColor(.white)
                    .font(.title2)
                    .bold()
                
                // Student Label
                Text("Student")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .sheet(isPresented: $showSheet) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $changingImage)
        }
        .onChange(of: changingImage) { newImage in
            switch changingType {
            case .logo:
                logoImage = newImage
                changingLogo = true
            case .strip:
                stripImage = newImage
                changingStrip = true
            case .thumbnail:
                thumbnailImage = newImage
                changingThumbnail = true
            }
        }
        .frame(width: 358, height: 448)
    }
}
