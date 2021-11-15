
import Foundation

class WarsawVehicleDataObtainer {
    
    private func doOnMainThread(resultHandler: @escaping () -> ()) {
        DispatchQueue.main.async {
            resultHandler()
        }
    }
    
    func getVehicles(resultHandler: @escaping (_ success: Bool, _ networkError: Bool, _ data: [VehicleData]?) -> ()) {
        var request = URLRequest(url: URL(string: "https://gdzietentramwaj.herokuapp.com/vehicles/list")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil { // Handle error…
                print("Error occurred!")
                self.doOnMainThread {
                    resultHandler(false, true, nil)
                }
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                self.doOnMainThread {
                    resultHandler(false, false, nil)
                }
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                self.doOnMainThread {
                    resultHandler(false, false, nil)
                }
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                self.doOnMainThread {
                    resultHandler(false, false, nil)
                }
                return
            }
            
            guard let parsedCheckedResult = parsedResult else {
                print("Parsing failed")
                self.doOnMainThread {
                    resultHandler(false, false, nil)
                }
                return
            }
            guard let resultsData = parsedCheckedResult["result"] as? [[String: AnyObject]] else {
                print("Results object not found")
                self.doOnMainThread {
                    resultHandler(false, false, nil)
                }
                return
            }
            
            var vehicles: [VehicleData] = []
            for item in resultsData {
                vehicles.append(VehicleData(dict: item))
            }
            
            self.doOnMainThread {
                resultHandler(true, false, vehicles)
            }
        }
        task.resume()
    }
}
