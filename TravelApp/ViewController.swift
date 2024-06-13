import UIKit

// Screen width.
public var screenWidth: CGFloat {
  return UIScreen.main.bounds.width
}

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
  static let bottomSheetMaxHeightOffset: CGFloat = 26.0
  static let cardContainerAspectRatio: CGFloat = 0.66
  static let pageControlHeight: CGFloat = 28.0
  static let pageIndicatorHeight: CGFloat = 40.0
  static let buttonsViewHeight: CGFloat = 111.0
  
}

class ViewModel {
  
  //weak var appCoordinator : InitialCoordinator!
  //var model: DataModel
  
  var profileName: String = "John Doe"
  var profileDescription: String = "Globe-trotter, fearless adventurer, cultural enthusiast, storyteller"
    
  
  init() {  }
  
//  func goToHomePage(){
//    appCoordinator.backToHomePage()
//  }
  
}


class ViewController: UIViewController {
  
  var visitedCountries = [
         ("Ukraine", "ukraine_flag"),
         ("Mexico", "mexico_flag"),
         ("Chile", "chile_flag"),
         ("France", "france_flag"),
         ("Germany", "germany_flag")
     ]
     
  var bucketListCountries = [
         ("Italy", "italy_flag"),
         ("Peru", "peru_flag"),
         ("United States", "usa_flag"),
         ("Japan", "japan_flag"),
         ("Australia", "australia_flag")
     ]
     
  
  enum SectionType: Int, CaseIterable {
    case summary, shortInfo, pastCountries, futureCountries
  }

  var viewModel : ViewModel!
  var isExpanded: [Bool] = [false, false] // for openning sections
  
  private var currentBottomSheetPosition: BottomSheetPosition = .bottom
  private var bottomSheetMaxHeight: CGFloat = .zero
  private var bottomSheetMinHeight: CGFloat = .zero
  private var currentHeight: CGFloat = .zero
  private var shouldAnimateToTop = false
  private var currentPosition: BottomSheetPosition = .bottom
  
  @IBOutlet weak private var collectionView: UICollectionView?
  @IBOutlet weak private var bottomSheetView: UIView!
  @IBOutlet private var bottomViewHeightConstraint: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView?.delegate = self
    collectionView?.dataSource = self
    collectionView?.registerNib(ShortInfoCell.self)
    collectionView?.registerNib(CountryCell.self)
    collectionView?.registerNib(HeaderCell.self)
    collectionView?.registerNib(ProfileCell.self)
    collectionView?.registerNib(SeeMoreCell.self)

    bottomSheetView.layer.cornerRadius = 16
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(bottomSheetPanGesture))
    gesture.delegate = self
    bottomSheetView.addGestureRecognizer(gesture)
    
    collectionView?.isUserInteractionEnabled = false
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    guard let safeAreaTopInset = window?.safeAreaInsets.top else { return }
    let availableHeight = UIScreen.main.bounds.height - safeAreaTopInset
    bottomSheetMaxHeight = availableHeight - CardViewController.bottomSheetMaxHeightOffset
    let cardOffset = UIScreen.main.bounds.width * CardViewController.cardContainerAspectRatio
    let viewsOffset = CardViewController.pageControlHeight + CardViewController.buttonsViewHeight
    bottomSheetMinHeight = availableHeight - cardOffset - viewsOffset
    currentHeight = bottomSheetMinHeight

  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    guard currentBottomSheetPosition == .bottom else { return }
    updateBottomSheetPosition(position: .current(bottomSheetMinHeight))
  }

  
  @objc private func bottomSheetPanGesture(recognizer: UIPanGestureRecognizer) {
    let translation = recognizer.translation(in: view)
    switch recognizer.state {
    case .changed:
      let newMinHeight = bottomSheetMinHeight + translation.y
      let newMaxHeight = bottomSheetMaxHeight + translation.y
      let newHeight = currentHeight - translation.y
      guard currentHeight >= newMinHeight else {
        updateBottomSheetPosition(position: .bottom)
        return
      }
      guard currentHeight <= newMaxHeight else {
        updateBottomSheetPosition(position: .top)
        return
      }
      updateBottomSheetPosition(position: .current(newHeight))
      shouldAnimateToTop = shouldAnimateToTop(dependOn: newHeight)
    case .ended:
      updateBottomSheetPosition(position: shouldAnimateToTop ? .top : .bottom)
    default:
      break
    }
  }
  
  private func updateBottomSheetPosition(position: BottomSheetPosition) {
    switch position {
    case .top:
      bottomViewHeightConstraint.constant = bottomSheetMaxHeight
      currentBottomSheetPosition = .top
      currentHeight = bottomViewHeightConstraint.constant
      collectionView?.isUserInteractionEnabled = true
      
    case .bottom:
      bottomViewHeightConstraint.constant = bottomSheetMinHeight
      currentBottomSheetPosition = .bottom
      currentHeight = bottomViewHeightConstraint.constant
      collectionView?.isUserInteractionEnabled = false
      collectionView?.scrollToItem(at: IndexPath(row: .zero, section: .zero), at: .top, animated: true)
      UIView.setAnimationsEnabled(true)
    case .current(let currentHeight):
      bottomViewHeightConstraint.constant = currentHeight
    }
  }
  
