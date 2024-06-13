import UIKit

class ShortInfoCell: BaseCollectionCell {
  
  @IBOutlet weak var countriesLabel: UILabel!
  @IBOutlet weak var worldProcentLabel: UILabel!

 // static var reuseId: String = "ShortInfoCell"
  
  func populate(countries: Int, worldProcent: Int) {
    countriesLabel.text = "\(countries)"
    worldProcentLabel.text = "\(worldProcent)%"

  }
}

