import UIKit
import CoreData

class FavoritesViewController : UICollectionViewController {
    
    var dataController: DataController!
    
    private var knownLines: [FavVehicle]!
    private let reuseIdentifier = "FavVehicleCellView"
    
    override func viewWillAppear(_ animated: Bool) {
        var temp = getAllKnownLines()
        temp.sort {
            ($0.line ?? "").localizedStandardCompare($1.line ?? "") == .orderedAscending
        }
        knownLines = temp
        collectionView.reloadData()
    }
    
    private func getAllKnownLines() -> [FavVehicle] {
        let request = FavVehicle.fetchRequest()
        return (try? dataController.viewContext.fetch(request)) ?? []
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return knownLines.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FavVehicleCellView
        
        let item = knownLines[indexPath.row]
        cell.vehicleButton.text = item.line
        cell.vehicleButton.backgroundColor = item.favorite ? UIColor.yellow : UIColor.white
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentState = knownLines[indexPath.row].favorite
        knownLines[indexPath.row].favorite = !currentState
        try? dataController.viewContext.save()
        collectionView.reloadData()
    }
}
