import UIKit

open class BaseCollectionCell: UICollectionViewCell {
  static var identifier: String { return String(describing: self) }
  static var nib: UINib { return UINib(nibName: identifier, bundle: nil) }

  public func setupLayout() {}

  public func setup() {}

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayout()
    setup()
  }

  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    setupLayout()
    setup()
  }
}
