// CatalogLoadState.swift

actor CatalogLoadState {
    private(set) var hasLoaded = false

    func recordLoad() {
        hasLoaded = true
    }
}
