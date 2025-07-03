//
//  EventCalendarView.swift
//  Eventorias
//
//  Created on 03/07/2025.
//

import SwiftUI

struct EventCalendarView: View {
    let eventViewModel: EventViewModel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth = Date()
    
    // Liste des événements du jour sélectionné
    private var eventsOnSelectedDay: [Event] {
        eventViewModel.filteredEvents.filter { event in
            Calendar.current.isDate(event.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête calendrier avec navigation mois
            calendarHeader
            
            // Affichage des jours de la semaine
            weekdayHeader
                .padding(.top, 10)
            
            // Grille du calendrier
            calendarGrid
            
            // Liste des événements du jour sélectionné
            eventsList
        }
        .padding(.bottom, 80) // Espace pour la tabBar
    }
    
    // MARK: - Calendar Components
    
    private var calendarHeader: some View {
        HStack {
            Button(action: {
                withAnimation {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(monthYearString())
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(daysOfWeek(), id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var calendarGrid: some View {
        let days = daysInMonth()
        
        return VStack(spacing: 15) {
            ForEach(0..<days.count/7, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let index = row * 7 + column
                        if index < days.count {
                            let date = days[index]
                            DayCell(date: date, 
                                    isToday: Calendar.current.isDateInToday(date),
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                    hasEvents: hasEvents(on: date),
                                    onTap: {
                                        withAnimation {
                                            selectedDate = date
                                        }
                                    })
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var eventsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Événements du \(formattedDate(selectedDate))")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, 16)
            
            if eventsOnSelectedDay.isEmpty {
                Text("Aucun événement ce jour")
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(eventsOnSelectedDay) { event in
                            NavigationLink(destination:
                                EventDetailsView(eventID: event.id ?? "")
                                    .toolbar(.hidden, for: .tabBar)
                            ) {
                                EventRowView(event: event)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Functions
    
    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: currentMonth).capitalized
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func daysOfWeek() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.shortWeekdaySymbols ?? ["L", "M", "M", "J", "V", "S", "D"]
    }
    
    private func daysInMonth() -> [Date] {
        var days = [Date]()
        let calendar = Calendar.current
        
        // Trouver le premier jour du mois
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))
        else {
            return days
        }
        
        // Déterminer le premier jour à afficher (peut être du mois précédent)
        var startDate = firstDayOfMonth
        let weekday = calendar.component(.weekday, from: startDate)
        let offsetToStartOfWeek = (weekday - calendar.firstWeekday + 7) % 7
        startDate = calendar.date(byAdding: .day, value: -offsetToStartOfWeek, to: startDate) ?? startDate
        
        // Remplir le tableau avec les dates à afficher (42 jours max pour couvrir 6 semaines)
        for dayOffset in 0..<42 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                days.append(day)
                
                // Si nous avons dépassé la fin du mois et rempli la dernière semaine, nous pouvons arrêter
                if dayOffset > 28 && calendar.component(.month, from: day) != calendar.component(.month, from: firstDayOfMonth) 
                    && calendar.component(.weekday, from: day) == calendar.firstWeekday {
                    break
                }
            }
        }
        
        return days
    }
    
    private func hasEvents(on date: Date) -> Bool {
        eventViewModel.filteredEvents.contains { event in
            Calendar.current.isDate(event.date, inSameDayAs: date)
        }
    }
}

// MARK: - Day Cell Component
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isToday ? Color("Red") : (isSelected ? .white : .gray))
                    .frame(width: 35, height: 35)
                    .background(isSelected ? Color.gray.opacity(0.3) : Color.clear)
                    .clipShape(Circle())
                
                if hasEvents {
                    Circle()
                        .fill(Color("Red"))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month) ? 1 : 0.4)
    }
}

#Preview {
    EventCalendarView(eventViewModel: AppDependencyContainer.shared.makeEventViewModel())
        .preferredColorScheme(.dark)
}
