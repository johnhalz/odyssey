//
//  Value.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Fluent
import Vapor

public enum ValueType: String, Codable, Sendable {
    case string, integer, decimal, array
}

public final class Value: Model, Content, @unchecked Sendable {
    public static let schema = "values"

    @ID(key: .id)
    public var id: UUID?

    @Enum(key: "type")
    public var valueType: ValueType

    @Field(key: "string")
    public var string: String?

    @Field(key: "integer")
    public var integer: Int?

    @Field(key: "decimal")
    public var decimal: Decimal?

    @Field(key: "array")
    public var array: [Decimal]?

    @OptionalParent(key: "unit_id")
    public var unit: UnitRecord?

    public init() {}

    public init(
        id: UUID? = nil, valueType: ValueType, string: String? = nil, integer: Int? = nil,
        decimal: Decimal? = nil, array: [Decimal]? = nil, unitID: UnitRecord.IDValue? = nil
    ) {
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
    public struct Create: Content {
        public var string: String?
        public var integer: Int?
        public var decimal: Decimal?
        public var array: [Decimal]?
        public var unit: UnitRecord?

        public var hasOnlyOneNonNilValue: Bool {
            let nonNilCount = [string as Any, integer as Any, decimal as Any, array as Any]
                .compactMap { $0 }.count
            return nonNilCount == 1
        }
    }
}

extension Value.Create: Validatable {
    public static func validations(_ validations: inout Validations) {}
}
