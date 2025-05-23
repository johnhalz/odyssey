//
//  Value.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Fluent
import Vapor

enum ValueType: String, Codable {
    case string, integer, decimal, array
}

final class Value: Model, Content, @unchecked Sendable {
    static let schema = "values"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "type")
    var valueType: ValueType
    
    @Field(key: "string")
    var string: String?
    
    @Field(key: "integer")
    var integer: Int?
    
    @Field(key: "decimal")
    var decimal: Decimal?
    
    @Field(key: "array")
    var array: [Decimal]?
    
    @OptionalParent(key: "unit_id")
    var unit: UnitRecord?
    
    init() {}
    
    init(id: UUID? = nil, valueType: ValueType, string: String? = nil, integer: Int? = nil, decimal: Decimal? = nil, array: [Decimal]? = nil, unitID: UnitRecord.IDValue? = nil) {
        self.id = id
        self.valueType = valueType
        self.string = string
        self.integer = integer
        self.decimal = decimal
        self.array = array
        self.$unit.id = unitID
    }
}

extension Value {
    struct Create: Content {
        var string: String?
        var integer: Int?
        var decimal: Decimal?
        var array: [Decimal]?
        var unit: UnitRecord?
        
        var hasOnlyOneNonNilValue: Bool {
            let nonNilCount = [string as Any, integer as Any, decimal as Any, array as Any].compactMap { $0 }.count
            return nonNilCount == 1
        }
    }
}

extension Value.Create: Validatable {
    static func validations(_ validations: inout Validations) {}
}
