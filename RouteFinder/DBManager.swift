//
//  DBManager.swift
//  RouteFinder
//
//  Created by Renaud Amar on 5/7/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import Foundation
import SQLite


class DBManager {
    
    // Create a singleton instance of our class:
    // check out this post for the right way to write a singleton in Swift:
    // http://krakendev.io/blog/the-right-way-to-write-a-singleton
    // and here: https://thatthinginswift.com/singletons/
    static let sharedManager = DBManager()
    
    var db : Connection!
    let areas = Table("areas")
    let routes = Table("routes")
    let photos = Table("photos")
    let _area_id = Expression<Int64>("area_id")
    let _name = Expression<String>("name")
    let _parent_area_id = Expression<Int64>("parent_area_id")
    let _route_id = Expression<Int64>("route_id")
    let _grade = Expression<String>("grade")
    let _photo_id = Expression<Int64>("photo_id")
    let _longitude = Expression<Double>("longitude")
    let _latitude = Expression<Double>("latitude")
    let _azimuth = Expression<Double>("azimuth")
    let _inclination = Expression<Double>("inclination")
    let _filename = Expression<String>("filename")
    let _filepath = Expression<String>("filepath")
    let _timestamp = Expression<NSDate>("timestamp")
    let _date_taken = Expression<NSDate>("timestamp")
    
    
    // failable initializer (returns nil in case of failure):
    init?() {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        
        // create the connection:
        do {
            db = try Connection("\(path)/route_finder_db.sqlite3")
        } catch {
            print("DB initialization failed: \(error)")
            return nil
        }
        // create the tables:
        if (!createTables()) {
            return nil
        }
    }
    
    func createTables() -> Bool {
        do {
            try db.execute(
                "BEGIN TRANSACTION;" +
                    "CREATE TABLE IF NOT EXISTS areas (" +
                    "area_id INTEGER PRIMARY KEY NOT NULL," +
                    "name TEXT NOT NULL," +
                    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP," +
                    "parent_area_id INTEGER REFERENCES areas," +
                    "UNIQUE(name, parent_area_id)" + // each area's name should be unique within a given parent area
                    ");" +
                    "CREATE TABLE IF NOT EXISTS routes (" +
                    "route_id INTEGER PRIMARY KEY NOT NULL," +
                    "name TEXT NOT NULL," +
                    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP," +
                    "grade VARCHAR," +
                    "area_id INTEGER NOT NULL REFERENCES areas," +
                    "UNIQUE(name, area_id)" + // each route name should be unique within a given area
                    ");" +
                    "CREATE TABLE IF NOT EXISTS photos (" +
                    "photo_id INTEGER PRIMARY KEY NOT NULL," +
                    "date_taken DATETIME DEFAULT CURRENT_TIMESTAMP," +
                    "longitude DOUBLE," +
                    "latitude DOUBLE," +
                    "azimuth DOUBLE," +
                    "inclination DOUBLE," +
                    "filename VARCHAR," +
                    "filepath VARCHAR," +
                    "route_id INTEGER NOT NULL REFERENCES routes" +
                    ");" +
                "COMMIT TRANSACTION;"
            )
        } catch {
            print("Tables creation failed: \(error)");
            return false
        }
        
        return true
    }
    
    // create a new area given its name and id of the parent area
    // returns the area id
    func addArea(name : String, parentId : Int64) -> Int64? {
        
        do {
            let rowid = try db.run(areas.insert(_name <- name, _parent_area_id <- parentId ))
            print("inserted id: \(rowid)")
            return rowid
        } catch {
            print("addArea failed: \(error)")
            return nil
        }
    }
    
    // get the name and parent id for a given area id:
    func getArea(areaId: Int64) -> (name: String, parentAreaId:Int64)? {
        
        let query = areas.select(_area_id, _name, _parent_area_id)
            .filter(_area_id == areaId)
        
        do {
            for area in try db.prepare(query) {
                print("area_id: \(area[_area_id]), name: \(area[_name]), parent: \(area[_parent_area_id])")
                return (area[_name], area[_parent_area_id])
            }
        }
        catch {
            print("getArea error: \(error)")
        }
        return nil
    }
    
    // delete an area based on its id:
    func deleteArea(areaId: Int64) -> Bool {
        
        let query = areas.filter(_area_id == areaId)
        do {
            try db.run(query.delete())
            return true
        }
        catch {
            print("deleteArea error: \(error)")
        }
        return false
    }
    
