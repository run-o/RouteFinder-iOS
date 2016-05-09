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
    
    // failable initializer (returns nil in case of failure):
    init?() {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        
        // create the connection:
        do {
            db = try Connection("\(path)/route_finder_db.sqlite3")
            createTables()
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
                    "CREATE TABLE IF NOT EXISTS area (" +
                    "area_id INTEGER PRIMARY KEY NOT NULL," +
                    "name TEXT NOT NULL," +
                    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP," +
                    "parent_area_id INTEGER REFERENCES areas" +
                    ");" +
                    "CREATE TABLE IF NOT EXISTS routes (" +
                    "route_id INTEGER PRIMARY KEY NOT NULL," +
                    "name TEXT NOT NULL," +
                    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP," +
                    "grade VARCHAR," +
                    "area_id INTEGER NOT NULL REFERENCES areas" +
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
                "COMMIT TRANSACTION:"
            )
        } catch {
            print("Tables creation failed: \(error)");
            return false
        }
        
        return true
    }
    
}