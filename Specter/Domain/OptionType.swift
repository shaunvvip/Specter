import Foundation

enum OptionType: Equatable {
    case string
    case integer(range: ClosedRange<Int>)
    case double(range: ClosedRange<Double>)
    case bool
    case enumeration([String])
    case color
    case font
    case theme
    case keybind
    case opaque
}
