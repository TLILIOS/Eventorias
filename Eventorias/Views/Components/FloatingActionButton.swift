//
//  FloatingActionButton.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 08/06/2025.
//
//
//  FloatingActionButton.swift
//  Eventorias
//
import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.red)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90) 
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FloatingActionButton {
            print("Bouton pressé")
        }
    }
}
