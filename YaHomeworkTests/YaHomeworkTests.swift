//
//  YaHomeworkTests.swift
//  YaHomeworkTests
//
//  Created by Максим Лейхнер on 12.06.2023.
//

import XCTest
@testable import YaHomework

final class YaHomeworkTests: XCTestCase {

    let fileCache = FileCache()


    func testParseJSON_allRequiredFields() throws {
        let input = """
                    {
                    "id": "1234",
                    "text": "Hello, World!",
                    "priority": "unimportant",
                    "done": false
                    }
                    """.data(using: .utf8)!
        let result = TodoItem.parse(json: try JSONSerialization.jsonObject(with: input, options: []))!
        
        XCTAssertEqual(result.id, "1234")
        XCTAssertEqual(result.text, "Hello, World!")
        XCTAssertEqual(result.priority, Priority.unimportant)
        XCTAssertEqual(result.done, false)
    }
    
    func testParseJSON_allFields() throws {
        let input = """
                    {
                    "id": "12345",
                    "text": "Hello",
                    "priority": "important",
                    "deadline": 1686588922,
                    "done": false,
                    "creationDate": 1686588923,
                    "modificationDate": 1686588924
                    }
                    """.data(using: .utf8)!
        let result = TodoItem.parse(json: try JSONSerialization.jsonObject(with: input, options: []))!
        
        XCTAssertEqual(result.id, "12345")
        XCTAssertEqual(result.text, "Hello")
        XCTAssertEqual(result.priority, Priority.important)
        XCTAssertEqual(result.deadline, Date(timeIntervalSince1970: 1686588922))
        XCTAssertEqual(result.done, false)
        XCTAssertEqual(result.creationDate, Date(timeIntervalSince1970: 1686588923))
        XCTAssertEqual(result.modificationDate, Date(timeIntervalSince1970: 1686588924))
    }
    
    func testParseJSON_missingRequiredFields() throws {
        let input = """
                    {
                    "id": "12345",
                    "priority": "important",
                    "deadline": 1686588922,
                    "done": false,
                    "creationDate": 1686588923,
                    "modificationDate": 1686588924
                    }
                    """.data(using: .utf8)!

        let result = TodoItem.parse(json: try JSONSerialization.jsonObject(with: input, options: []))
        
        XCTAssertNil(result)
    }
    
    func testParseJSON_usingDefaults() throws {
        let input = """
                    {
                    "text": "Hello",
                    "done": true
                    }
                    """.data(using: .utf8)!

        let result = TodoItem.parse(json: try JSONSerialization.jsonObject(with: input, options: []))
        
        XCTAssertNotNil(result)
    }
    
    func testHashableEquatable() {
        let lhs = TodoItem(
                id: "1234",
                text: "4321",
                priority: .normal,
                deadline: Date(),
                done: false,
                creationDate: Date(),
                modificationDate: Date())
        let rhs = TodoItem(
                id: "1234",
                text: "1234",
                priority: .unimportant,
                deadline: Date(),
                done: true,
                creationDate: Date(),
                modificationDate: Date())
        
        let resultHashable = lhs.hashValue == rhs.hashValue
        let resultEquatable = lhs == rhs
        
        XCTAssertTrue(resultHashable)
        XCTAssertTrue(resultEquatable)
    }
    
    func testFileCache_addingToSet() {
        let todoItems = [TodoItem(
                                id: "1234",
                                text: "4321",
                                priority: .normal,
                                deadline: Date(),
                                done: false,
                                creationDate: Date(),
                                modificationDate: Date()),
                         TodoItem(
                                 id: "1234",
                                 text: "1234",
                                 priority: .unimportant,
                                 deadline: Date(),
                                 done: true,
                                 creationDate: Date(),
                                 modificationDate: Date()),
                         TodoItem(
                                 id: "4321",
                                 text: "1234",
                                 priority: .unimportant,
                                 deadline: Date(),
                                 done: true,
                                 creationDate: Date(),
                                 modificationDate: Date())]

        for item in todoItems {
            fileCache.addTodo(item)
        }
        let result = fileCache.todoList
        XCTAssertEqual(result.count, 2)
    }
    
    func testFileCache_saving() throws {
        let todoItems = [TodoItem(
                                id: "1234",
                                text: "4321",
                                priority: .normal,
                                deadline: Date(),
                                done: false,
                                creationDate: Date(),
                                modificationDate: Date()),
                         TodoItem(
                                 id: "4321",
                                 text: "1234",
                                 priority: .unimportant,
                                 deadline: Date(),
                                 done: true,
                                 creationDate: Date(),
                                 modificationDate: Date())]
        for item in todoItems {
            fileCache.addTodo(item)
        }
        
        try fileCache.saveToJSON()
        
        let rootUrl = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
        let appDataFolder = rootUrl.appendingPathComponent("YaHomework")
        let fileUrl = appDataFolder.appendingPathComponent("TodoList.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.relativePath))
            
    }
    
    func testFileCache_loading() throws {
        
        try fileCache.loadFromJSON()
        XCTAssertEqual(fileCache.todoList.count, 2)
        
    }
    
    func testFromCSV_line() {
        let input = "7269829;Погладить кошечку;important;1686588922;false;1686585922;NULL"
        let result = TodoItem.parse(CSVLine: input)
        XCTAssertNotNil(result)
        if result == nil { return }
        XCTAssertEqual(result!.id, "7269829")
        XCTAssertEqual(result!.text, "Погладить кошечку")
        XCTAssertEqual(result!.priority, Priority.important)
        XCTAssertEqual(result!.deadline, Date(timeIntervalSince1970: 1686588922))
        XCTAssertEqual(result!.done, false)
        XCTAssertEqual(result!.creationDate, Date(timeIntervalSince1970: 1686585922))
        XCTAssertEqual(result!.modificationDate, nil)
    }
    
    func testFromCSV_line_missingData() {
        let input = "7269829;Погладить кошечку;important;1686588922;1686585922;NULL"
        let result = TodoItem.parse(CSVLine: input)
        XCTAssertNil(result)
    }
    
    func testFromCSV_multiple() throws {
        let input = """
                    7269829;Погладить кошечку;important;1686588922;false;1686585922;NULL
                    9287710;Посадить цветочек;unimportant;NULL;false;1686585922;1686587922
                    """
        let result = TodoItem.parse(CSVMultiple: input)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "7269829")
        XCTAssertEqual(result[1].id, "9287710")
    }
    
    func testToCSV() {
        
        let input = TodoItem(id: "1234", text: "Hello", priority: .important, deadline: Date(timeIntervalSince1970: 1234), done: false, creationDate: Date(timeIntervalSince1970: 5678), modificationDate: Date(timeIntervalSince1970: 9012))
        let output = input.csv
        XCTAssertEqual(output, "1234;Hello;important;1234.0;false;5678.0;9012.0")
    }

}
