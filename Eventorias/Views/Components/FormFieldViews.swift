//
// FormFieldViews.swift
// Eventorias
//
// Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    @ViewBuilder
    func accessibilityLabelIfNeeded(_ label: String?) -> some View {
        if let label = label {
            self.accessibilityLabel(label)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func accessibilityHintIfNeeded(_ hint: String?) -> some View {
        if let hint = hint {
            self.accessibilityHint(hint)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func conditionalModifier<T: ViewModifier>(_ condition: Bool, modifier: T) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }
}

// MARK: - Private View Extensions

private extension View {
    func textFieldStyle() -> some View {
        self
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(height: 56)
    }
}

// MARK: - Styled TextEditor Component

struct StyledTextEditor: View {
    // MARK: - Configuration
    struct Configuration {
        var height: CGFloat = 120
        var minHeight: CGFloat = 56
        var maxHeight: CGFloat? = nil
        var cornerRadius: CGFloat = 12
        var backgroundColor: Color = Color("DarkGray")
        var textColor: Color = .white
        var placeholderColor: Color = .gray
        var borderWidth: CGFloat = 2
        var focusedBorderColor: Color = .blue
        var errorBorderColor: Color = .red
        var padding: EdgeInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        var font: Font = .body
        var animationDuration: Double = 0.2
    }
    
    // MARK: - Properties
    @Binding var text: String
    var placeholder: String = "Tap here to enter your description"
    var configuration = Configuration()
    
    // Functional Properties
    var isDisabled: Bool = false
    var maxLength: Int? = nil
    var showCharacterCount: Bool = false
    var isExpandable: Bool = true
    
    // Validation
    var validator: ((String) -> String?)? = nil
    var showValidationOnEdit: Bool = false
    
    // Actions
    var onEditingChanged: ((Bool) -> Void)? = nil
    var onTextChanged: ((String) -> Void)? = nil
    
    // Accessibility
    var accessibilityId: String? = nil
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    
    // MARK: - State
    @FocusState private var isFocused: Bool
    @State private var errorMessage: String? = nil
    @State private var hasBeenEdited: Bool = false
    @State private var currentHeight: CGFloat = 0
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        if errorMessage != nil {
            return configuration.errorBorderColor
        } else if isFocused {
            return configuration.focusedBorderColor
        } else {
            return .clear
        }
    }
    
    private var shouldShowError: Bool {
        errorMessage != nil && (showValidationOnEdit ? hasBeenEdited : true)
    }
    
    private var characterCount: Int {
        text.count
    }
    
    private var dynamicHeight: CGFloat {
        guard isExpandable && currentHeight > 0 else {
            return configuration.height
        }
        
        let height = max(configuration.minHeight, currentHeight)
        if let maxHeight = configuration.maxHeight {
            return min(height, maxHeight)
        }
        
        return height
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            textEditorContainer
            bottomSection
        }
        .onChange(of: text) { oldValue, newValue in
            handleTextChange(newValue)
        }
        .onChange(of: isFocused) { oldValue, newValue in
            onEditingChanged?(newValue)
            if !newValue && hasBeenEdited {
                validateText()
            }
        }
    }
    
    // MARK: - Views
    private var textEditorContainer: some View {
        ZStack(alignment: .topLeading) {
            backgroundView
            textEditorView
            if text.isEmpty {
                placeholderView
            }
        }
        .frame(height: dynamicHeight)
        .accessibilityIdentifier(accessibilityId ?? "textEditor")
        .accessibilityLabelIfNeeded(accessibilityLabel)
        .accessibilityHintIfNeeded(accessibilityHint)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
            .fill(isDisabled ? configuration.backgroundColor.opacity(0.6) : configuration.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .stroke(borderColor, lineWidth: configuration.borderWidth)
            )
            .animation(.easeInOut(duration: configuration.animationDuration), value: borderColor)
    }
    
    private var textEditorView: some View {
        TextEditor(text: $text)
            .font(configuration.font)
            .foregroundColor(isDisabled ? configuration.textColor.opacity(0.6) : configuration.textColor)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .focused($isFocused)
            .disabled(isDisabled)
            .padding(configuration.padding)
            .background(heightCalculationView)
    }
    
    private var heightCalculationView: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    if isExpandable {
                        currentHeight = geometry.size.height
                    }
                }
                .onChange(of: text) { _, _ in
                    if isExpandable {
                        DispatchQueue.main.async {
                            currentHeight = geometry.size.height
                        }
                    }
                }
        }
    }
    
    private var placeholderView: some View {
        Text(placeholder)
            .font(configuration.font)
            .foregroundColor(configuration.placeholderColor)
            .padding(configuration.padding)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: configuration.animationDuration), value: text.isEmpty)
    }
    
    @ViewBuilder
    private var bottomSection: some View {
        if shouldShowError || showCharacterCount {
            HStack {
                if shouldShowError, let errorMessage = errorMessage {
                    errorView(errorMessage)
                }
                
                Spacer()
                
                if showCharacterCount {
                    characterCountView
                }
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(configuration.errorBorderColor)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(configuration.errorBorderColor)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: configuration.animationDuration), value: shouldShowError)
    }
    
    private var characterCountView: some View {
        Group {
            if let maxLength = maxLength {
                Text("\(characterCount)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(characterCount > maxLength ? .red : .secondary)
            } else {
                Text("\(characterCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .animation(.easeInOut(duration: configuration.animationDuration), value: characterCount)
    }
    
    // MARK: - Methods
    private func handleTextChange(_ newValue: String) {
        if let maxLength = maxLength, newValue.count > maxLength {
            text = String(newValue.prefix(maxLength))
            return
        }
        
        hasBeenEdited = true
        onTextChanged?(newValue)
        
        if showValidationOnEdit {
            validateText()
        }
    }
    
    private func validateText() {
        withAnimation(.easeInOut(duration: configuration.animationDuration)) {
            errorMessage = validator?(text)
        }
    }
}

// MARK: - Styled TextField Component

struct StyledTextField: View {
    // MARK: - Configuration
    struct Configuration {
        var height: CGFloat = 56
        var cornerRadius: CGFloat = 12
        var backgroundColor: Color = Color("DarkGray")
        var textColor: Color = .white
        var placeholderColor: Color = .gray
        var horizontalPadding: CGFloat = 16
        var font: Font = .body
        var borderWidth: CGFloat = 2
        var focusedBorderColor: Color = .blue
        var errorBorderColor: Color = .red
        var animationDuration: Double = 0.2
    }
    
    // MARK: - Properties
    let placeholder: String
    @Binding var text: String
    var configuration = Configuration()
    
    // Functional Properties
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false // ✅ Nouveau paramètre
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .done
    var isDisabled: Bool = false
    var maxLength: Int? = nil
    
    // Validation
    var validator: ((String) -> String?)? = nil
    var showValidationOnEdit: Bool = false
    
    // Actions
    var onEditingChanged: ((Bool) -> Void)? = nil
    var onCommit: (() -> Void)? = nil
    var onPasswordToggle: (() -> Void)? = nil // ✅ Nouveau callback
    
    // Accessibility
    var accessibilityId: String? = nil
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    
    // MARK: - State
    @FocusState private var isFocused: Bool
    @State private var errorMessage: String? = nil
    @State private var hasBeenEdited: Bool = false
    @State private var isPasswordVisible: Bool = false // ✅ Nouvel état
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        if errorMessage != nil {
            return configuration.errorBorderColor
        } else if isFocused {
            return configuration.focusedBorderColor
        } else {
            return .clear
        }
    }
    
    private var shouldShowError: Bool {
        errorMessage != nil && (showValidationOnEdit ? hasBeenEdited : true)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            textFieldContainer
            
            if shouldShowError, let errorMessage = errorMessage {
                errorView(errorMessage)
            }
        }
        .onChange(of: text) { oldValue, newValue in
            handleTextChange(newValue)
        }
        .onChange(of: isFocused) { oldValue, newValue in
            onEditingChanged?(newValue)
            if !newValue && hasBeenEdited {
                validateText()
            }
        }
    }
    
    // MARK: - Views
    private var textFieldContainer: some View {
        HStack {
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle()
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle()
                }
            }
            .focused($isFocused)
            .disabled(isDisabled)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .submitLabel(submitLabel)
            .onSubmit {
                onCommit?()
            }
            
            // ✅ Bouton toggle pour les mots de passe
            if isSecure && showPasswordToggle {
                Button(action: {
                    isPasswordVisible.toggle()
                    onPasswordToggle?()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(configuration.textColor.opacity(0.7))
                        .padding(.trailing, 8)
                }
                .accessibilityIdentifier(isPasswordVisible ? "Masquer le mot de passe" : "Afficher le mot de passe")
            }
        }
        .background(backgroundView)
        .accessibilityIdentifier(accessibilityId ?? placeholder)
        .accessibilityLabel(accessibilityLabel ?? placeholder)
        .accessibilityHintIfNeeded(accessibilityHint)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
            .fill(isDisabled ? configuration.backgroundColor.opacity(0.6) : configuration.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .stroke(borderColor, lineWidth: configuration.borderWidth)
            )
            .animation(.easeInOut(duration: configuration.animationDuration), value: borderColor)
    }
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(configuration.errorBorderColor)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(configuration.errorBorderColor)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: configuration.animationDuration), value: shouldShowError)
    }
    
    // MARK: - Methods
    private func handleTextChange(_ newValue: String) {
        if let maxLength = maxLength, newValue.count > maxLength {
            text = String(newValue.prefix(maxLength))
            return
        }
        
        hasBeenEdited = true
        
        if showValidationOnEdit {
            validateText()
        }
    }
    
    private func validateText() {
        withAnimation(.easeInOut(duration: configuration.animationDuration)) {
            errorMessage = validator?(text)
        }
    }
}

