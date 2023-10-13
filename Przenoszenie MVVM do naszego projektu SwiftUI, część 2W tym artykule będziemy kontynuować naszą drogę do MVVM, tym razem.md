# Przenoszenie MVVM do naszego projektu SwiftUI, część 2
W tym artykule będziemy kontynuować naszą drogę do MVVM, tym razem przekształcając kolejne dwa widoki, które działają dobrze, ale także przyglądając się kodowi, który działa mniej dobrze, abyś mógł lepiej zrozumieć, jak SwiftUI i MVVM naprawdę pasują do siebie.

### Prostszy przypadek: ContentView
Drugi widok, który zamierzamy przekształcić, to `ContentView`, i używa większości tych samych technik, które już zastosowaliśmy w `SidebarView` – to doskonała okazja do praktyki tego, czego do tej pory się nauczyłeś.

Podobnie jak poprzednio, zaczniemy od łatwych rzeczy: utworzenia nowego pliku, aby zawierał typ widoku jako rozszerzenie na `ContentView`, przeniesienia właściwości `DataController` do tego miejsca, aby mogło obsługiwać dostęp do danych, oraz przeniesienia metody delete().

Zacznijmy od utworzenia nowego pliku o nazwie ContentViewModel.swift, a następnie dodajmy do niego ten kod:

```swift
extension ContentView {
    class ViewModel: ObservableObject {
        var dataController: DataController

        init(dataController: DataController) {
            self.dataController = dataController
        }
    }
}
```

Mając to gotowe, wróć do ContentView i przenieś jego metodę delete() do nowej klasy ViewModel, którą właśnie utworzyliśmy.

Teraz możemy nadać ContentView inicjalizator, który przekazuje instancję DataController do naszego widoku modelu, ale nie przechowuje jej lokalnie.

Po pierwsze, zaznacz właściwość dataController w ContentView i zastąp ją tym kodem:

```swift
@StateObject var viewModel: ViewModel
```

Po drugie, dodaj ten inicjalizator, aby utworzyć i przechować obiekt stanu widoku modelu:

```swift
init(dataController: DataController) {
    let viewModel = ViewModel(dataController: dataController)
    _viewModel = StateObject(wrappedValue: viewModel)
}
```

Jednocześnie musisz zaktualizować struct podglądu, aby przekazać statyczne dane podglądu:

```swift
ContentView(dataController: .preview)
```

A w UltimatePortfolioApp, gdzie ContentView jest tworzony w naszym podziale nawigacji Split View:

```swift
ContentView(dataController: dataController)
```

Po trzecie i na koniec, musisz naprawić błędy kompilacji spowodowane przeniesieniem właściwości z widoku do widoku modelu. Oznacza to dodanie viewModel. przed każdym wystąpieniem dataController oraz zmianę .onDelete(perform: delete) na .onDelete(perform: viewModel.delete).

I to wszystko dla naszego `ContentView` – jest podobny do `SidebarView` pod względem podejścia, ale znacznie prostszy.

### Praca z wierszami na liście

Uważam, że korzyści płynące z naszych modeli widoku są dość oczywiste: prawie cała logika teraz wychodzi z widoku, co oznacza, że różne rodzaje logiki można teraz testować bez konieczności uciekania się do testów interfejsu użytkownika. Co więcej, Core Data teraz jest szczegółem implementacji naszych modeli widoku - możemy go zastąpić płaskim formatem JSON, jeśli zechcemy, i ani SidebarView, ani ContentView nie będą miały z tym problemu.

Chcę teraz przejrzeć trzeci widok, gdzie możemy zacząć przenosić kod z innych części naszej aplikacji w miejsce, gdzie będzie bardziej odpowiednie.

Tak czy inaczej, zaczniemy od podstaw: utworzenia nowego pliku o nazwie "IssueRowViewModel.swift". Będzie to klasa ViewModel dla naszego widoku IssueRow, podobnie jak w przypadku naszych dwóch poprzednich plików. Nie będzie ona tworzyć kontrolera wyników zapytania, ponieważ nie będzie bezpośrednio ładować żadnych danych - otrzymuje issue (problem), więc musimy je po prostu zachować i pozwolić SwiftUI zająć się resztą.

Zaczniemy od utworzenia tej klasy ViewModel:

```swift
extension IssueRow {
    class ViewModel: ObservableObject {
        let issue: Issue
        
        init(issue: Issue) {
            self.issue = issue
        }
        
        var iconOpacity: Double {
            issue.priority == 2 ? 1 : 0
        }
        
        var iconIdentifier: String {
            issue.priority == 2 ? "\(issue.issueTitle) Wysoki Priorytet" : ""
        }
        
        var accessibilityCreationDate: String {
            issue.issueCreationDate.formatted(date: .abbreviated, time: .omitted)
        }
    }
}
```

