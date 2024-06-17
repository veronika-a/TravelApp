import UIKit
import MapKit

class CountryNameAnnotationView: MKAnnotationView {
  override var annotation: MKAnnotation? {
    willSet {
      guard let countryAnnotation = newValue as? CountryAnnotation else { return }
      
      canShowCallout = true
      
      for subview in subviews {
        subview.removeFromSuperview()
      }
      
      let bgImg = UIImageView(image: UIImage(named: countryAnnotation.check ? "PinCheck" : "Pin"))
      bgImg.frame = CGRect(x: 0, y: 0, width: 36, height: 42)
      bgImg.contentMode = .scaleAspectFit
      bgImg.layer.masksToBounds = true
      addSubview(bgImg)
      
      let countryLabel = UILabel()
      countryLabel.text = countryAnnotation.flag
      countryLabel.font = UIFont.systemFont(ofSize: 24)
      countryLabel.textAlignment = .center
      countryLabel.sizeToFit()
      countryLabel.layer.masksToBounds = true
      addSubview(countryLabel)
      
      frame = bgImg.frame
      
      countryLabel.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        countryLabel.centerXAnchor.constraint(equalTo: bgImg.centerXAnchor),
        countryLabel.centerYAnchor.constraint(equalTo: bgImg.centerYAnchor)
      ])
    }
  }
}

class CountryAnnotation: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var title: String?
  var flag: String
  var check: Bool
  
  init(coordinate: CLLocationCoordinate2D, title: String, flag: String, check: Bool) {
    self.coordinate = coordinate
    self.title = title
    self.flag = flag
    self.check = check
    super.init()
  }
}
