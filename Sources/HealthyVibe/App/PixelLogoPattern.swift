enum PixelLogoPattern {
    static let pixels: [[Bool]] = [
        row("   #######      "),
        row(" ##       ##    "),
        row("#  #######  #   "),
        row("# ######### ### "),
        row("# #########    #"),
        row("# ######### #  #"),
        row("#  #######  ## #"),
        row("#           #  #"),
        row("#              #"),
        row("#             # "),
        row("#           ##  "),
        row(" #         #    "),
        row(" #         #    "),
        row("  #       #     "),
        row("   #######      "),
        row("                ")
    ]

    private static func row(_ value: String) -> [Bool] {
        value.map { $0 == "#" }
    }
}
