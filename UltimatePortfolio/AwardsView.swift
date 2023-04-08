//
//  AwardsView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 09/04/2023.
//

import SwiftUI

struct AwardsView: View {
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100,maximum: 100))]
    }
    
    var body: some View {
        NavigationStack{
            ScrollView{
                LazyVGrid(columns:columns) {
                    ForEach(Award.allAwards) { award in
                        Button{
                            
                        } label: {
                            Image(systemName: award.image)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                }
            }
            .navigationTitle("Pierdoły")
        }
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
    }
}