//  private func updateDependentViews(dependOn newHeight: CGFloat, animated: Bool) {
//    let basePercent = calculateScrollPercent(dependOn: newHeight)
//  }
  
  private func calculateScrollPercent(dependOn newHeight: CGFloat, topInset: CGFloat = .zero) -> CGFloat {
    let maxValue = bottomSheetMaxHeight - topInset
    let minValue = bottomSheetMinHeight
    let currentValue = newHeight
    
    var currentPercent: CGFloat = 1.0
    let diff = maxValue - minValue
    let wightedNewHeight = currentValue - minValue
    currentPercent = (wightedNewHeight * 100) / diff
    return currentPercent
  }
  
  private func shouldAnimateToTop(dependOn newHeight: CGFloat) -> Bool {
    let percent: CGFloat = 30.0
    let diff: CGFloat = bottomSheetMaxHeight - bottomSheetMinHeight
    let offset: CGFloat = diff / (100 / percent)
    var saddlePoint: CGFloat = .zero
    if currentPosition == .bottom {
      saddlePoint = bottomSheetMinHeight + offset
    } else {
      saddlePoint = bottomSheetMaxHeight - offset
    }
    return newHeight > saddlePoint
  }
  
  private func configure<T: BaseCollectionCell>(cellType: T.Type, for indexPath: IndexPath) -> T {
    guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: cellType.identifier, for: indexPath) as? T else {
      fatalError("Error \(cellType)")
    }
    return cell
  }
  
  @IBAction func back(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
  
  func populate() {
    
  }
  
  func addNewCountry(toSection section: Int) {
    let newCountry = ("New Country", "new_country_flag")
    if SectionType(rawValue: section) == .pastCountries {
      visitedCountries.insert(newCountry, at: 0)
    } else {
      bucketListCountries.insert(newCountry, at: 0)
    }
    collectionView?.reloadSections(IndexSet(integer: section))
  }
  
  
  func editProfile() {
          let alertController = UIAlertController(title: "Edit Profile", message: nil, preferredStyle: .alert)
          
          alertController.addTextField { (textField) in
            textField.text = self.viewModel.profileName
          }
          
          alertController.addTextField { (textField) in
            textField.text = self.viewModel.profileDescription
          }
          
          let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
              if let nameField = alertController.textFields?[0], let descriptionField = alertController.textFields?[1] {
                self.viewModel.profileName = nameField.text ?? self.viewModel.profileName
                self.viewModel.profileDescription = descriptionField.text ?? self.viewModel.profileDescription
                self.collectionView?.reloadData()
              }
          }
          
          let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
          
          alertController.addAction(saveAction)
          alertController.addAction(cancelAction)
          
          present(alertController, animated: true, completion: nil)
      }

}