// MARK: - Styled DatePicker Component (Séparé Date/Heure)

struct StyledDatePicker: View {
    // MARK: - Configuration
    struct Configuration {
        var height: CGFloat = 56
        var cornerRadius: CGFloat = 12
        var backgroundColor: Color = Color("DarkGray")
        var textColor: Color = .white
        var borderWidth: CGFloat = 2
        var focusedBorderColor: Color = .blue
        var errorBorderColor: Color = .red
        var padding: EdgeInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        var font: Font = .body
        var animationDuration: Double = 0.2
        var spacing: CGFloat = 12
    }
    
    // MARK: - Properties
    @Binding var date: Date
    var configuration = Configuration()
    
    // Content Properties
    var label: String? = nil
    var dateRange: ClosedRange<Date>? = nil
    
    // Functional Properties
    var isDisabled: Bool = false
    var showTimeSelector: Bool = true
    
    // Validation
    var validator: ((Date) -> String?)? = nil
    var showValidationOnEdit: Bool = false
    
    // Actions
    var onDateChanged: ((Date) -> Void)? = nil
    
    // Accessibility
    var accessibilityId: String? = nil
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    
    // MARK: - State
    @State private var errorMessage: String? = nil
    @State private var hasBeenEdited: Bool = false
    @State private var dateOnlyValue: Date
    @State private var timeOnlyValue: Date
    
