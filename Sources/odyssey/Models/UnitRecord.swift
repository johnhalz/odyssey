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

    @Field(key: "archived_unit")
    var archivedUnit: String

    init() {}

    init(unit: Unit) throws {
        self.unitType = String(describing: type(of: unit))
        self.unitSymbol = unit.symbol

        let nsUnit = unit as Unit
        let data = try NSKeyedArchiver.archivedData(withRootObject: nsUnit, requiringSecureCoding: true)
        self.archivedUnit = data.base64EncodedString()
    }

    func decodedUnit() throws -> Unit {
        guard let data = Data(base64Encoded: archivedUnit) else {
            throw Abort(.internalServerError, reason: "Invalid base64 for unit")
        }
        guard let nsUnit = try NSKeyedUnarchiver.unarchivedObject(ofClass: Unit.self, from: data) else {
            throw Abort(.internalServerError, reason: "Failed to decode NSUnit")
        }
        return nsUnit
    }
}
