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

class DataController: ObservableObject {
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

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Main")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

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
            "ul. Marszałkowska 1, 00-001 Warsaw, Poland",
            "ul. Floriańska 23, 31-019 Kraków, Poland",
            "ul. Świdnicka 18, 50-068 Wrocław, Poland",
            "ul. Piotrkowska 155, 90-006 Łódź, Poland",
            "ul. Słowackiego 16, 80-257 Gdańsk, Poland",
            "ul. 3 Maja 12, 40-097 Katowice, Poland",
            "ul. Grunwaldzka 67, 60-001 Poznań, Poland",
            "ul. Basztowa 27, 35-005 Rzeszów, Poland",
            "ul. Armii Krajowej 5, 70-001 Szczecin, Poland",
            "ul. Karmelicka 8, 20-010 Lublin, Poland",
            "ul. Mickiewicza 21, 05-123 Chotomów, Poland",
            "ul. Piękna 46, 15-123 Białystok, Poland",
            "ul. Kilińskiego 8, 25-123 Kielce, Poland",
            "ul. Złota 61, 75-344 Koszalin, Poland",
            "ul. Długa 29, 85-123 Bydgoszcz, Poland",
            "ul. Wyszyńskiego 17, 58-123 Legnica, Poland",
            "ul. Wojska Polskiego 56, 44-100 Gliwice, Poland",
            "ul. Bohaterów 26, 95-123 Skierniewice, Poland",
            "ul. Zielona 34, 48-123 Oława, Poland",
            "ul. Sienkiewicza 42, 64-123 Leszno, Poland",
            "ul. Nowy Świat 12, 00-400 Warsaw, Poland",
            "ul. Krakowskie Przedmieście 20, 00-325 Warsaw, Poland",
            "ul. Chmielna 33, 00-021 Warsaw, Poland",
            "ul. Żelazna 45, 00-838 Warsaw, Poland",
            "ul. Emilii Plater 9, 00-669 Warsaw, Poland",
            "ul. Wilcza 23, 00-544 Warsaw, Poland",
            "ul. Świętokrzyska 14, 00-050 Warsaw, Poland",
            "ul. Sienna 59, 00-820 Warsaw, Poland",
            "ul. Smolna 37, 00-375 Warsaw, Poland",
            "ul. Wspólna 51, 00-687 Warsaw, Poland",
            "ul. Mickiewicza 12, 40-092 Katowice, Poland",
            "ul. Kościuszki 32, 41-902 Bytom, Poland",
            "ul. 3 Maja 24, 43-300 Bielsko-Biała, Poland",
            "ul. Krasińskiego 17, 44-100 Gliwice, Poland",
            "ul. Sienkiewicza 45, 44-190 Knurów, Poland",
            "ul. Powstańców 56, 42-200 Częstochowa, Poland",
            "ul. Wyszyńskiego 26, 41-800 Zabrze, Poland",
            "ul. Zamkowa 13, 42-600 Tarnowskie Góry, Poland",
            "ul. Pocztowa 11, 43-400 Cieszyn, Poland",
            "ul. Korfantego 8, 40-166 Katowice, Poland",
            "Plac Wolności 1, 40-078 Katowice, Poland",
            "Plac Grunwaldzki 2, 41-902 Bytom, Poland",
            "Plac Ratuszowy 3, 43-300 Bielsko-Biała, Poland",
            "Plac Piastowski 4, 44-100 Gliwice, Poland",
            "Plac Wolności 5, 44-190 Knurów, Poland",
            "Plac Biegańskiego 6, 42-200 Częstochowa, Poland",
            "Plac Teatralny 7, 41-800 Zabrze, Poland",
            "Plac Rynek 8, 42-600 Tarnowskie Góry, Poland",
            "Plac Wolności 9, 43-400 Cieszyn, Poland",
            "Plac Sejmu Śląskiego 10, 40-166 Katowice, Poland",
            "Plac Wolności 1, 60-967 Poznań, Poland",
            "Plac Mickiewicza 2, 60-770 Poznań, Poland",
            "Plac Kolegiacki 3, 61-841 Poznań, Poland",
            "Plac Wiosny Ludów 4, 61-831 Poznań, Poland",
            "Plac Cyryla Ratajskiego 5, 61-752 Poznań, Poland",
            "Plac Bernardyński 6, 61-839 Poznań, Poland",
            "Plac Andersa 7, 61-894 Poznań, Poland",
            "Plac Świętego Wojciecha 8, 61-108 Poznań, Poland",
            "Plac Dąbrowskiego 9, 60-839 Poznań, Poland",
            "Plac Wolności 10, 60-282 Poznań, Poland"
        ]

        let randomIndex = Int.random(in: 0..<addresses.count)
        return addresses[randomIndex]
    }

}