//MARK: - DELEGATE METHODS
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    switch SectionType(rawValue: section) {
    case .pastCountries:
      return isExpanded[0] ? visitedCountries.count + 2 : 4
    case .futureCountries:
      return isExpanded[1] ? bucketListCountries.count + 2 : 4
    default:
      return 1
    }
    
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return SectionType.allCases.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch SectionType(rawValue: indexPath.section)! {
    case .pastCountries, .futureCountries:
//      if indexPath.item == 0 {
//        let cell = self.configure(cellType: HeaderCell.self, for: indexPath)
//        cell.titleLabel.text = SectionType(rawValue: indexPath.section) == .pastCountries ? "I've been to" : "My bucket list"
//        cell.addButton.setTitle("Add country", for: .normal)
//        return cell
//      } else {
//        let cell = self.configure(cellType: CountryCell.self, for: indexPath)
//        let country = SectionType(rawValue: indexPath.section) == .pastCountries ? visitedCountries[indexPath.item - 1] : bucketListCountries[indexPath.item - 1]
//        
//        cell.countryNameLabel.text = country.0
//        cell.flagImageView.image = UIImage(named: country.1)
//        
//        return cell
//      }
//      
      
      if indexPath.item == 0 {
        let cell = self.configure(cellType: HeaderCell.self, for: indexPath)
        cell.titleLabel.text = SectionType(rawValue: indexPath.section) == .pastCountries ? "I've been to" : "My bucket list"
        cell.addButton.setTitle("Add country", for: .normal)
        return cell
      } else if SectionType(rawValue: indexPath.section) == .pastCountries {
        if !isExpanded[0] && indexPath.item == 3 || isExpanded[0] && indexPath.item == visitedCountries.count + 1 {
          let cell = self.configure(cellType: SeeMoreCell.self, for: indexPath)
          cell.seeMoreLabel.text = isExpanded[0] ? "See less" : "See 5 more"
          return cell
        }
      } else {
        if (!isExpanded[1] && indexPath.item == 3) || (isExpanded[1] && indexPath.item == bucketListCountries.count + 1) {
          let cell = self.configure(cellType: SeeMoreCell.self, for: indexPath)
          cell.seeMoreLabel.text = isExpanded[1] ? "See less" : "See 5 more"
          return cell
        }
      }
      
      let cell = self.configure(cellType: CountryCell.self, for: indexPath)
      let country = SectionType(rawValue: indexPath.section) == .pastCountries ? visitedCountries[indexPath.item - 1] : bucketListCountries[indexPath.item - 1]
      
      cell.countryNameLabel.text = country.0
      cell.flagImageView.image = UIImage(named: country.1)
      
      return cell
    case .summary:
      let cell = self.configure(cellType: ProfileCell.self, for: indexPath)
      cell.nameLabel.text = viewModel.profileName
      cell.descriptionLabel.text = viewModel.profileDescription
      cell.editButtonAction = {
        self.editProfile()
      }
      return cell
    case .shortInfo:
      let cell = self.configure(cellType: ShortInfoCell.self, for: indexPath)
      return cell
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = screenWidth
    switch SectionType(rawValue: indexPath.section)! {
    case .futureCountries, .pastCountries:
      return CGSize(width: collectionView.frame.width - 20, height: 50)
    default:
      return CGSize(
        width: width,
        height: 81
      )
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch SectionType(rawValue: indexPath.section)! {
    case .pastCountries, .futureCountries:
      if indexPath.item == 0 {
        addNewCountry(toSection: indexPath.section)
      } else if SectionType(rawValue: indexPath.section) == .pastCountries && (!isExpanded[0] && indexPath.item == 3 || isExpanded[0] && indexPath.item == visitedCountries.count + 1) {
        isExpanded[0].toggle()
        collectionView.reloadSections(IndexSet(integer: indexPath.section))
      } else if SectionType(rawValue: indexPath.section) == .futureCountries && (!isExpanded[1] && indexPath.item == 3 || isExpanded[1] && indexPath.item == bucketListCountries.count + 1) {
        isExpanded[1].toggle()
        collectionView.reloadSections(IndexSet(integer: indexPath.section))

      }
    default:
      break
    }
  }
  
}

extension ViewController: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if otherGestureRecognizer.view == collectionView,
       currentBottomSheetPosition == .top {
      return collectionView?.contentOffset.y ?? 0 <= .zero
    }
    return false
  }
}

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

extension UICollectionView {
  func registerNib<T: UICollectionViewCell>(_ cellType: T.Type){
    let nibName = String(describing: cellType)
    let nib = UINib(nibName: nibName, bundle: nil)
    register(nib, forCellWithReuseIdentifier: nibName)
  }
}
