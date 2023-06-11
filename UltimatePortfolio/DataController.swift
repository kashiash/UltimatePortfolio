//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 25/02/2023.
//

import CoreData

enum SortType: String {
    case dateCreated = "creationDate"
    case dateModified = "modificationDate"
}

enum Status {
    case all, open, closed
}

/// An environment singleton responsible for managing our Core Data stack, including handling saving,
/// counting fetch requests, tracking awards, and dealing with sample data.
class DataController: ObservableObject {
    /// The lone CloudKit container used to store all data
    let container: NSPersistentCloudKitContainer

    @Published var selectedFilter: Filter? = Filter.all
    @Published var selectedIssue: Issue?

    @Published var filterText = ""
    @Published var filterTokens = [Tag]()

    @Published var filterEnabled = false
    @Published var filterPriority = -1
    @Published var filterStatus = Status.all
    @Published var sortType = SortType.dateCreated
    @Published var sortNewestFirst = true

    private var saveTask: Task<Void, Error>?

    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()

    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else {
            return []
        }

        let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
        let request = Tag.fetchRequest()

        if trimmedFilterText.isEmpty == false {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
        }

        return (try? container.viewContext.fetch(request).sorted()) ?? []
    }

    /// Initializes a data controller, either in memory (for temporary use such as testing and previewing),
    /// or on permanent storage (for use in regular app runs.)
    ///
    /// Defaults to permanent storage.
    /// - Parameter inMemory: Whether to store this data in temporary memory or not.

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Main")

        // For testing and previewing purposes, we create a
        // temporary, in-memory database by writing to /dev/null
        // so our data is destroyed after the app finishes running.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // Make sure that we watch iCloud for all changes to make
        // absolutely sure we keep our local UI in sync when a
        // remote change happens.
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator, queue: .main, using: remoteStoreChanged)

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }

    func remoteStoreChanged(_ notification: Notification) {
        objectWillChange.send()
    }

    func createSampleData() {
        let viewContext = container.viewContext

        for tagCounter in 1...5 {
            let tag = Tag(context: viewContext)
            tag.id = UUID()
            tag.name = "Tag \(tagCounter)"

            for issueCounter in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(tagCounter)-\(issueCounter)"
                issue.content = "Description goes here"
                issue.creationDate = .now
                issue.startDate = .now
                issue.dueDate = .now
                issue.taskAddress = getRandomPolishAddress()
                issue.completed = Bool.random()
                issue.priority = Int16.random(in: 0...2)
                tag.addToIssues(issue)
            }
        }

        try? viewContext.save()
    }
    /// Saves our Core Data context iff there are changes. This silently ignores
    /// any errors caused by saving, but this should be fine because all our attributes are optional.
    func save() {
        saveTask?.cancel()

        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }

    func queueSave() {
        saveTask?.cancel()

        saveTask = Task { @MainActor in
            try await Task.sleep(for: .seconds(3))
            save()
        }
    }

    func delete(_ object: NSManagedObject) {
        objectWillChange.send()
        container.viewContext.delete(object)
        save()
    }

    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        // When performing a batch delete we need to make sure we read the result back
        // then merge all the changes from that result back into our live view context
        // so that the two stay in sync.
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }

    func deleteAll() {
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(request1)
        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        delete(request2)
        save()
    }

    func missingTags(from issue: Issue) -> [Tag] {
        let request = Tag.fetchRequest()
        let allTags = (try? container.viewContext.fetch(request)) ?? []

        let allTagsSet = Set(allTags)
        let difference = allTagsSet.symmetricDifference(issue.issueTags)

        return difference.sorted()
    }

    /// Runs a fetch request with various predicates that filter the user's issues based
    /// on tag, title and content text, search tokens, priority, and completion status.
    /// - Returns: An array of all matching issues.
    func issuesForSelectedFilter() -> [Issue] {
        let filter = selectedFilter ?? .all
        var predicates = [NSPredicate]()

        if let tag = filter.tag {
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            let datePredicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
        }

        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)

        if trimmedFilterText.isEmpty == false {
            let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
            let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
            let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
                                                            [titlePredicate, contentPredicate])
            predicates.append(combinedPredicate)
        }

        if filterTokens.isEmpty == false {
            for filterToken in filterTokens {
                let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
                predicates.append(tokenPredicate)
            }
        }

        if filterEnabled {
            if filterPriority >= 0 {
                let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
                predicates.append(priorityFilter)
            }

            if filterStatus != .all {
                let lookForClosed = filterStatus == .closed
                let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
                predicates.append(statusFilter)
            }
        }

        let request = Issue.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]
        let allIssues = (try? container.viewContext.fetch(request)) ?? []
        return allIssues
    }

    func newTag() {
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = NSLocalizedString("New tag", comment: "Create a new tag")
        save()
    }

    func newIssue() {
        let issue = Issue(context: container.viewContext)
        issue.title = NSLocalizedString("New issue", comment: "Create a new issue")
        issue.creationDate = .now
        issue.priority = 1

        // If we're currently browsing a user-created tag, immediately
        // add this new issue to the tag otherwise it won't appear in
        // the list of issues they see.
        if let tag = selectedFilter?.tag {
            issue.addToTags(tag)
        }

        save()

        selectedIssue = issue
    }

    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }

    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
        case "issues":
                    // returns true if they added a certain number of issues
                let fetchRequest = Issue.fetchRequest()
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

        case "closed":
                    // returns true if they closed a certain number of issues
                let fetchRequest = Issue.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "completed = true")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

        case "tags":
                    // return true if they created a certain number of tags
                let fetchRequest = Tag.fetchRequest()
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

        default:
                    // an unknown award criterion; this should never be allowed
                    // fatalError("Unknown award criterion: \(award.criterion)")
        return false
        }
    }
}