    // get a list of sub areas with the same parent id:
    func getSubAreas(parentId: Int64) -> Array<(areaId: Int64, name: String)>? {
        var subAreas: [(Int64, String)] = []
        
        let query = areas.filter(_parent_area_id == parentId)
        do {
            print("getSubAreas for parent id = \(parentId)")
            for area in try db.prepare(query) {
                subAreas.append((area[_area_id], area[_name]))
                print("area_id: \(area[_area_id]), name: \(area[_name])")
            }
            return subAreas
        }
        catch {
            print("getSubAreas error: \(error)")
        }
        
        return nil
    }
    
    // ** This is probably not needed (can be achieved with getArea)
    // get the parent area of the given area:
    //func getParentArea(areaId: Int64) -> (name: String, parentAreaId:Int64)?
    
    // add a new route:
    func addRoute(name : String, areaId : Int64, grade: String) -> Int64? {
        
        do {
            let rowid = try db.run(routes.insert(_name <- name, _grade <- grade, _area_id <- areaId ))
            print("route inserted id: \(rowid)")
            return rowid
        } catch {
            print("addRoute failed: \(error)")
            return nil
        }
    }
    
    // get the route info for a given route id:
    func getRoute(routeId: Int64) -> (name: String, grade: String, areaId:Int64)? {
        
        let query = routes.select(_name, _grade, _area_id)
            .filter(_route_id == routeId)
        
        do {
            for route in try db.prepare(query) {
                print("name: \(route[_name]), grade: \(route[_grade]), areaId: \(route[_area_id])")
                return (route[_name], route[_grade], route[_area_id])
            }
        }
        catch {
            print("getRoute error: \(error)")
        }
        return nil
    }
    
    // delete a route based on its id:
    func deleteRoute(routeId: Int64) -> Bool {
        
        let query = routes.filter(_route_id == routeId)
        do {
            try db.run(query.delete())
            return true
        }
        catch {
            print("deleteRoute error: \(error)")
        }
        return false
    }
    
    // get the list of routes for the given area id:
    func getRoutesForArea(areaId: Int64) -> Array<(routeId:Int64, name:String, grade:String)>? {
        var routesInArea: [(Int64, String, String)] = []
        
        let query = routes.filter(_area_id == areaId)
        do {
            print("getRoutesForArea areaId = \(areaId)")
            for route in try db.prepare(query) {
                routesInArea.append((route[_route_id], route[_name], route[_grade]))
                print("route_id: \(route[_route_id]), grade: \(route[_grade]), name: \(route[_name])")
            }
            return routesInArea
        }
        catch {
            print("getRoutesForArea error: \(error)")
        }
        
        return nil
    }
    
    func addRoutePhoto(routeId: Int64, longitude: Double, latitude: Double,
                       azimuth: Double, inclination: Double,
                       fileName: String, filePath: String) -> Int64? {
        do {
            let rowid = try db.run(photos.insert(_longitude <- longitude, _latitude <- latitude,
                            _azimuth <- azimuth, _inclination <- inclination,
                            _filename <- fileName, _filepath <- filePath, _route_id <- routeId))
            print("photo inserted id: \(rowid)")
            return rowid
        } catch {
            print("addRoutePhoto failed: \(error)")
            return nil
        }
    }
    
    func getPhotosForRoute(routeId: Int64) -> Array<(photoId: Int64, longitude: Double, latitude: Double, azimuth: Double, inclination: Double, fileName: String, filePath:String)>? {
        var photosForRoute: [(Int64, Double, Double, Double, Double, String, String)] = []
        
        let query = photos.filter(_route_id == routeId)
        do {
            print("photosForRoute routeId = \(routeId)")
            for photo in try db.prepare(query) {
                photosForRoute.append((photo[_photo_id], photo[_longitude], photo[_latitude],
                                       photo[_azimuth], photo[_inclination], photo[_filename], photo[_filepath]))
                print("photo_id: \(photo[_photo_id]), longitude: \(photo[_longitude]), latidue: \(photo[_latitude]), azimuth: \(photo[_azimuth]), inclination: \(photo[_inclination]), filename: \(photo[_filename]), filepath: \(photo[_filepath])")
            }
            return photosForRoute
        }
        catch {
            print("getRoutesForArea error: \(error)")
        }
        
        return nil
    }
}