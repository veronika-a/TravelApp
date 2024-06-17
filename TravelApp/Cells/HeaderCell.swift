import UIKit

class HeaderCell: BaseCollectionCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var addButton: UIButton!
  
  var addButtonAction: (() -> Void)?
  
  @IBAction func addButtonTapped(_ sender: UIButton) {
    addButtonAction?()
  }
  
  func populate(titleText: String) {
    addButton.roundCorners(radius: 16)
    titleLabel.text = titleText
  }
}
