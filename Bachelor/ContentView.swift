import SwiftUI
import MapKit
import CoreLocation
import Polyline


struct ContentView: View {
    
    @State var routePolyline: MKPolyline?
    @State var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 52.520007, longitude: 13.404954), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    @State var locations : [location] = []
    
    @State var startAndDestination : [CLLocationCoordinate2D] = []
    var locationsCombined : [location] {
       return locations + resultLocationsStart + resultLocationsDestination + resultLocationsBlocked
   }
    
    @State var searchQueryStart = ""
    @State var searchQueryZiel = ""
    @State var searchQueryBlocked = ""
    
    @State var searchResults: [MKMapItem] = []
    @State var searchResultsDestination: [MKMapItem] = []
    @State var searchResultsStart: [MKMapItem] = []
    @State var searchResultsBlocked : [MKMapItem] = []
    
    @State var resultLocationsDestination : [location] = []
    @State var resultLocationsStart : [location] = []
    @State var resultLocationsBlocked : [location] = []
    @State var showAlert = false
    @State var showList = false

    
    
    var body: some View {
        VStack(spacing: 0) {
            
             //Searchbar zur view hinzufügen und die entsprechenden Variablen zuweisen
            searchBar(searchQueryDestination: $searchQueryZiel, searchQueryStart: $searchQueryStart, searchQueryBlocked: $searchQueryBlocked, onSearchDestiantion: performSearchDestination, onSearchStart: performSearchStart, onSearchBlocked: performSearchBlocked)
                .padding(.top)
            
            Button("Route planen") {
                getDirection()
                showList = true
                
            }
               
            HStack{
                Spacer()
                Button{
                    let newSpan = MKCoordinateSpan(latitudeDelta: mapRegion.span.latitudeDelta/2, longitudeDelta: mapRegion.span.longitudeDelta/2)
                    mapRegion = MKCoordinateRegion(center: mapRegion.center, span: newSpan)
                    
                }
            label: {
                Image(systemName: "plus")
                
                
            }
                Button{
                    let newSpan = MKCoordinateSpan(latitudeDelta: mapRegion.span.latitudeDelta*2, longitudeDelta: mapRegion.span.longitudeDelta*2)
                    mapRegion = MKCoordinateRegion(center: mapRegion.center, span: newSpan)
                    
                    
                }label: {
                    Image(systemName: "minus")
                    
                }
                Spacer()
                Button(action: {
                    showAlert = true
                    
                }){
                    Image(systemName: "info.circle")
                    
                }
                .alert(isPresented: $showAlert){
                    Alert(
                        title: Text ("Information"),
                        message: Text("Bitte den Ort mit angeben für eine genauereSuche. Bitte geben Sie mindestens zwei blockierte Koordinaten an, um diese während der Planung berücksichigen zu können." +
                                      "\n Die Routenplanung wird mithilfe von Openrouteservice durchgeführt"))
                    
                }
                
            }
            .padding()
            ZStack {
                //Hinzufügen der Annotationen bevor das Overlay hinzugefügt wird. Hierbei ohne Namen
                Map(coordinateRegion: $mapRegion,showsUserLocation: true, annotationItems: locationsCombined) { location in
                    MapMarker(coordinate: location.coordinate, tint: location.markerColor)
                    
                }
                .overlay(polylineOverlay) // Polylinie mit den Annotationen wird auf die Karte gelegt
                
                VStack {
                    Spacer()  //Darstellung des Ergebnis aus der jeweiligen Suchleiste
                    List(searchResults, id: \.self) { item in
                        Text(item.name ?? "")
                        
                    }
                    .frame(height: 100)
                    
                    
                }
                
            }
            
        }
        
    }
  
    
    struct searchBar: View {
        @Binding var searchQueryDestination: String
        @Binding var searchQueryStart: String
        @Binding var searchQueryBlocked: String
        
       
        var onSearchDestiantion: () -> Void
        var onSearchStart: () -> Void
        var onSearchBlocked: () -> Void

        var body: some View {
            VStack {
                HStack{
                    TextField("Start", text: $searchQueryStart, onCommit: onSearchStart)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchQueryStart){ searchString in
                            
                        }
                    
                    Button(action: onSearchStart) {
                        Image(systemName: "magnifyingglass")
                        
                    }
                    
                }
                HStack{
                    TextField("Ziel", text: $searchQueryDestination, onCommit: onSearchDestiantion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: onSearchDestiantion) {
                        Image(systemName: "magnifyingglass")
                        
                    }
                    
                }
                
                HStack{
                    TextField("Blockierte Straße", text: $searchQueryBlocked, onCommit: onSearchBlocked)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: onSearchBlocked) {
                        Image(systemName: "magnifyingglass")
                        
                    }
                    
                }
                
            }
            .padding()
            
        }
        
    }
    
    //view wird aufgerufen um die Polylinie auf die Karte mit den Annotationen zu legen
    var polylineOverlay: some View {
        if let polyline = routePolyline {
            
            return AnyView(mapOverlay(polyline: polyline, mapRegion: $mapRegion, locations: locations + resultLocationsStart + resultLocationsDestination))
            
        } else {
            
            return AnyView(EmptyOverlay())
        }
    }
    
    
    func convertCLLocationToCoordinates(clLocation: CLLocationCoordinate2D) -> String {
        let latitude = clLocation.latitude
        let longitude = clLocation.longitude
        return "\(longitude),\(latitude)"
    }
    
    func performSearchStart() {
        routePolyline = nil
        let requestStart = MKLocalSearch.Request()
            requestStart.naturalLanguageQuery = searchQueryStart
       
        
        let search = MKLocalSearch(request: requestStart)
        
        search.start { response, error in
            if let error = error {
                print("Search error: \(error)")
                return
                
            }
            
              guard let mapItems = response?.mapItems else {
                return
                  
              }
            
                
                
                if self.searchQueryStart.isEmpty{
                    resultLocationsStart.removeAll()
               
                }else{
                    self.searchResults = mapItems
                    self.searchResultsStart = mapItems
                    let newSearchCoordinates = createLocation(from: self.searchResults.last!)
                    
                    resultLocationsStart.append(location(name: "Start", coordinate: newSearchCoordinates.coordinate))
                    
                    if resultLocationsStart.last?.name == "Start"{
                        print("hi")
                        locations.removeAll{ location in
                            location.name == "Start"
                            
                        }
                        
                    }
                    
                    if resultLocationsStart.last?.name == "Start"{
                        resultLocationsStart.removeAll{ location in
                            location.name == "Start"
                            
                        }
                        
                        resultLocationsStart.append(location(name: "Start", coordinate: newSearchCoordinates.coordinate))
                        locations.append(location(name: "Start", coordinate: newSearchCoordinates.coordinate))
                        
                    }else{
                        resultLocationsStart.append(location(name: "Start", coordinate: newSearchCoordinates.coordinate))
                        locations.append(location(name: "Start", coordinate: newSearchCoordinates.coordinate))
                        
                    }
                    
                    if let existingIndex = self.resultLocationsStart.firstIndex(where: {$0.name == "Start"}){
                        self.resultLocationsStart.remove(at: existingIndex)
                        
                    }
                }
        }
        
    }
    
    func performSearchDestination() {
        routePolyline = nil
        let requestZiel = MKLocalSearch.Request()
            requestZiel.naturalLanguageQuery = searchQueryZiel
        
        
        let search = MKLocalSearch(request: requestZiel)
        search.start { response, error in
            if let error = error {
                print("Search error: \(error)")
                return
            }
            
            guard let mapItems = response?.mapItems else {
                return
            }
            

                if self.searchQueryZiel.isEmpty{
                    return
                }else{
                    self.searchResults = mapItems
                    self.searchResultsDestination = mapItems
                    let newSearch = createLocation(from: self.searchResults.last!)
                    resultLocationsDestination.append(location(name: "Destination", coordinate: newSearch.coordinate))

                    
                    if resultLocationsDestination.last?.name == "Destination"{
                        locations.removeAll{ location in
                            location.name == "Destination"
                            
                        }
                        
                    }
                    
                    if resultLocationsDestination.last?.name == "Destination"{
                        resultLocationsDestination.removeAll{ location in
                            location.name == "Destination"
                            
                        }
                        
                        resultLocationsDestination.append(location(name: "Destination", coordinate: newSearch.coordinate))
                        locations.append(location(name: "Destination", coordinate: newSearch.coordinate))
                    }else{
                        resultLocationsDestination.append(location(name: "Destination", coordinate: newSearch.coordinate))
                        locations.append(location(name: "Destination", coordinate: newSearch.coordinate))
                        
                    }
                    
                    if let existingIndex = self.resultLocationsDestination.firstIndex(where: {$0.name == "Destination"}){
                        self.resultLocationsDestination.remove(at: existingIndex)
                        
                    }
                    
                }
        }
        
    }
    
    func performSearchBlocked() {
        let requestZiel = MKLocalSearch.Request()
            requestZiel.naturalLanguageQuery = searchQueryBlocked
        
        
        
        let search = MKLocalSearch(request: requestZiel)
        search.start { response, error in
            if let error = error {
                print("Search error: \(error)")
                return
            }
            
            
            guard let mapItems = response?.mapItems else {
                return
            }
            
                if self.searchQueryBlocked.isEmpty{
                    return
                }else{
                    self.searchResults = mapItems
                    self.searchResultsBlocked = mapItems
                    let newSearch = createLocation(from: self.searchResults.last!)
                    

                        resultLocationsBlocked.append(location(name: "Blocked", coordinate: newSearch.coordinate))
                        locations.append(location(name: "Blocked", coordinate: newSearch.coordinate))

                }
                
        }
    }
    
    func printCoordinates(of mapItems: [MKMapItem]) {
        for item in mapItems {
            print("Name: \(item.name ?? "")")
            print("Coordinate: \(item.placemark.coordinate)")
            print("------------")
        }
    }
    
    func getDirection() {
        routePolyline = nil
        searchResults = []
        startAndDestination = []
        
        guard let resultStart = searchResultsStart.first else{
            print("Start could not be found")
            return
        }
        
        guard let resultDestination = searchResultsDestination.first else{
            print("Destination could not be found")
            return
        }
      
        
        let startCoordinate = resultStart.placemark.coordinate
        let destinationCoordinate = resultDestination.placemark.coordinate
        
        
        
        startAndDestination.removeAll{ coordinate in
            return coordinate.latitude == startCoordinate.latitude && coordinate.longitude == startCoordinate.longitude
        }
        startAndDestination.removeAll{ coordinate in
            return coordinate.latitude == destinationCoordinate.latitude && coordinate.longitude == destinationCoordinate.longitude
            
        }
     
        startAndDestination.append(startCoordinate)
        startAndDestination.append(destinationCoordinate)
        
        
         
        
      
        
        var avoidPolygons: [String:Any] = [:]
        if !resultLocationsBlocked.isEmpty {
                let blockedCoordinates = resultLocationsBlocked.map { location in
                    return [location.coordinate.longitude, location.coordinate.latitude]
                }
            
                
                let polygon: [Any] = [blockedCoordinates + [blockedCoordinates.first!]]
                avoidPolygons = [
                    "type": "Polygon",
                    "coordinates": polygon
                ]
            }
        let key = "5b3ce3597851110001cf624874267b8241c6481eb8e25088aec6f33d"

    /*    guard let url = URL(string: "https://api.openrouteservice.org/v2/directions/driving-car?api_key=\(key)&start=\(startCoordinate)&end=\(destinationCoordinate)&radiuses=\(searchRadius),\(searchRadius)") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8", forHTTPHeaderField: "Accept")*/
        
            let url = URL(string: "https://api.openrouteservice.org/v2/directions/driving-car")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8", forHTTPHeaderField: "Accept")
                request.addValue(key, forHTTPHeaderField: "Authorization")
                
                request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        var requestContent: [String:Any] = [:]
        
        if !avoidPolygons.isEmpty{
             requestContent = [
                "coordinates": startAndDestination.map{[ $0.longitude,  $0.latitude]},
                
                "options": [
                    "avoid_polygons": avoidPolygons
                ]
             ]
            
        }else{
        requestContent = [
           "coordinates": startAndDestination.map{[ $0.longitude,  $0.latitude]},
        ]
            
        }
        
        print("Start And Ziel : ", startAndDestination)
        let jsonData = try? JSONSerialization.data(withJSONObject: requestContent)
        if let jsonData = jsonData{
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON Response: \(jsonString)")
            }
        }
        
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                            print("JSON Response: \(jsonString)")
                    
                }
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let response = try decoder.decode(directionsResponse.self, from: data)
                   
                    if let route = response.routes?.first, let _ = response.routes {
                        let routeCoordinates = route.routeCoordinates
                        
                        
                            routePolyline = MKPolyline(coordinates:routeCoordinates, count: routeCoordinates.count)
                        
                            let startingLocation = location(name: "Start", coordinate: resultStart.placemark.coordinate)
                            let destinationLocation = location(name: "Destination", coordinate: resultDestination.placemark.coordinate)
                            
                        if locations.last?.name != "Start" || locations.last?.name == "Start"{
                                locations.removeAll {location in
                                    location.name == "Start"
                                }
                                locations.append(location(name: "Start", coordinate: startingLocation.coordinate))
                            }
                            
                            
                            if locations.last?.name != "Destination"{
                                locations.removeAll {location in
                                    location.name == "Destination"
                                }
                                locations.append(location(name: "Destination", coordinate: destinationLocation.coordinate))
                            }

                    }else if let error = response.error{
                        print("The error \(error.message)")
                    }
                 
                } catch {
                    print("Error decoding JSON: \(error)")
                    
                }
            } else if let error = error {
                print("Error: \(error)")
            }
        }
        
        task.resume()

    }
    
    func createLocation(from mapItem: MKMapItem) -> location {
        let name = mapItem.name ?? ""
        let coordinate = mapItem.placemark.coordinate
        return location(name: name, coordinate: coordinate)
    }
}




