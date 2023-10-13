//
//  MeView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 19/09/2023.
//
import CoreImage.CIFilterBuiltins
import SwiftUI

struct MeView: View {
//    @State private var name = "Anonymous"
//    @State private var emailAddress = "you@yoursite.com"
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    var body: some View {
       // NavigationView {
       //     Form {
//                TextField("Name", text: $name)
//                    .textContentType(.name)
//                    .font(.title)
//
//                TextField("Email address", text: $emailAddress)
//                    .textContentType(.emailAddress)
//                    .font(.title)

                Image(uiImage: generateQRCode(from: "||15102020360000010200180497|333|MARIANNA KOSIŃSKA| Zrzuta na sierotę informagiczną|kashiash@gmail.com|INV-08A|PLN"))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

          //  }
          //  .navigationTitle("Zrzuta na sierote informagiczną")
       // }
    }

    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

#Preview {
    MeView()
}
