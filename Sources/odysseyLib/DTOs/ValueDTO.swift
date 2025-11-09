//
//  ValueDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 14.05.2025.
//

import Fluent
import Vapor

public struct ArrayDTO: Content {
    public var id: UUID?
    public var array: [Decimal]
    public var unit: UnitDTO?

    public init(id: UUID? = nil, array: [Decimal], unit: UnitDTO? = nil) {
        self.id = id
        self.array = array
        self.unit = unit
    }

    public init(value: Value) {
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

public struct StringDTO: Content {
    public var id: UUID?
    public var string: String

    public init(id: UUID? = nil, string: String) {
        self.id = id
        self.string = string
    }

    public init(value: Value) {
        self.id = value.id

        if let string = value.string {
            self.string = string
        } else {
            self.string = ""
        }
    }
}

public struct DecimalDTO: Content {
    public var id: UUID?
    public var decimal: Decimal
    public var unit: UnitDTO?

    public init(id: UUID? = nil, decimal: Decimal, unit: UnitDTO? = nil) {
        self.id = id
        self.decimal = decimal
        self.unit = unit
    }

    public init(value: Value) {
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

public struct IntegerDTO: Content {
    public var id: UUID?
    public var integer: Int
    public var unit: UnitDTO?

    public init(id: UUID? = nil, integer: Int, unit: UnitDTO? = nil) {
        self.id = id
        self.integer = integer
        self.unit = unit
    }

    public init(value: Value) {
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

public enum ValueDTO: Content {
    case array(ArrayDTO)
    case string(StringDTO)
    case integer(IntegerDTO)
    case decimal(DecimalDTO)

    enum CodingKeys: String, CodingKey {
        case type, data
    }

    public enum ResponseType: String, Codable {
        case array, string, integer, decimal
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .array(let arrayDTO):
            try container.encode(ResponseType.array, forKey: .type)
            try container.encode(arrayDTO, forKey: .data)
        case .string(let stringDTO):
            try container.encode(ResponseType.string, forKey: .type)
            try container.encode(stringDTO, forKey: .data)
        case .integer(let integerDTO):
            try container.encode(ResponseType.integer, forKey: .type)
            try container.encode(integerDTO, forKey: .data)
        case .decimal(let decimalDTO):
            try container.encode(ResponseType.decimal, forKey: .type)
            try container.encode(decimalDTO, forKey: .data)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ResponseType.self, forKey: .type)

        switch type {
        case .array:
            let dto = try container.decode(ArrayDTO.self, forKey: .data)
            self = .array(dto)
        case .string:
            let dto = try container.decode(StringDTO.self, forKey: .data)
            self = .string(dto)
        case .integer:
            let dto = try container.decode(IntegerDTO.self, forKey: .data)
            self = .integer(dto)
        case .decimal:
            let dto = try container.decode(DecimalDTO.self, forKey: .data)
            self = .decimal(dto)
        }
    }

    public init(value: Value) {
        switch value.valueType {
        case .array:
            self = .array(.init(value: value))
        case .decimal:
            self = .decimal(.init(value: value))
        case .integer:
            self = .integer(.init(value: value))
        case .string:
            self = .string(.init(value: value))
        }
    }
}