struct location: Identifiable {
    let id = UUID()
    let name: String
    var coordinate: CLLocationCoordinate2D
    
    var markerColor : Color{
        switch name{
        case "Start","Destination" :
            return .blue
            
        case "Blocked":
            return .yellow
            
        default:
            return .red
        }
    }
    
    var markerColorAfterUpdate : UIColor{
        switch name{
        case "Start","Destination" :
            return UIColor.blue
            
        case "Blocked":
            return UIColor.yellow
            
        default:
            return .red
        }
    }
}

struct directionsResponse: Codable {
     let routes :[route]?
    let error: directionsError?
}

struct directionsError:Codable{
    let code: Int
    let message: String
}

struct route: Codable {
    let geometry: String
   
    var routeCoordinates: [CLLocationCoordinate2D]{
        let polyline = Polyline(encodedPolyline: geometry)
        return polyline.coordinates ?? []
    }
}


struct geometry: Codable {
    let coordinates: [[Double]]
    
}

struct mapOverlay: View {
    let polyline: MKPolyline
    @Binding var mapRegion: MKCoordinateRegion
    let locations: [location]
    
    var body: some View {
        mapOverlayRepresentable(polyline: polyline, mapRegion: $mapRegion, locations: locations)
    }
}



struct mapOverlayRepresentable: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    let polyline: MKPolyline
    @Binding var mapRegion : MKCoordinateRegion
    let locations : [location]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let overlaysToRemove = uiView.overlays.filter { overlay in
            !(overlay is MKAnnotationView)
        }
        uiView.removeOverlays(overlaysToRemove)
       
        uiView.addOverlay(polyline)
        
        uiView.removeAnnotations(uiView.annotations)
        
        uiView.addAnnotations(locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
 
            return annotation
        })
        
       uiView.region = mapRegion
 
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(locations: locations)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        var locations : [location]
        init(locations: [location]) {
            self.locations = locations
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let line = MKPolylineRenderer(overlay: overlay)
                line.strokeColor = .blue
                line.lineWidth = 3
                return line
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let locationAnnotation = annotation as? MKPointAnnotation else {
                return nil
            }
            let reuseIdentifier = "LocationAnnotation"
            
            let annotationView = MKMarkerAnnotationView(annotation: locationAnnotation, reuseIdentifier: reuseIdentifier)

            if let location = locations.first(where: { $0.coordinate == annotation.coordinate }) {
                if let annotationView = annotationView as? MKMarkerAnnotationView {
                    annotationView.markerTintColor = UIColor(location.markerColor)
                    
                }
                
            }
            
            return annotationView
            
        }
        
    }
    
}


extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct EmptyOverlay: View {
    var body: some View {
        EmptyView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
}
