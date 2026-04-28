import Foundation
import CoreLocation

struct UserAddress {
    let street: String
    let city: String
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var locationContinuation: CheckedContinuation<UserAddress, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func getCurrentAddress() async throws -> UserAddress {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            
            let status = manager.authorizationStatus
            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            } else {
                continuation.resume(throwing: NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]))
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    let street = placemark.thoroughfare ?? "Unknown Street"
                    let city = placemark.locality ?? "Unknown City"
                    
                    locationContinuation?.resume(returning: UserAddress(street: street, city: city))
                } else {
                    locationContinuation?.resume(throwing: NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find address"]))
                }
            } catch {
                locationContinuation?.resume(throwing: error)
            }
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
