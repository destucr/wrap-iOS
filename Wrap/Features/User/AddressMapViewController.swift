import UIKit
import MapKit
import SnapKit
import CoreLocation

final class AddressMapViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var currentAddress: String = "Pilih lokasi..."
    private var currentPostalCode: String = ""
    
    var onSave: ((CLLocationCoordinate2D, String, String) -> Void)?
    
    // UI Elements
    private let pinImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        iv.tintColor = Brand.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let addressCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 10
        return view
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Mengambil alamat..."
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    private let locateButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "location.fill")
        config.baseBackgroundColor = .systemBackground
        config.baseForegroundColor = Brand.primary
        config.cornerStyle = .capsule
        button.configuration = config
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Konfirmasi Lokasi", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
    }
    
    private func setupUI() {
        title = "Pilih Alamat"
        view.backgroundColor = .systemBackground
        
        view.addSubview(mapView)
        view.addSubview(pinImageView)
        view.addSubview(addressCard)
        addressCard.addSubview(addressLabel)
        view.addSubview(locateButton)
        view.addSubview(saveButton)
        
        mapView.delegate = self
        mapView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        pinImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        addressCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(60)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        locateButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(saveButton.snp.top).offset(-20)
            make.width.height.equalTo(50)
        }
        
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }
        
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        locateButton.addTarget(self, action: #selector(handleLocateMe), for: .touchUpInside)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        handleLocateMe()
    }
    
    @objc private func handleLocateMe() {
        locationManager.startUpdatingLocation()
    }
    
    @objc private func handleSave() {
        let center = mapView.centerCoordinate
        onSave?(center, currentAddress, currentPostalCode)
        navigationController?.popViewController(animated: true)
    }
    
    private func updateAddress(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            let name = placemark.name ?? ""
            let street = placemark.thoroughfare ?? ""
            let subLocality = placemark.subLocality ?? ""
            let city = placemark.locality ?? ""
            let postalCode = placemark.postalCode ?? ""
            
            let fullAddress = [name, street, subLocality, city]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            
            self.currentAddress = fullAddress
            self.currentPostalCode = postalCode
            DispatchQueue.main.async {
                self.addressLabel.text = fullAddress
            }
        }
    }
}

extension AddressMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        updateAddress(for: mapView.centerCoordinate)
    }
}

extension AddressMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error)")
    }
}
