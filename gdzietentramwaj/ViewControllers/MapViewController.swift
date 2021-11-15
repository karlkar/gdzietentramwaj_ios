import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet var reloadButton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    
    var dataController: DataController!
    
    private let activityIndicator = UIActivityIndicatorView()
    
    private var lastFetchedVehicles: [VehicleAnnotation] = []
    
    private var timer: Timer? = nil
    private var favoritesEnabled = false
    
    private let WARSAW_LAT = 52.231841
    private let WARSAW_LNG = 21.005940
    
    private let warsawVehicleObtainer = WarsawVehicleDataObtainer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.color = .gray
        
        map.delegate = self
        
        setupInitialPosition()
    }
    
    private func setupInitialPosition() {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: WARSAW_LAT, longitude: WARSAW_LNG), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadAndRescheduleTimer()
    }
    
    private func reloadAndRescheduleTimer() {
        timer?.invalidate()
        refreshVehicleData()
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(MapViewController.refreshVehicleData), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    
    @objc func refreshVehicleData() {
        startBarButtonIndicator()
        warsawVehicleObtainer.getVehicles(resultHandler: { success, networkError, data in
            if !success {
                self.stopBarButtonIndicator()
                if networkError {
                    self.showToast(message: "Network error!")
                }else{
                    self.showToast(message: "Error occurred!")
                }
                return
            }
            
            guard let data = data else {
                print("Null data returned in success response!")
                self.stopBarButtonIndicator()
                return
            }
            
            self.storeUnknownLines(data: data)
            self.updateAnnotations(data: data)
            self.stopBarButtonIndicator()
        })
    }
    
    private func storeUnknownLines(data: [VehicleData]) {
        DispatchQueue.main.async {
            Set(data.map { $0.line }).filter { !self.isKnownLine($0) }.forEach { self.storeLine($0)}
            try? self.dataController.viewContext.save()
        }
    }
    
    private func isKnownLine(_ line: String) -> Bool {
        let request = FavVehicle.fetchRequest()
        request.predicate = NSPredicate(format: "line == %@", line)
        let result = (try? dataController.viewContext.fetch(request)) ?? []
        return !result.isEmpty
    }
    
    private func storeLine(_ line: String) {
        let favorite = FavVehicle(context: dataController.viewContext)
        favorite.line = line
        favorite.favorite = false
    }
    
    private func updateAnnotations(data: [VehicleData]) {
        lastFetchedVehicles = data.map { VehicleAnnotation(vehicleData: $0) }
        updateAnnotationsVisibility(lastFetchedVehicles)
    }
    
    private func getFavoriteLines() -> [String] {
        let request = FavVehicle.fetchRequest()
        request.predicate = NSPredicate(format: "favorite == true")
        return (try? dataController.viewContext.fetch(request))?.map { $0.line! } ?? []
    }
    
    private func updateAnnotationsVisibility(_ annotations: [MKAnnotation]) {
        if !(annotations is [VehicleAnnotation]) { return }
        
        let favoriteLines: [String] = getFavoriteLines()
        let filteredAnnotations = annotations.filter { !favoritesEnabled || favoriteLines.contains($0.title!!) }
        
        map.removeAnnotations(map.annotations)
        map.addAnnotations(filteredAnnotations)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let isTram = (annotation as? VehicleAnnotation)?.isTram ?? false
        
        let reuseID: String
        if isTram {
            reuseID = "tram_pin"
        } else {
            reuseID = "bus_pin"
        }
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        if pin == nil {
            pin = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            
            pin?.image = prepareUiImage(isTram)
            pin?.isEnabled = true
            pin?.canShowCallout = true
            
            let label = prepareUiLabel(isTram)
            pin?.addSubview(label)
        } else {
            pin?.annotation = annotation
        }
        
        for subview in pin!.subviews {
            (subview as? UILabel)?.text = annotation.title ?? ""
        }
        return pin
    }
    
    private func prepareUiImage(_ isTram: Bool) -> UIImage? {
        let pinImage: UIImage?
        if isTram {
            pinImage = UIImage(named: "new_tram")
        } else {
            pinImage = UIImage(named: "new_bus")
        }
        let size = CGSize(width: 55, height: 55)
        UIGraphicsBeginImageContext(size)
        pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func prepareUiLabel(_ isTram: Bool) -> UILabel {
        let label: UILabel
        if isTram {
            label = UILabel(frame: CGRect(x: 10, y: 13, width: 35, height: 25))
        } else {
            label = UILabel(frame: CGRect(x: 10, y: 7, width: 35, height: 25))
        }
        label.textColor = .black
        label.textAlignment = .center
        label.font = label.font.withSize(16)
        return label
    }
    
    func startBarButtonIndicator() {
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setLeftBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
    }
    
    func stopBarButtonIndicator() {
        activityIndicator.stopAnimating()
        navigationItem.setLeftBarButton(reloadButton, animated: true)
    }
    
    @IBAction func reloadButtonAction(_ sender: Any) {
        reloadAndRescheduleTimer()
    }
    
    @IBAction func favoriteButtonAction(_ sender: Any) {
        if favoritesEnabled {
            favoriteButton.image = UIImage(systemName: "star")
        } else {
            favoriteButton.image = UIImage(systemName: "star.fill")
        }
        
        favoritesEnabled = !favoritesEnabled
        updateAnnotationsVisibility(lastFetchedVehicles)
    }
    
    @IBAction func settingsButtonAction(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "FavoritesViewController") as! FavoritesViewController
        vc.dataController = self.dataController
        navigationController?.pushViewController(vc, animated: true)
    }
}
