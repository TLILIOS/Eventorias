//
// ImageUploadState.swift
// Eventorias
//
// Created on 02/07/2025.
//

import Foundation

/// État du processus d'upload d'une image
enum ImageUploadState: Equatable {
    case ready
    case uploading(progress: Double)
    case success(url: String)
    case failure(error: String)
    
    var isUploading: Bool {
        switch self {
        case .uploading: return true
        default: return false
        }
    }
    
    var progressValue: Double {
        switch self {
        case .uploading(let progress): return progress
        case .success: return 1.0
        default: return 0.0
        }
    }
}
