import UIKit
import MapKit
import CoreLocation

class EarthViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var annotations: [String: MKAnnotation] = [:]
    let geocoder = CLGeocoder()

    var visitedCountries: [(String, String)] = [
        ("Ukraine", "🇺🇦"),
        ("Mexico", "🇲🇽"),
        ("Chile", "🇨🇱"),
        ("France", "🇫🇷"),
        ("Germany", "🇩🇪")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        // Настройка начального вида карты как глобус
        mapView.mapType = .hybridFlyover
        mapView.camera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), fromDistance: 20000000, pitch: 0, heading: 0)

        // Добавляем распознаватель долгого нажатия для установки меток
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began { return }

        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        // Определяем страну по координатам
        let location = CLLocation(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let placemark = placemarks?.first, let countryCode = placemark.isoCountryCode {
                if let country = Countries.countryIdentifiers[countryCode] {
                    print("Страна: \(country)")
                    self.findCountryLocation(for: country)
                }
            }
        }
    }

    func findCountryLocation(for country: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = country

        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let response = response, error == nil else {
                print("Ошибка при поиске страны: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                return
            }

            if let mapItem = response.mapItems.first {
                let countryLocation = mapItem.placemark.coordinate
                print("Локация страны \(country): \(country)")

              self.addAnnotation(at: countryLocation, title: country, check: true)
                self.addToVisitedCountries(country)
            }
        }
    }

  func addAnnotation(at coordinate: CLLocationCoordinate2D, title: String, check: Bool) {
        if let countryData = Countries.allCountries.first(where: { $0.0 == title }) {
          let annotation = CountryAnnotation(coordinate: coordinate, title: title, flag: countryData.1, check: check)
            mapView.addAnnotation(annotation)

            // Сохраняем метку в словарь
            annotations[annotation.title ?? ""] = annotation
        }
    }

    func addToVisitedCountries(_ country: String) {
        if let countryData = Countries.allCountries.first(where: { $0.0 == country }) {
            visitedCountries.append(countryData)
            print("Добавлена страна: \(countryData)")
        } else {
            print("Страна \(country) не найдена в словаре.")
        }
    }

    // MKMapViewDelegate метод для отображения пользовательских аннотаций
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let countryAnnotation = annotation as? CountryAnnotation else {
            return nil
        }

        let identifier = "CountryAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CountryNameAnnotationView
        if annotationView == nil {
            annotationView = CountryNameAnnotationView(annotation: countryAnnotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = countryAnnotation
        }
        return annotationView
    }
}
