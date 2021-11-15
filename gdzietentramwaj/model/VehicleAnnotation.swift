
import MapKit

class VehicleAnnotation : NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    
    let title: String?
    let subtitle: String?
    let isTram: Bool
    
    init(vehicleData: VehicleData) {
        title = vehicleData.line
        subtitle = vehicleData.brigade
        coordinate = vehicleData.position
        isTram = vehicleData.isTram
    }
}
