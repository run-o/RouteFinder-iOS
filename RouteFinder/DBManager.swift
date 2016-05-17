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
    
    func addArea(name : String, parentId : Int64) -> Int64? {
        do {
            let rowid = try db.run(areas.insert(_name <- name, _parent_area_id <- parentId ))
            print("inserted id: \(rowid)")
            return rowid
        } catch {
            print("insertion failed: \(error)")
            return nil
        }
    }
    
    func getArea(areaId: Int64) -> String? {
        let query = areas.select(_area_id, _name, _parent_area_id)
            .filter(_area_id == areaId)
        
        do {
            for area in try db.prepare(query) {
                print("area_id: \(area[_area_id]), name: \(area[_name]), parent: \(area[_parent_area_id])")
                return area[_name]
            }
        }
        catch {
            print("select error: \(error)")
        }
        return nil
    }
    
    
}