//
//  FormFieldViews.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI

// MARK: - Styled TextField Component
struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 5
    var backgroundColor: String = "DarkGry"
    var textColor: Color = .white
    var horizontalPadding: CGFloat = 16
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(Color(backgroundColor))
            .cornerRadius(cornerRadius)
            .foregroundColor(textColor)
    }
}

// MARK: - Styled TextEditor Component
struct StyledTextEditor: View {
    @Binding var text: String
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 5
    var backgroundColor: String = "DarkGry"
    var textColor: Color = .white
    
    var body: some View {
        TextEditor(text: $text)
            .frame(height: height)
            .scrollContentBackground(.hidden)
            .background(Color(backgroundColor))
            .cornerRadius(cornerRadius)
            .foregroundColor(textColor)
    }
}

// MARK: - Styled DatePicker Component
struct StyledDatePicker: View {
    @Binding var date: Date
    var components: DatePickerComponents
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 5
    var backgroundColor: String = "DarkGry"
    var horizontalPadding: CGFloat = 16
    
    var body: some View {
        DatePicker("", selection: $date, displayedComponents: components)
            .labelsHidden()
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(Color(backgroundColor))
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Preview Container
struct FormComponentsPreviewContainer: View {
    @State private var textFieldValue = "Texte d'exemple"
    @State private var textEditorValue = "Description plus longue sur plusieurs lignes pour montrer comment le TextEditor gère le texte dans l'interface utilisateur."
    @State private var dateValue = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("StyledTextField")
                    .font(.headline)
                    .foregroundColor(.white)
                
                StyledTextField(placeholder: "Entrez un titre", text: $textFieldValue)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("StyledTextEditor")
                    .font(.headline)
                    .foregroundColor(.white)
                
                StyledTextEditor(text: $textEditorValue, height: 150)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("StyledDatePicker")
                    .font(.headline)
                    .foregroundColor(.white)
                
                StyledDatePicker(date: $dateValue, components: [.date, .hourAndMinute])
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Preview
#Preview {
    FormComponentsPreviewContainer()
}
