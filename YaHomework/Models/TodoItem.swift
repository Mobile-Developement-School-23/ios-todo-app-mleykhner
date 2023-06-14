//
//  TodoItem.swift
//  YaHomework
//
//  Created by Максим Лейхнер on 12.06.2023.
//

import Foundation

// Структура удовлетворяет требованиям протоколов Hashable и Equatable,
// что позволяет хранить её экземпляры в сетах. Использование сета
// защищает от дублирования задач
struct TodoItem : Hashable, Equatable {
    let id: String
    let text: String
    let priority: Priority
    let deadline: Date?
    let done: Bool
    let creationDate: Date
    let modificationDate: Date?
    
    init(id: String = UUID().uuidString, text: String, priority: Priority, deadline: Date?, done: Bool, creationDate: Date, modificationDate: Date?) {
        self.id = id
        self.text = text
        self.priority = priority
        self.deadline = deadline
        self.done = done
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }

    // Переопределение оператора сравнения для протокола Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    // Метод вычисления хэша для протокола Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Разбор JSON
extension TodoItem {
    static func parse(json: Any) -> TodoItem? {
        // Пытаемся привести json к типу словаря, и,
        // если это удаётся, пытаемся получить значения
        // для обязательных полей данных
        guard let dictionary = json as? [String: Any],
              let text = dictionary["text"] as? String,
              let done = dictionary["done"] as? Bool,
              let priority = Priority(rawValue: dictionary["priority"] as? String ?? "normal")
        else {
            // Упс... не получилось
            return nil
        }

        // Если в json'е не было айдишника - генерируем новый
        let id = dictionary["id"] as? String ?? UUID().uuidString

        // Даты храним в формате Unix Timestamp
        // Если дату создания не получилось достать из json'а,
        // записываем текущую
        let unixCDate = dictionary["creationDate"] as? Double
        let creationDate = unixCDate != nil ? Date(timeIntervalSince1970: unixCDate!) : Date()

        let unixMDate = dictionary["modificationDate"] as? Double
        let modificationDate = unixMDate != nil ? Date(timeIntervalSince1970: unixMDate!) : nil

        let unixDeadline = dictionary["deadline"] as? Double
        let deadline = unixDeadline != nil ? Date(timeIntervalSince1970: unixDeadline!) : nil

        // Создаём новый тудуайтем и возвращаем его
        return TodoItem(id: id,
                text: text,
                priority: priority,
                deadline: deadline,
                done: done,
                creationDate: creationDate,
                modificationDate: modificationDate)
    }

    // Вычислимое свойство json
    var json: Any {
        get {
            // Сразу кладём в словарь обязательные поля
            var result: [String: Any] = ["id": id,
                                         "text": text,
                                         "done": done,
                                         "creationDate": creationDate.timeIntervalSince1970]
            // А дальше - только то что необходимо
            if priority != .normal {
                result["priority"] = priority.rawValue
            }
            if let dDate = deadline {
                result["deadline"] = dDate.timeIntervalSince1970
            }
            if let mDate = modificationDate {
                result["modificationDate"] = mDate.timeIntervalSince1970
            }
            return result
        }
    }
}

// Разбор CSV
extension TodoItem {
    static func parse(csv line: String, separator: String = ";") -> TodoItem? {
        let dataCells = line.split(separator: separator).map { element -> String? in
            if element == "NULL" { return nil }
            return String(element)
        }
        
        guard dataCells.count == 7,
              let text = dataCells[1],
              let priority = Priority(rawValue: dataCells[2] ?? "normal"),
              let doneString = dataCells[4],
              let done = Bool(doneString)
        else {
            return nil
        }
        
        let id = dataCells[0] != nil ? dataCells[0]! : UUID().uuidString
        
        let unixDeadline = dataCells[3] != nil ? Double(dataCells[3]!) : nil
        let deadline = unixDeadline != nil ? Date(timeIntervalSince1970: unixDeadline!) : nil
        
        let unixCDate = dataCells[5] != nil ? Double(dataCells[5]!) : nil
        let creationDate = unixCDate != nil ? Date(timeIntervalSince1970: unixCDate!) : Date()
        
        let unixMDate = dataCells[6] != nil ? Double(dataCells[6]!) : nil
        let modificationDate = unixMDate != nil ? Date(timeIntervalSince1970: unixMDate!) : nil
        
        return TodoItem(id: id,
                        text: text,
                        priority: priority,
                        deadline: deadline,
                        done: done,
                        creationDate: creationDate,
                        modificationDate: modificationDate)
        
    }
    
    var csv: String {
        get {
            let deadlineString = deadline != nil ? deadline!.timeIntervalSince1970.description : "NULL"
            let creationDateString = creationDate.timeIntervalSince1970.description
            let modificationDateString = modificationDate != nil ? modificationDate!.timeIntervalSince1970.description : "NULL"
            let priorityString = priority != .normal ? priority.rawValue : "NULL"
            return "\(id);\(text);\(priorityString);\(deadlineString);\(done.description.lowercased());\(creationDateString);\(modificationDateString)"
        }
    }
}
