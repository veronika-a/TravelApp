import UIKit

enum BottomSheetPosition: Equatable {
  
  case top
  case bottom
  case current(CGFloat)
  
}

enum AnimationTime: TimeInterval {
  
  case slowest = 1.0
  case extremelySlow = 0.9
  case verySlow = 0.8
  case quiteSlow = 0.7
  case slow = 0.6
  case `default` = 0.5
  case fast = 0.4
  case quiteFast = 0.3
  case veryFast = 0.2
  case extremelyFast = 0.1
  case fastest = 0.0
  
}

struct CardViewController {
  
  static let bottomSheetMaxHeightOffset: CGFloat = 72.0
  static let cardContainerAspectRatio: CGFloat = 0.66
  static let pageControlHeight: CGFloat = 28.0
  static let pageIndicatorHeight: CGFloat = 40.0
  static let buttonsViewHeight: CGFloat = 111.0
  
}

extension UICollectionView {
  
  func registerNib<T: UICollectionViewCell>(_ cellType: T.Type){
    let nibName = String(describing: cellType)
    let nib = UINib(nibName: nibName, bundle: nil)
    register(nib, forCellWithReuseIdentifier: nibName)
  }
  
}

extension UIButton {
  
  func roundCorners(radius: CGFloat) {
    self.layer.cornerRadius = radius
    self.clipsToBounds = true
  }
  
}
