//
//  UnitRecord.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Vapor
import Fluent

final class UnitRecord: Model, Content, @unchecked Sendable {
    static let schema = "unit_records"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "unit_type")
    var unitType: String

    @Field(key: "unit_symbol")
    var unitSymbol: String

    init() {}

    init(unit: Unit) throws {
        self.unitType = String(describing: type(of: unit))
        self.unitSymbol = unit.symbol
    }
    
    init(unitDTO: UnitDTO) throws {
        self.unitType = unitDTO.unitType
        self.unitSymbol = unitDTO.unitSymbol
    }
}
