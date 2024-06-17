import UIKit

class CountryCell: BaseCollectionCell {
  @IBOutlet weak var flagImageLabel: UILabel!
  @IBOutlet weak var countryNameLabel: UILabel!
  
  func populate(countryName: String, flag: String) {
    countryNameLabel.text = countryName
    flagImageLabel.text = flag
  }
}