    // MARK: - Initializer
    init(
        date: Binding<Date>,
        configuration: Configuration = Configuration(),
        label: String? = nil,
        dateRange: ClosedRange<Date>? = nil,
        isDisabled: Bool = false,
        showTimeSelector: Bool = true,
        validator: ((Date) -> String?)? = nil,
        showValidationOnEdit: Bool = false,
        onDateChanged: ((Date) -> Void)? = nil,
        accessibilityId: String? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil
    ) {
        self._date = date
        self.configuration = configuration
        self.label = label
        self.dateRange = dateRange
        self.isDisabled = isDisabled
        self.showTimeSelector = showTimeSelector
        self.validator = validator
        self.showValidationOnEdit = showValidationOnEdit
        self.onDateChanged = onDateChanged
        self.accessibilityId = accessibilityId
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        
        // Initialiser les valeurs séparées
        self._dateOnlyValue = State(initialValue: date.wrappedValue)
        self._timeOnlyValue = State(initialValue: date.wrappedValue)
    }
    
    // MARK: - Computed Properties
    private var shouldShowError: Bool {
        errorMessage != nil && (showValidationOnEdit ? hasBeenEdited : true)
    }
    
    private var datePickerRange: ClosedRange<Date> {
        dateRange ?? (Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date())...(Calendar.current.date(byAdding: .year, value: 100, to: Date()) ?? Date())
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                labelView(label)
            }
            
            pickerContainer
            
