//
//  ValueDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 14.05.2025.
//

import Fluent
import Vapor

protocol ValueDTO: Content {}

struct ArrayDTO: ValueDTO {
    var id: UUID?
    var array: [Decimal]
    var unit: UnitDTO?
    
    init(id: UUID? = nil, array: [Decimal], unit: UnitDTO? = nil) {
        self.id = id
        self.array = array
        self.unit = unit
    }
    
    init(value: Value) {
        self.id = value.id
        if let array = value.array {
            self.array = array
        } else {
            self.array = []
        }
        
        if let unit = value.unit {
            self.unit = UnitDTO(unit: unit)
        } else {
            self.unit = nil
        }
    }
}

struct StringDTO: ValueDTO {
    var id: UUID?
    var string: String
    
    init(id: UUID? = nil, string: String) {
        self.id = id
        self.string = string
    }
    
    init(value: Value) {
        self.id = value.id
        
        if let string = value.string {
            self.string = string
        } else {
            self.string = ""
        }
    }
}

struct DecimalDTO: ValueDTO {
    var id: UUID?
    var decimal: Decimal
    var unit: UnitDTO?
    
    init(id: UUID? = nil, decimal: Decimal, unit: UnitDTO? = nil) {
        self.id = id
        self.decimal = decimal
        self.unit = unit
    }
    
    init(value: Value) {
        self.id = value.id
        
        if let decimal = value.decimal {
            self.decimal = decimal
        } else {
            self.decimal = 0.0
        }
        
        if let unit = value.unit {
            self.unit = UnitDTO(unit: unit)
        } else {
            self.unit = nil
        }
    }
}

struct IntegerDTO: ValueDTO {
    var id: UUID?
    var integer: Int
    var unit: UnitDTO?
    
    init(id: UUID? = nil, integer: Int, unit: UnitDTO? = nil) {
        self.id = id
        self.integer = integer
        self.unit = unit
    }
    
    init(value: Value) {
        self.id = value.id
        
        if let integer = value.integer {
            self.integer = integer
        } else {
            self.integer = 0
        }
        
        if let unit = value.unit {
            self.unit = UnitDTO(unit: unit)
        } else {
            self.unit = nil
        }
    }
}
