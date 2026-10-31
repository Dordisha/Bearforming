# Architecture

- App/: SwiftUI lifecycle, root navigation and observable workout store.
- App/Features/: Today, Workout, Journey, Coach and future HistoryImport.
- Sources/FitnessCore/: Foundation-only Codable workout models and local repository.
- Tests/FitnessCoreTests/: persistence and previous-performance tests.
- Data/Fixtures/: synthetic import examples; private exports are ignored.

Local state is versioned JSON in Application Support. Mutations write an atomic snapshot before publishing success. Corrupt/unsupported state blocks edits. Rest uses a wall-clock deadline. No server, cloud sync, analytics, coach model, or importer is connected. Recovery, migration, export/deletion and editing historical workouts remain future work.
