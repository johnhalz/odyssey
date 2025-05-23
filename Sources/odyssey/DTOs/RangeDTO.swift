//
//  RangeDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 14.05.2025.
//

import Fluent
import Vapor

struct RangeDTO: Content {
    var id: UUID?
    var lower: ValueDTO
    var upper: ValueDTO
}