extension DataController {
    // swiftlint:disable:next function_body_length
    func getRandomPolishAddress() -> String {
        let addresses = [
            "ul. Marszałkowska 1, 00-001 Warsaw, Poland, Mazowieckie",
            "ul. Floriańska 23, 31-019 Kraków, Poland, Małopolskie",
            "ul. Świdnicka 18, 50-068 Wrocław, Poland, Dolnośląskie",
            "ul. Piotrkowska 155, 90-006 Łódź, Poland, Łódzkie",
            "ul. Słowackiego 16, 80-257 Gdańsk, Poland, Pomorskie",
            "ul. 3 Maja 12, 40-097 Katowice, Poland, Śląskie",
            "ul. Grunwaldzka 67, 60-001 Poznań, Poland, Wielkopolskie",
            "ul. Basztowa 27, 35-005 Rzeszów, Poland, Podkarpackie",
            "ul. Armii Krajowej 5, 70-001 Szczecin, Poland, Zachodniopomorskie",
            "ul. Karmelicka 8, 20-010 Lublin, Poland, Lubelskie",
            "ul. Mickiewicza 21, 05-123 Chotomów, Poland, Mazowieckie",
            "ul. Piękna 46, 15-123 Białystok, Poland, Podlaskie",
            "ul. Kilińskiego 8, 25-123 Kielce, Poland, Świętokrzyskie",
            "ul. Złota 61, 75-344 Koszalin, Poland, Zachodniopomorskie",
            "ul. Długa 29, 85-123 Bydgoszcz, Poland, Kujawsko-Pomorskie",
            "ul. Wyszyńskiego 17, 58-123 Legnica, Poland, Dolnośląskie",
            "ul. Wojska Polskiego 56, 44-100 Gliwice, Poland, Śląskie",
            "ul. Bohaterów 26, 95-123 Skierniewice, Poland, Łódzkie",
            "ul. Zielona 34, 48-123 Oława, Poland, Dolnośląskie",
            "ul. Sienkiewicza 42, 64-123 Leszno, Poland, Wielkopolskie",
            "ul. Nowy Świat 12, 00-400 Warsaw, Poland, Mazowieckie",
            "ul. Krakowskie Przedmieście 20, 00-325 Warsaw, Poland, Mazowieckie",
            "ul. Chmielna 33, 00-021 Warsaw, Poland, Mazowieckie",
            "ul. Żelazna 45, 00-838 Warsaw, Poland, Mazowieckie",
            "ul. Emilii Plater 9, 00-669 Warsaw, Poland, Mazowieckie",
            "ul. Wilcza 23, 00-544 Warsaw, Poland, Mazowieckie",
            "ul. Świętokrzyska 14, 00-050 Warsaw, Poland, Mazowieckie",
            "ul. Sienna 59, 00-820 Warsaw, Poland, Mazowieckie",
            "ul. Smolna 37, 00-375 Warsaw, Poland, Mazowieckie",
            "ul. Wspólna 51, 00-687 Warsaw, Poland, Mazowieckie",
            "ul. Mickiewicza 12, 40-092 Katowice, Poland, Śląskie",
            "ul. Kościuszki 32, 41-902 Bytom, Poland, Śląskie",
            "ul. 3 Maja 24, 43-300 Bielsko-Biała, Poland, Śląskie",
            "ul. Krasińskiego 17, 44-100 Gliwice, Poland, Śląskie",
            "ul. Sienkiewicza 45, 44-190 Knurów, Poland, Śląskie",
            "ul. Powstańców 56, 42-200 Częstochowa, Poland, Śląskie",
            "ul. Wyszyńskiego 26, 41-800 Zabrze, Poland, Śląskie",
            "ul. Zamkowa 13, 42-600 Tarnowskie Góry, Poland, Śląskie",
            "ul. Pocztowa 11, 43-400 Cieszyn, Poland, Śląskie",
            "ul. Korfantego 8, 40-166 Katowice, Poland, Śląskie",
            "Plac Wolności 1, 40-078 Katowice, Poland, Śląskie",
            "Plac Grunwaldzki 2, 41-902 Bytom, Poland, Śląskie",
            "Plac Ratuszowy 3, 43-300 Bielsko-Biała, Poland, Śląskie",
            "Plac Piastowski 4, 44-100 Gliwice, Poland, Śląskie",
            "Plac Wolności 5, 44-190 Knurów, Poland, Śląskie",
            "Plac Biegańskiego 6, 42-200 Częstochowa, Poland, Śląskie",
            "Plac Teatralny 7, 41-800 Zabrze, Poland, Śląskie",
            "Plac Rynek 8, 42-600 Tarnowskie Góry, Poland, Śląskie",
            "Plac Wolności 9, 43-400 Cieszyn, Poland, Śląskie",
            "Plac Sejmu Śląskiego 10, 40-166 Katowice, Poland, Śląskie",
            "Plac Wolności 1, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 2, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 3, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 4, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 5, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 6, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 7, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 8, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 9, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 10, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 11, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 12, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 13, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 14, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 15, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 16, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 17, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 18, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 19, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 20, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 21, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 22, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 23, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 24, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 25, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 26, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 27, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 28, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 29, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 30, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 31, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 32, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 33, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 34, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 35, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 36, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 37, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 38, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 39, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 40, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 41, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 42, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 43, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 44, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 45, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 46, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 47, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 48, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 49, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 50, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 51, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 52, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 53, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 54, 61-775 Poznań, Poland, Wielkopolskie",
            "Plac Wolności 55, 60-967 Poznań, Poland, Wielkopolskie",
            "Plac Mickiewicza 56, 60-770 Poznań, Poland, Wielkopolskie",
            "Plac Kolegiacki 57, 61-841 Poznań, Poland, Wielkopolskie",
            "Plac Wiosny Ludów 58, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Cyryla Ratajskiego 59, 61-831 Poznań, Poland, Wielkopolskie",
            "Plac Wielkopolski 60, 61-775 Poznań, Poland, Wielkopolskie"
        ];


        let randomIndex = Int.random(in: 0..<addresses.count)
        return addresses[randomIndex]
    }

}
