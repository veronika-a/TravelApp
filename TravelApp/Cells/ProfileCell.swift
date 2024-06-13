import UIKit

class ProfileCell: BaseCollectionCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var editButtonAction: (() -> Void)?
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        editButtonAction?()
    }
}
