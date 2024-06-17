import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
  
  enum SectionType: Int, CaseIterable {
    case summary, shortInfo, pastCountries, futureCountries
  }
  
  @IBOutlet weak var mapView: MKMapView!
  var annotations: [String: MKAnnotation] = [:]
  let geocoder = CLGeocoder()
  
  var viewModel : ViewModel!
  var isExpanded: [Bool] = [false, false] // for opening sections
  
  private var currentBottomSheetPosition: BottomSheetPosition = .bottom
  private var bottomSheetMaxHeight: CGFloat = .zero
  private var bottomSheetMinHeight: CGFloat = .zero
  private var currentHeight: CGFloat = .zero
  private var shouldAnimateToTop = false
  private var currentPosition: BottomSheetPosition = .bottom
  
  @IBOutlet weak private var collectionView: UICollectionView?
  @IBOutlet weak private var backButton: UIButton?
  @IBOutlet weak private var bottomSheetView: UIView?
  @IBOutlet weak private var bottomViewHeightConstraint: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mapView.delegate = self
    
    // Setting the initial view of the map as a globe
    mapView.mapType = .hybridFlyover
    mapView.camera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), fromDistance: 20000000, pitch: 0, heading: 0)
    
    // Adding a long press recognizer to set markers
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    mapView.addGestureRecognizer(longPressRecognizer)
    
    collectionView?.delegate = self
    collectionView?.dataSource = self
    collectionView?.registerNib(ShortInfoCell.self)
    collectionView?.registerNib(CountryCell.self)
    collectionView?.registerNib(HeaderCell.self)
    collectionView?.registerNib(ProfileCell.self)
    collectionView?.registerNib(SeeMoreCell.self)
    
    bottomSheetView?.layer.cornerRadius = 16
    backButton?.roundCorners(radius: 16)
    
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(bottomSheetPanGesture))
    gesture.delegate = self
    bottomSheetView?.addGestureRecognizer(gesture)
    
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
    
    // Add annotations for visited and bucket list countries
    addAnnotations(for: viewModel.visitedCountries)
    addAnnotations(for: viewModel.bucketListCountries, check: false)
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
  
  private func calculateScrollPercent(dependOn newHeight: CGFloat, topInset: CGFloat = .zero) -> CGFloat {
    let maxValue = bottomSheetMaxHeight - topInset
    let minValue = bottomSheetMinHeight
    let currentValue = newHeight
    
    var currentPercent: CGFloat = 1.0
    let diff = maxValue - minValue
    let weightedNewHeight = currentValue - minValue
    currentPercent = (weightedNewHeight * 100) / diff
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
  
  func addNewCountry(name: String, flag: String, toSection section: Int) {
    let newCountry = (name, flag)
    if SectionType(rawValue: section) == .pastCountries {
      if viewModel.visitedCountries.first(where: {$0.0 == newCountry.0}) == nil {
        viewModel.visitedCountries.insert(newCountry, at: 0)
        addAnnotations(for: [newCountry], check: true)
        print("Visited Country added: \(newCountry)")
      } else {
        showAlertForDuplicateCountry(name: newCountry.0)
      }
    } else {
      if viewModel.bucketListCountries.first(where: {$0.0 == newCountry.0}) == nil {
        viewModel.bucketListCountries.insert(newCountry, at: 0)
        addAnnotations(for: [newCountry], check: false)
        print("Bucket Country added: \(newCountry)")
      } else {
        showAlertForDuplicateCountry(name: newCountry.0)
      }
    }
    collectionView?.reloadSections(IndexSet(integer: section))
  }
  
  func removeCountry(name: String, fromSection section: Int) {
    let sectionType = SectionType(rawValue: section)!
    viewModel.removeCountry(name: name, fromSection: sectionType)
    removeAnnotation(for: name)
    collectionView?.reloadSections(IndexSet(integer: section))
  }

  func removeAnnotation(for country: String) {
    if let annotation = annotations[country] {
      mapView.removeAnnotation(annotation)
      annotations.removeValue(forKey: country)
    }
  }
  
  func showAlertForDuplicateCountry(name: String) {
     let alert = UIAlertController(title: "Duplicate Country", message: "The country \(name) is already in the list.", preferredStyle: .alert)
     let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
     alert.addAction(okAction)
     present(alert, animated: true, completion: nil)
   }
  
  func showDeleteConfirmationAlert(for country: String, inSection section: Int) {
    let alertController = UIAlertController(title: "Delete Country", message: "Are you sure you want to delete \(country) from the list?", preferredStyle: .alert)
    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
      self.removeCountry(name: country, fromSection: section)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true, completion: nil)
  }
  
  func showAddCountryAlert(forSection section: Int) {
    let alertController = UIAlertController(title: "Add New Country", message: "\n\n\n\n\n\n", preferredStyle: .alert)
    
    let pickerView = UIPickerView(frame: CGRect(x: 0, y: 50, width: 270, height: 140))
    pickerView.dataSource = self
    pickerView.delegate = self
    
    alertController.view.addSubview(pickerView)
    
    let addAction = UIAlertAction(title: "Add", style: .default) { _ in
      let selectedRow = pickerView.selectedRow(inComponent: 0)
      let selectedCountry = Countries.allCountries[selectedRow]
      self.addNewCountry(name: selectedCountry.0, flag: selectedCountry.1, toSection: section)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    alertController.addAction(addAction)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true, completion: nil)
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

// MARK: - DELEGATE METHODS
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    switch SectionType(rawValue: section) {
    case .pastCountries:
      return isExpanded[0] ? viewModel.visitedCountries.count + 2 : 4
    case .futureCountries:
      return isExpanded[1] ? viewModel.bucketListCountries.count + 2 : 4
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
      if indexPath.item == 0 {
        let cell = self.configure(cellType: HeaderCell.self, for: indexPath)
        cell.populate(
          titleText: SectionType(rawValue: indexPath.section) == .pastCountries ? "I've been to" : "My bucket list")
        cell.addButtonAction = {
          self.showAddCountryAlert(forSection: indexPath.section)
        }
        return cell
      } else if SectionType(rawValue: indexPath.section) == .pastCountries {
        if !isExpanded[0] && indexPath.item == 3 || isExpanded[0] && indexPath.item == viewModel.visitedCountries.count + 1 {
          let cell = self.configure(cellType: SeeMoreCell.self, for: indexPath)
          cell.seeMoreLabel.text = isExpanded[0] ? "See less" : "See \(viewModel.visitedCountries.count - 2) more"
          return cell
        }
      } else {
        if (!isExpanded[1] && indexPath.item == 3) || (isExpanded[1] && indexPath.item == viewModel.bucketListCountries.count + 1) {
          let cell = self.configure(cellType: SeeMoreCell.self, for: indexPath)
          cell.seeMoreLabel.text = isExpanded[1] ? "See less" : "See \(viewModel.bucketListCountries.count - 2) more"
          return cell
        }
      }
      
      let cell = self.configure(cellType: CountryCell.self, for: indexPath)
      let country = SectionType(rawValue: indexPath.section) == .pastCountries ? viewModel.visitedCountries[indexPath.item - 1] : viewModel.bucketListCountries[indexPath.item - 1]
      
      cell.populate(countryName: country.0, flag: country.1)
      
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
    let width = collectionView.frame.width - 48
    switch SectionType(rawValue: indexPath.section)! {
    case .futureCountries, .pastCountries:
      if indexPath.item == 0 {
        return CGSize(
          width: width,
          height: 64
        )
      } else {
        return CGSize(
          width: width,
          height: 48
        )
      }
    default:
      return CGSize(
        width: width,
        height: 92
      )
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch SectionType(rawValue: indexPath.section)! {
    case .pastCountries, .futureCountries:
      if SectionType(rawValue: indexPath.section) == .pastCountries && (!isExpanded[0] && indexPath.item == 3 || isExpanded[0] && indexPath.item == viewModel.visitedCountries.count + 1) {
        isExpanded[0].toggle()
        collectionView.reloadSections(IndexSet(integer: indexPath.section))
      } else if SectionType(rawValue: indexPath.section) == .futureCountries && (!isExpanded[1] && indexPath.item == 3 || isExpanded[1] && indexPath.item == viewModel.bucketListCountries.count + 1) {
        isExpanded[1].toggle()
        collectionView.reloadSections(IndexSet(integer: indexPath.section))
      } else {
        let country = SectionType(rawValue: indexPath.section) == .pastCountries ? viewModel.visitedCountries[indexPath.item - 1] : viewModel.bucketListCountries[indexPath.item - 1]
             showDeleteConfirmationAlert(for: country.0, inSection: indexPath.section)
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

// MARK: - Picker
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return Countries.allCountries.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return Countries.allCountries[row].0
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    // Nothing needed here
  }
  
}

// MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
  
  @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
    if gestureRecognizer.state != .began { return }
    
    let touchPoint = gestureRecognizer.location(in: mapView)
    let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    
    // Determine the country by coordinates
    let location = CLLocation(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
    geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
      guard let self = self else { return }
      if let placemark = placemarks?.first, let countryCode = placemark.isoCountryCode {
        if let country = Countries.countryIdentifiers[countryCode] {
          print("Country: \(country)")
          self.findCountryLocation(for: country, isNewAnnotation: true)
        }
      }
    }
  }
  
  func findCountryLocation(for country: String, check: Bool = true, isNewAnnotation: Bool) {
    let searchRequest = MKLocalSearch.Request()
    searchRequest.naturalLanguageQuery = country
    
    let search = MKLocalSearch(request: searchRequest)
    search.start { (response, error) in
      guard let response = response, error == nil else {
        print("Error finding country: \(error?.localizedDescription ?? "Unknown error")")
        return
      }
      
      if let mapItem = response.mapItems.first {
        let countryLocation = mapItem.placemark.coordinate
        
        if isNewAnnotation {
          print("Country location addToVisitedCountries \(country): \(country)")
          self.addToVisitedCountries(country)
        } else {
          print("Country location addAnnotation \(country): \(country)")
          self.addAnnotation(at: countryLocation, title: country, check: check)
        }
      }
    }
  }
  
  func addAnnotation(at coordinate: CLLocationCoordinate2D, title: String, check: Bool) {
    print("addAnnotation \(title)")
    if let countryData = Countries.allCountries.first(where: { $0.0 == title }) {
      let annotation = CountryAnnotation(coordinate: coordinate, title: title, flag: countryData.1, check: check)
      mapView.addAnnotation(annotation)
      
      // Save the annotation to the dictionary
      annotations[annotation.title ?? ""] = annotation
    }
  }
  
  func addToVisitedCountries(_ country: String) {
    print("addToVisitedCountries \(country)")
    
    if let countryData = Countries.allCountries.first(where: { $0.0 == country }) {
      self.addNewCountry(name: countryData.0, flag: countryData.1, toSection: SectionType.pastCountries.rawValue)
      
    } else {
      print("Country \(country) not found in the dictionary.")
    }
  }
  
  // MKMapViewDelegate method for displaying custom annotations
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let countryAnnotation = annotation as? CountryAnnotation else {
      return nil
    }
    
    let identifier = "CountryAnnotationView"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CountryNameAnnotationView
    if (annotationView == nil) {
      annotationView = CountryNameAnnotationView(annotation: countryAnnotation, reuseIdentifier: identifier)
    } else {
      annotationView?.annotation = countryAnnotation
    }
    return annotationView
  }
  
  func addAnnotations(for countries: [(String, String)], check: Bool = true) {
    for country in countries {
      findCountryLocation(for: country.0, check: check, isNewAnnotation: false)
    }
  }
  
}