Tak, nie musimy oznaczać issue jako observed - zobaczysz dlaczego niedługo.

Ponieważ jest to klasa, a nie struktura, napiszmy własny prosty inicjalizator, który akceptuje Issue, aby je zachować:

```swift
init(issue: Issue) {
    self.issue = issue
}
```

Teraz możemy postępować tak samo jak wcześniej, aby przechować instancję tej nowej klasy wewnątrz IssueRow. Zastąp istniejący `@ObservedObject` tym:

```swift
@StateObject var viewModel: ViewModel
```

Następnie utwórz inicjalizator, który akceptuje nasz issue i przekazuje go bezpośrednio do widoku modelu:

```swift
init(issue: Issue) {
    let viewModel = ViewModel(issue: issue)
    _viewModel = StateObject(wrappedValue: viewModel)
}
```

Teraz dodaj `viewModel.` przed każdym wystąpieniem issue, aby usunąć wszystkie błędy kompilacji. Może się zdarzyć, że wciąż pojawi się ostrzeżenie o długości linii w dwóch miejscach, ale na razie to nic strasznego.

To jest podstawowe, choć dość leniwe podejście do wprowadzenia MVVM w tym miejscu, ale mamy okazję przenieść kilka dodatkowych rzeczy z widoku do widoku modelu - małe fragmenty logiki, które wcześniej znajdowały się w właściwościach body widoku lub gdzie indziej, ale teraz mogą być czysto wyciągnięte na zewnątrz.

Na przykład wszystkie trzy miejsca w IssueRow, które odczytują priorytet issue, mogą zostać przeniesione do obliczanych właściwości w jego klasie ViewModel.

Zacznijmy od przeniesienia warunkowego operatora ternarnego wewnątrz modyfikatora `opacity()` do nowej właściwości iconOpacity w widoku modelu, w ten sposób:

```swift
var iconOpacity: Double {
    issue.priority == 2 ? 1 : 0
}
```

Teraz możemy użyć `.opacity(viewModel.iconOpacity)`, co usuwa całą logikę wbudowaną z modyfikatora.

Co do identyfikatora dostępności ikony, to również kolejna właściwość:

```swift
var iconIdentifier: String {
    issue.priority
```

### Gdzie MVVM jest mniej użyteczne
Jest jeszcze jedna część kodu, o której chcę wspomnieć w kontekście MVVM, i to jest przykład, gdzie użycie MVVM staje się mniej oczywistym wyborem. Nie mówię tu "MVVM to zły wybór", tylko uważam, że wady i zalety zaczynają być albo mniej więcej równe, albo nawet przeciwko MVVM.

Chodzi o widok AwardsView: gdyby ten widok miał model widoku, jak by to wyglądało? Cóż, nie przenieślibyśmy już właściwości Awards.allAwards do środka, ponieważ ta właściwość nie jest już przechowywana w naszym widoku, i nie przenieślibyśmy ani selectedAward, ani showingAwardDetails, ponieważ obie te właściwości odnoszą się do naszego widoku.

Jedyną rzeczą, którą naprawdę moglibyśmy przenieść, jest nasz kontroler danych (data controller), ale to naprawdę nie pomaga, ponieważ musielibyśmy umieścić jego metodę hasEarned(award:) w naszym modelu widoku, aby można ją było wywołać w awardTitle. Efektem końcowym jest większa złożoność przy tylko marginalnych korzyściach; jest to możliwe, ale nie jest to jasne rozwiązanie.

Jednakże, to, co nie działa tak dobrze dla mnie, może być idealne dla Ciebie, i niezależnie od tego, czy zdecydujesz się pójść tą drogą, zawsze coś się nauczysz.

Mniej więcej to, na co patrzymy, wygląda tak:

```swift
import SwiftUI

extension AwardsView {
    class ViewModel: ObservableObject {
        let dataController: DataController

        init(dataController: DataController) {
            self.dataController = dataController
        }

        func color(for award: Award) -> Color {
            dataController.hasEarned(award: award) ? Color(award.color) : .secondary.opacity(0.5)
        }

        func label(for award: Award) -> LocalizedStringKey {
            dataController.hasEarned(award: award) ? "Odblokowany: \(award.name)" : "Zablokowany"
        }

        func hasEarned(award: Award) -> Bool {
            dataController.hasEarned(award: award)
        }
    }
}
```

