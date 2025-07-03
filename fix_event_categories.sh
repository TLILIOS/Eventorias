#!/bin/bash

# Correction pour EventServiceTests.swift
echo "Correction de EventServiceTests.swift..."
# Remplacer toutes les occurrences de category: "Musique" par category: .music
sed -i '' 's/category: "Musique"/category: .music/g' EventoriasTests/Services/EventServiceTests.swift

# Remplacer toutes les occurrences de category: "Art" par category: .art
sed -i '' 's/category: "Art"/category: .art/g' EventoriasTests/Services/EventServiceTests.swift

# Remplacer toutes les occurrences de category: "Test" par category: .other
sed -i '' 's/category: "Test"/category: .other/g' EventoriasTests/Services/EventServiceTests.swift

# Remplacer le paramètre de la méthode filterEventsByCategory
sed -i '' 's/filterEventsByCategory(category: "Musique")/filterEventsByCategory(category: .music)/g' EventoriasTests/Services/EventServiceTests.swift

# Correction pour EventViewModelTests.swift
echo "Correction de EventViewModelTests.swift..."
# Remplacer toutes les occurrences de category: "Test" par category: .other
sed -i '' 's/category: "Test"/category: .other/g' EventoriasTests/ViewModels/EventViewModelTests.swift

# Vérifier que les fichiers contiennent bien les modifications
echo "\nVérification des modifications dans EventServiceTests.swift :"
grep -n "category:" EventoriasTests/Services/EventServiceTests.swift
grep -n "filterEventsByCategory" EventoriasTests/Services/EventServiceTests.swift

echo "\nVérification des modifications dans EventViewModelTests.swift :"
grep -n "category:" EventoriasTests/ViewModels/EventViewModelTests.swift
