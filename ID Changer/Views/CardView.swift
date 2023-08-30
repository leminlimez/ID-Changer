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
                        Image(uiImage: UIImage(contentsOfFile: "/var/mobile/Library/Passes/Cards/" + cardPath + "/logo@3x.png")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 286, height: 50)
                            .contentShape(Rectangle())
                            .clipped()
                            .padding(.horizontal, 5)
                    }
                    .onChange(of: self.logoImage) { _ in
                        changingLogo = true
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
                        Image(uiImage: UIImage(contentsOfFile: "/var/mobile/Library/Passes/Cards/" + cardPath + "/strip@2x.png")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 358, height: 100)
                            .contentShape(Rectangle())
                            .clipped()
                    }
                    .onChange(of: self.stripImage) { _ in
                        changingStrip = true
                    }
                    
                    // Profile Picture
                    Button(action: {
                        // Change Image
                        changingType = .thumbnail
                        showSheet = true
                    }) {
                        Image(uiImage: UIImage(contentsOfFile: "/var/mobile/Library/Passes/Cards/" + cardPath + "/thumbnail@2x.png")!)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                    }
                    .offset(y: 50)
                    .onChange(of: self.thumbnailImage) { _ in
                        changingThumbnail = true
                    }
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
            if changingType == .logo {
                ImagePickerView(sourceType: .photoLibrary, selectedImage: self.$logoImage)
            } else if changingType == .strip {
                ImagePickerView(sourceType: .photoLibrary, selectedImage: self.$stripImage)
            } else if changingType == .thumbnail {
                ImagePickerView(sourceType: .photoLibrary, selectedImage: self.$thumbnailImage)
            }
        }
        .frame(width: 358, height: 448)
    }
}
