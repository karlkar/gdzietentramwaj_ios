import Foundation
import CoreLocation
import UIKit

struct VehicleData {
    let id: String
    let position: CLLocationCoordinate2D
    let line: String
    let isTram: Bool
    let brigade: String?
    let prevPosition: CLLocationCoordinate2D?
    
    init(dict: [String: AnyObject]) {
        self.id = dict["id"] as! String
        let curPosition = dict["position"] as! [String: AnyObject]
        self.position = CLLocationCoordinate2D(latitude: Double(truncating: curPosition["latitude"] as! NSNumber), longitude: Double(truncating: curPosition["longitude"] as! NSNumber))
        self.line = dict["line"] as! String
        self.isTram = dict["isTram"] as! Bool
        self.brigade = dict["brigade"] as? String
        let prevPosition = dict["prevPosition"] as? [String: AnyObject]
        if prevPosition == nil {
            self.prevPosition = nil
        } else {
            self.prevPosition = CLLocationCoordinate2D(latitude: Double(truncating: prevPosition!["latitude"] as! NSNumber), longitude: Double(truncating: prevPosition!["longitude"] as! NSNumber))
        }
    }
    
    
}
