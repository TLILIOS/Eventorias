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
