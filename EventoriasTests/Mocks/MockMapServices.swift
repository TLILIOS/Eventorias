//
//  MockMapServices.swift
//  EventoriasTests
//
//  Created on 27/06/2025
//

import Foundation
import CoreLocation
@testable import Eventorias

// MARK: - Mock pour PlacemarkProtocol

class MockPlacemark: PlacemarkProtocol {
    var name: String?
    var thoroughfare: String?
    var subThoroughfare: String?
    var locality: String?
    var subLocality: String?
    var administrativeArea: String?
    var subAdministrativeArea: String?
    var postalCode: String?
    var country: String?
    var isoCountryCode: String?
    var location: CLLocation?
    
    init(
        name: String? = nil,
        thoroughfare: String? = nil,
        subThoroughfare: String? = nil,
        locality: String? = nil,
        subLocality: String? = nil,
        administrativeArea: String? = nil,
        subAdministrativeArea: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        isoCountryCode: String? = nil,
        location: CLLocation? = nil
    ) {
        self.name = name
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.subAdministrativeArea = subAdministrativeArea
        self.postalCode = postalCode
        self.country = country
        self.isoCountryCode = isoCountryCode
        self.location = location
    }
}

// MARK: - Mock pour GeocodingService

class MockGeocodingService: GeocodingService {
    // Variables pour suivre les appels de méthodes
    var geocodeAddressCalled = false
    var cancelGeocodingCalled = false
    
    // Variables pour contrôler le comportement simulé
    var shouldThrowError = false
    var mockError: Error = NSError(domain: "MockGeocodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée de géocodage"])
    var mockPlacemarks: [MockPlacemark] = []
    
    func geocodeAddress(_ address: String) async throws -> [PlacemarkProtocol] {
        geocodeAddressCalled = true
        if shouldThrowError {
            throw mockError
        }
        return mockPlacemarks
    }
    
    func cancelGeocoding() {
        cancelGeocodingCalled = true
    }
}

// MARK: - Mock pour MapNetworkService

class MockMapNetworkService: MapNetworkService {
    // Variables pour suivre les appels de méthodes
    var validateMapImageURLCalled = false
    
    // Variables pour contrôler le comportement simulé
    var shouldSucceed = true
    var mockError: Error = NSError(domain: "MockMapNetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée de validation"])
    
    func validateMapImageURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        validateMapImageURLCalled = true
        
        if shouldSucceed {
            completion(.success(()))
        } else {
            completion(.failure(mockError))
        }
    }
}

// MARK: - Mock pour ConfigurationService

class MockConfigurationService: ConfigurationService {
    var googleMapsAPIKey: String = "mock-api-key"
}
