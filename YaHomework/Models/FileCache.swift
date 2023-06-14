//
//  FileCache.swift
//  YaHomework
//
// Created by Максим Лейхнер on 12.06.2023.
//

import Foundation

class FileCache {
    
    
    private(set) var todoList: Set<TodoItem> = []
    
    func addTodo(_ todo: TodoItem) { todoList.insert(todo) }

    func removeTask(id: String) -> Bool {
        if let found = todoList.first(where: { $0.id == id }) {
            todoList.remove(found)
            return true
        }
        return false
    }

    func saveToJSON() throws {
        let rootUrl = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)
        let appDataFolder = rootUrl.appendingPathComponent("YaHomework")

        if !FileManager.default.fileExists(atPath: appDataFolder.relativePath) {
            try FileManager.default.createDirectory(
                    at: appDataFolder,
                    withIntermediateDirectories: false)
        }

        let fileUrl = appDataFolder.appendingPathComponent("TodoList.json")
        let data = try JSONSerialization.data(withJSONObject: todoList.map({ element -> Any in element.json }), options: [])
        try data.write(to: fileUrl)
    }
    
    func loadFromJSON() throws {
        let rootUrl = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
        let appDataFolder = rootUrl.appendingPathComponent("YaHomework")
        let fileUrl = appDataFolder.appendingPathComponent("TodoList.json")
        if !FileManager.default.fileExists(atPath: fileUrl.relativePath) {
            throw FileCacheError.NoSuchFile(path: fileUrl.relativePath)
        }
        
        let data = try Data(contentsOf: fileUrl, options: [])
        if let newTodoItemsData = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject] {
            for element in newTodoItemsData {
                if let newTodoItem = TodoItem.parse(json: element) {
                    todoList.insert(newTodoItem)
                } else {
                    throw FileCacheError.UnableToParseFromJSON
                }
            }
        }
    }
    
    func saveToCSV() throws {
        let rootUrl = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
        let appDataFolder = rootUrl.appendingPathComponent("YaHomework")
        
        if !FileManager.default.fileExists(atPath: appDataFolder.relativePath) {
            try FileManager.default.createDirectory(
                at: appDataFolder,
                withIntermediateDirectories: false)
        }
        
        let fileUrl = appDataFolder.appendingPathComponent("TodoList.csv")
        let csvLines = todoList.map{ $0.csv }.joined(separator: "\n")
        try csvLines.write(to: fileUrl, atomically: false, encoding: .unicode)
    }
    
    func loadFromCSV() throws {
        let rootUrl = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
        let appDataFolder = rootUrl.appendingPathComponent("YaHomework")
        let fileUrl = appDataFolder.appendingPathComponent("TodoList.csv")
        let csvLines = try String(contentsOf: fileUrl)
        todoList = Set(csvLines.split(separator: "\n").compactMap { TodoItem.parse(csv: String($0)) })
    }
}

enum FileCacheError : Error {
    case NoSuchFile(path: String)
    case UnableToParseFromJSON
}
