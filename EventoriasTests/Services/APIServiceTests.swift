//
//  APIServiceTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
@testable import Eventorias
@MainActor
final class APIServiceTests: XCTestCase {
    
    var mockAPIService: MockAPIService!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
    }
    
    override func tearDown() {
        mockAPIService = nil
        super.tearDown()
    }
    
    // MARK: - Tests de requêtes génériques
    
    func testRequestSuccess() async {
        // Arrange
        struct TestResponse: Codable, Equatable {
            let name: String
            let age: Int
        }
        
        let testResponse = TestResponse(name: "Test", age: 30)
        mockAPIService.setResponseForTests(testResponse)
        mockAPIService.shouldThrowError = false
        
        let testURL = URL(string: "https://api.example.com/test")!
        
        // Act
        do {
            let result: TestResponse = try await mockAPIService.request(
                url: testURL,
                method: .get,
                headers: nil,
                parameters: nil,
                responseType: TestResponse.self
            )
            
            // Assert
            XCTAssertTrue(mockAPIService.requestCalled, "La méthode request n'a pas été appelée")
            XCTAssertEqual(result, testResponse, "La réponse reçue ne correspond pas à la réponse attendue")
        } catch {
            XCTFail("La requête a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testRequestFailure() async {
        // Arrange
        struct TestResponse: Codable {
            let name: String
        }
        
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = .networkError(NSError(domain: "TestError", code: 1))
        let testURL = URL(string: "https://api.example.com/test")!
        
        // Act & Assert
        do {
            let _: TestResponse = try await mockAPIService.request(
                url: testURL,
                method: .get,
                headers: nil,
                parameters: nil,
                responseType: TestResponse.self
            )
            XCTFail("La requête a réussi alors qu'elle devrait échouer")
        } catch let error as APIError {
            XCTAssertTrue(mockAPIService.requestCalled, "La méthode request n'a pas été appelée")
            if case .networkError = error {
                // L'erreur attendue
            } else {
                XCTFail("Type d'erreur inattendu: \(error)")
            }
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
    
    func testRequestDecodingError() async {
        // Arrange
        struct TestResponse: Codable {
            let name: String
            let requiredField: String
        }
        
        // Données JSON incorrectes (manque requiredField)
        let jsonString = """
        {
            "name": "Test"
        }
        """
        mockAPIService.dataToReturn = jsonString.data(using: .utf8)!
        mockAPIService.shouldThrowError = false
        let testURL = URL(string: "https://api.example.com/test")!
        
        // Act & Assert
        do {
            let _: TestResponse = try await mockAPIService.request(
                url: testURL,
                method: .get,
                headers: nil,
                parameters: nil,
                responseType: TestResponse.self
            )
            XCTFail("Le décodage a réussi alors qu'il devrait échouer")
        } catch let error as APIError {
            XCTAssertTrue(mockAPIService.requestCalled, "La méthode request n'a pas été appelée")
            if case .decodingError = error {
                // L'erreur attendue
            } else {
                XCTFail("Type d'erreur inattendu: \(error)")
            }
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
    
    // MARK: - Tests de requêtes de données brutes
    
    func testRequestDataSuccess() async {
        // Arrange
        let expectedData = "Test data".data(using: .utf8)!
        mockAPIService.dataToReturn = expectedData
        mockAPIService.shouldThrowError = false
        let testURL = URL(string: "https://api.example.com/test")!
        
        // Act
        do {
            let result = try await mockAPIService.requestData(
                url: testURL,
                method: .post,
                headers: ["Content-Type": "application/json"],
                parameters: ["key": "value"]
            )
            
            // Assert
            XCTAssertTrue(mockAPIService.requestDataCalled, "La méthode requestData n'a pas été appelée")
            XCTAssertEqual(result, expectedData, "Les données reçues ne correspondent pas aux données attendues")
        } catch {
            XCTFail("La requête a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testRequestDataFailure() async {
        // Arrange
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = .serverError(500, nil)
        let testURL = URL(string: "https://api.example.com/test")!
        
        // Act & Assert
        do {
            _ = try await mockAPIService.requestData(
                url: testURL,
                method: .post,
                headers: nil,
                parameters: nil
            )
            XCTFail("La requête a réussi alors qu'elle devrait échouer")
        } catch let error as APIError {
            XCTAssertTrue(mockAPIService.requestDataCalled, "La méthode requestData n'a pas été appelée")
            if case .serverError(let code, _) = error {
                XCTAssertEqual(code, 500, "Le code d'erreur ne correspond pas")
            } else {
                XCTFail("Type d'erreur inattendu: \(error)")
            }
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
    
    // MARK: - Tests d'upload de fichier
    
    func testUploadFileSuccess() async {
        // Arrange
        let expectedData = "Response data".data(using: .utf8)!
        mockAPIService.dataToReturn = expectedData
        mockAPIService.shouldThrowError = false
        let testURL = URL(string: "https://api.example.com/upload")!
        let testFileData = "File content".data(using: .utf8)!
        
        // Act
        do {
            let result = try await mockAPIService.uploadFile(
                url: testURL,
                method: .post,
                headers: nil,
                parameters: ["description": "Test file"],
                fileData: testFileData,
                fileName: "test.txt",
                mimeType: "text/plain",
                fileFieldName: "file"
            )
            
            // Assert
            XCTAssertTrue(mockAPIService.uploadFileCalled, "La méthode uploadFile n'a pas été appelée")
            XCTAssertEqual(result, expectedData, "Les données reçues ne correspondent pas aux données attendues")
        } catch {
            XCTFail("L'upload a échoué alors qu'il devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testUploadFileFailure() async {
        // Arrange
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = .authenticationError
        let testURL = URL(string: "https://api.example.com/upload")!
        let testFileData = "File content".data(using: .utf8)!
        
        // Act & Assert
        do {
            _ = try await mockAPIService.uploadFile(
                url: testURL,
                method: .post,
                headers: nil,
                parameters: nil,
                fileData: testFileData,
                fileName: "test.txt",
                mimeType: "text/plain",
                fileFieldName: "file"
            )
            XCTFail("L'upload a réussi alors qu'il devrait échouer")
        } catch let error as APIError {
            XCTAssertTrue(mockAPIService.uploadFileCalled, "La méthode uploadFile n'a pas été appelée")
            if case .authenticationError = error {
                // L'erreur attendue
            } else {
                XCTFail("Type d'erreur inattendu: \(error)")
            }
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
    
    // MARK: - Tests de construction d'URL
    
    func testBuildURLSuccess() {
        // Arrange
        mockAPIService.shouldThrowError = false
        let baseURL = URL(string: "https://api.example.com")!
        let queryItems = [
            URLQueryItem(name: "param1", value: "value1"),
            URLQueryItem(name: "param2", value: "value2")
        ]
        
        // Act
        do {
            let result = try mockAPIService.buildURL(baseURL: baseURL, queryItems: queryItems)
            
            // Assert
            XCTAssertTrue(mockAPIService.buildURLCalled, "La méthode buildURL n'a pas été appelée")
            XCTAssertTrue(result.absoluteString.contains("param1=value1"), "L'URL ne contient pas le premier paramètre")
            XCTAssertTrue(result.absoluteString.contains("param2=value2"), "L'URL ne contient pas le deuxième paramètre")
        } catch {
            XCTFail("La construction de l'URL a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testBuildURLFailure() {
        // Arrange
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = .requestError("URL invalide")
        let baseURL = URL(string: "https://api.example.com")!
        
        // Act & Assert
        do {
            _ = try mockAPIService.buildURL(baseURL: baseURL, queryItems: nil)
            XCTFail("La construction de l'URL a réussi alors qu'elle devrait échouer")
        } catch let error as APIError {
            XCTAssertTrue(mockAPIService.buildURLCalled, "La méthode buildURL n'a pas été appelée")
            if case .requestError = error {
                // L'erreur attendue
            } else {
                XCTFail("Type d'erreur inattendu: \(error)")
            }
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
}