            if shouldShowError, let errorMessage = errorMessage {
                errorView(errorMessage)
            }
        }
    }
    
    // MARK: - Views
    private func labelView(_ text: String) -> some View {
        Text(text)
            .font(configuration.font)
            .foregroundColor(configuration.textColor)
    }
    
    private var pickerContainer: some View {
        HStack(spacing: configuration.spacing) {
            // Case de gauche pour la date
            datePickerView
            
            // Case de droite pour l'heure (optionnelle)
            if showTimeSelector {
                timePickerView
            }
        }
        .accessibilityIdentifier(accessibilityId ?? "dateTimePicker")
        .accessibilityLabelIfNeeded(accessibilityLabel)
        .accessibilityHintIfNeeded(accessibilityHint)
    }
    
    private var datePickerView: some View {
        HStack {
            DatePicker(
                "Date",
                selection: $dateOnlyValue,
                in: datePickerRange,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .font(configuration.font)
            .foregroundColor(isDisabled ? configuration.textColor.opacity(0.6) : configuration.textColor)
            .disabled(isDisabled)
            .onChange(of: dateOnlyValue) { oldValue, newValue in
                updateCombinedDate()
            }
            
            Spacer()
            
            Image(systemName: "calendar")
                .foregroundColor(configuration.textColor.opacity(0.7))
                .font(.system(size: 16))
        }
        .padding(configuration.padding)
        .frame(height: configuration.height)
        .background(
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
                .fill(isDisabled ? configuration.backgroundColor.opacity(0.6) : configuration.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: configuration.cornerRadius)
                        .stroke(.clear, lineWidth: configuration.borderWidth)
                )
        )
    }
    
    private var timePickerView: some View {
        HStack {
            DatePicker(
                "Heure",
                selection: $timeOnlyValue,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .font(configuration.font)
            .foregroundColor(isDisabled ? configuration.textColor.opacity(0.6) : configuration.textColor)
            .disabled(isDisabled)
            .onChange(of: timeOnlyValue) { oldValue, newValue in
                updateCombinedDate()
            }
            
            Spacer()
            
            Image(systemName: "clock")
                .foregroundColor(configuration.textColor.opacity(0.7))
                .font(.system(size: 16))
        }
        .padding(configuration.padding)
        .frame(height: configuration.height)
        .background(
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
                .fill(isDisabled ? configuration.backgroundColor.opacity(0.6) : configuration.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: configuration.cornerRadius)
                        .stroke(.clear, lineWidth: configuration.borderWidth)
                )
        )
    }
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(configuration.errorBorderColor)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(configuration.errorBorderColor)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: configuration.animationDuration), value: shouldShowError)
    }
    
    // MARK: - Methods
    private func updateCombinedDate() {
        let calendar = Calendar.current
        
        // Extraire les composants de date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: dateOnlyValue)
        
        // Extraire les composants d'heure
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnlyValue)
        
        // Combiner les composants
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        // Créer la nouvelle date combinée
        if let combinedDate = calendar.date(from: combinedComponents) {
            date = combinedDate
            hasBeenEdited = true
            onDateChanged?(combinedDate)
            
            if showValidationOnEdit {
                validateDate()
            }
        }
    }
    
    private func validateDate() {
        withAnimation(.easeInOut(duration: configuration.animationDuration)) {
            errorMessage = validator?(date)
        }
    }
}

// MARK: - Preview Container

struct FormComponentsPreviewContainer: View {
    @State private var textFieldValue = "Texte d'exemple"
    @State private var passwordValue = "motdepasse123"
    @State private var textEditorValue = "Description plus longue sur plusieurs lignes pour montrer comment le TextEditor gère le texte dans l'interface utilisateur."
    @State private var dateValue = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                previewSection(
                    title: "StyledTextField",
                    content: StyledTextField(
                        placeholder: "Entrez un titre",
                        text: $textFieldValue,
                        accessibilityId: "PreviewTextField"
                    )
                )
                
                previewSection(
                    title: "StyledTextField avec Toggle Password",
                    content: StyledTextField(
                        placeholder: "Entrez votre mot de passe",
                        text: $passwordValue,
                        isSecure: true,
                        showPasswordToggle: true,
                        textContentType: .password,
                        accessibilityId: "PreviewPasswordField"
                    )
                )
                
                previewSection(
                    title: "StyledTextEditor",
                    content: StyledTextEditor(
                        text: $textEditorValue,
                        maxLength: 200,
                        showCharacterCount: true
                    )
                )
                
                previewSection(
                    title: "StyledDatePicker (Date + Heure séparées)",
                    content: StyledDatePicker(
                        date: $dateValue,
                        label: "Date et heure de l'événement",
                        showTimeSelector: true
                    )
                )
                
                previewSection(
                    title: "StyledDatePicker (Date uniquement)",
                    content: StyledDatePicker(
                        date: $dateValue,
                        label: "Date de naissance",
                        showTimeSelector: false
                    )
                )
            }
            .padding()
        }
        .background(Color.black)
    }
    
    private func previewSection<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    FormComponentsPreviewContainer()
}
