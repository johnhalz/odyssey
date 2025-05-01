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
    
    @Field(key: "decimal")
    var decimal: Decimal?
    
    @Field(key: "array")
    var array: [Decimal]?
    
    @OptionalParent(key: "unit_id")
    var unit: UnitRecord?
    
    init() {}
    
    init(id: UUID? = nil, valueType: ValueType, string: String? = nil, decimal: Decimal? = nil, array: [Decimal]? = nil, unitID: UnitRecord.IDValue? = nil) {
        self.id = id
        self.valueType = valueType
        self.string = string
        self.decimal = decimal
        self.array = array
        self.$unit.id = unitID
    }
}