Jak widzisz, większość tego to przekazywanie komunikatów między widokiem a naszą klasą DataController, ale musieliśmy również dodać import SwiftUI, aby uzyskać dostęp do Color i LocalizedStringKey – nie dostajemy zbyt wiele korzyści z testowania. Powiedziałbym, że jest to gorsze niż to, co mamy obecnie, i zachęcam Cię do podjęcia podobnie pragmatycznego wyboru, zamiast zawsze próbować walczyć o określony wzorzec architektoniczny.

Oczywiście, możesz to przetestować i uznać, że działa świetnie, i to w porządku. Wręcz przeciwnie, zachęcam Cię do próbowania takich rzeczy, bo właśnie tak się uczysz! Ale chciałbym, żebyś unikał forsowania swojego kodu w kierunku jednego konkretnego wzorca projektowego za wszelką cenę, ponieważ prowadzi to do wiru utrzymania kodu.

### Enkapsulacja DataController
Nie będę kontynuować forsowania MVVM w tym projekcie, ponieważ myślę, że już zrozumiałeś punkt, ale zanim zakończymy, jest jedna dodatkowa rzecz, którą chcę zaprezentować.

Podejście MVVM, które przyjęliśmy, działa, ale szczerze mówiąc, jest trochę leniwe. Jednym z głównych korzyści z programowania obiektowego jest zdolność do enkapsulacji danych - zatrzymywania eksponowania wewnętrznych części obiektu, tak aby jedna część naszego projektu nie była bezpośrednio zależna od drugiej, chyba że musi.

W naszym nowym kodzie ContentView i IssueView zauważysz rzeczy takie jak viewModel.dataController.selectedIssue, viewModel.dataController.filterText i viewModel.dataController.filterTokens - sięgamy do jednej z właściwości w modelu widoku i odczytujemy wartości stamtąd. Jest to zarówno brzydkie, jak i leniwe, a Swift pozwala nam zrobić to lepiej w większości przypadków.

Moglibyśmy napisać gettery i settery w modelu widoku, które obsługują wszystkie właściwości obiektu, którym zarządza, ale łatwiejszym podejściem jest użycie @dynamicMemberLookup w naszych klasach modelu widoku, a następnie dodanie subscript, który działa jako most między opakowanym obiektem a światem zewnętrznym.

Najlepiej to zademonstrować za pomocą rzeczywistego kodu, więc dostosuj model widoku dla IssueRow do tego:

```swift
extension IssueRow {
    @dynamicMemberLookup
    class ViewModel: ObservableObject {
```

To mówi Swiftowi, że chcemy mieć możliwość dynamicznego przeszukiwania nazw członków - czyli właściwości - w czasie działania programu. Jak to się dzieje, możemy zobaczyć w specjalnym subscript, który dodajemy teraz do klasy ViewModel:

```swift
subscript<Value>(dynamicMember keyPath: KeyPath<Issue, Value>) -> Value {
    issue[keyPath: keyPath]
}
```

To dość skomplikowany kod, ale robi coś niesamowitego: teraz możemy uzyskać dostęp do właściwości z issue bezpośrednio w modelu widoku. Więc, wracając do IssueRow, możesz zmienić prawie każde wystąpienie `viewModel.issue` na po prostu `viewModel`, a kod nadal będzie się kompilować - po prostu pozostaw linię NavigationLink bez zmian, ponieważ faktycznie musi przekazać issue.

To, co robi nasz subscript @dynamicMemberLookup, to mówi Swiftowi, że wszystkie właściwości Issue mogą wyglądać tak, jakby istniały w modelu widoku. Tak naprawdę nie istnieją one tam - kod wewnątrz subscript mówi "kiedy użytkownik poprosi o ścieżkę klucza, po prostu przekaż ją do issue i odbierz z niego jej wartość" - ale oznacza to, że reszta naszego kodu jest znacznie czyściejsza.

Oznacza to, że teraz nie eksponujemy w wielu miejscach w tym modelu widoku wewnętrznego Issue, co z kolei oznacza, że możemy zastąpić implementacje w przyszłości - możemy wziąć coś, co obecnie jest dynamicznym przeszukiwaniem członków i zamienić to w obliczeniową właściwość, na przykład.

Podobną pracę możemy wykonać w ContentView, choć wymaga to trochę więcej myślenia, ponieważ selectedIssue, filterText i filterTokens są wszystkimi przechowywanymi właściwościami, które można odczytywać i zapisywać, podczas gdy suggestedFilterTokens jest tylko do odczytu.

Aby to zadziałało, musimy dodać @dynamicMemberLookup do klasy ContentView.ViewModel, a następnie dodać dwa subskrypty:

```swift
subscript<Value>(dynamicMember keyPath: KeyPath<DataController, Value>) -> Value {
    dataController[keyPath: keyPath]
}

subscript