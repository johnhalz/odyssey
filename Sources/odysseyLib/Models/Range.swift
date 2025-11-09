//
//  Range.swift
//  odyssey
//
//  Created by John Halazonetis on 13.05.2025.
//

import Fluent
import Vapor

public final class Range: Model, Content, @unchecked Sendable {
    public static let schema = "ranges"

    @ID(key: .id)
    public var id: UUID?

    @Parent(key: "lower_id")
    var lower: Value

    @Parent(key: "upper_id")
    var upper: Value

    public init() {}

    init(id: UUID? = nil, lowerId: Value.IDValue, upperId: Value.IDValue) {
        self.id = id
        self.$lower.id = lowerId
        self.$upper.id = upperId
    }
}
