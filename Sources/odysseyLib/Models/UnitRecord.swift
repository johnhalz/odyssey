//
//  UnitRecord.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Fluent
import Vapor

public final class UnitRecord: Model, Content, @unchecked Sendable {
    public static let schema = "unit_records"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "unit_type")
    public var unitType: String

    @Field(key: "unit_symbol")
    public var unitSymbol: String

    public init() {}

    public init(unit: Unit) throws {
        self.unitType = String(describing: type(of: unit))
        self.unitSymbol = unit.symbol
    }

    public init(unitDTO: UnitDTO) throws {
        self.unitType = unitDTO.unitType
        self.unitSymbol = unitDTO.unitSymbol
    }
}
