## Przenoszenie naszego projektu SwiftUI do MVVM, część 1

### Wprowadzenie do MVVM

W tym artykule będziemy używać wzorca projektowego MVVM (Model-View-ViewModel), aby przejść przez proces konwersji jednego z naszych widoków, które doskonale nadają się do MVVM. To wymaga całkiem sporo pracy, głównie dlatego, że będziesz musiał nauczyć się nowych koncepcji po drodze, ale jak tylko opanujesz MVVM, stanie się to łatwiejsze.

Nie chcę przytłaczać cię dużą ilością pracy naraz, dlatego w tym artykule przekształcimy jeden widok. W następnym zakończymy pracę, przekształcając więcej widoków, które, moim zdaniem, również nadają się do MVVM, a następnie zakończymy analizując miejsce, gdzie MVVM jest wątpliwej wartości.

Celem tego ćwiczenia jest, że w trakcie jego trwania zdobędziesz naprawdę dobrą koncepcję działania MVVM: gdzie działa dobrze z SwiftUI, gdzie działa tak sobie, a gdzie SwiftUI naprawdę jest przeciwnikiem.

Ale najpierw muszę przynajmniej wyjaśnić, jak działa MVVM, ponieważ mogłeś słyszeć mnie mówiącego o tym wielokrotnie i nie do końca rozumiesz. Jeśli już korzystałeś z MVVM, możesz śmiało przejść do kolejnej części!

MVVM oznacza Model View ViewModel i to jest naprawdę głupia nazwa, która często wprowadza ludzi w błąd. Szczerze mówiąc, nie wiem, co Microsoft myślał, gdy wymyślali to pojęcie w 2005 roku, ponieważ ta jedna nazwa od tego czasu wprowadza w błąd setki tysięcy uczących się osób.

Oto co najważniejsze, co musisz wiedzieć:

- MVVM to małe udoskonalenie wzorca MVC (Model-View-Controller), który jest sprawdzoną metodą tworzenia aplikacji iOS przy użyciu UIKit.
- W 2004 roku pewien pan o nazwisku Martin Fowler zaproponował alternatywę dla MVC, wprowadzając nowy rodzaj obiektu o nazwie prezentacja modelu, który jest przeznaczony do przechowywania stanu twojej aplikacji niezależnie od interfejsu użytkownika.
- Model prezentacji to klasa, która może w pełni reprezentować twój widok, ale bez jakiejkolwiek przynależności do UIKit lub AppKit. Powinna ona być w stanie odczytywać dane modelu i wszystkie przekształcenia, które są potrzebne, aby przygotować te dane do prezentacji, bez tworzenia widoków.
- Oznacza to, że możesz pisać testy dla wszystkiego, co robi twój model prezentacji, ponieważ można mu dostarczyć dowolne dane i otrzymać odpowiedź, którą można sprawdzić.
- Chociaż model prezentacji pomaga w testowalności, wprowadza on znaczny problem: jeśli wszystkie modele prezentacji przechowują stan aplikacji, a wszystkie widoki wyświetlają stan aplikacji, jak zsynchronizować te dwa?
- Właśnie tu z pomocą przychodzi MVVM: wprowadza on mechanizmy powiązań danych, aby nie trzeba było pisać żadnego zbędnego kodu łączącego widoki z modelami prezentacji.
- I to tyle.

Tak więc modele prezentacji pozwalają nam pisać klasy, które przechowują stan interfejsu użytkownika niezależnie od samego interfejsu, włączając w to wszelkie przekształcenia wymagane do konwersji danych z modelu na widok prezentujący te dane. MVVM bierze tę ideę i dodaje do niej powiązania danych, więc zmiany w interfejsie użytkownika automatycznie zmieniają dane w modelu widoku, a zmiany w modelu widoku automatycznie aktualizują interfejs użytkownika.

O ile mi wiadomo, Apple nigdy nie wspomniało o MVVM na scenie, przynajmniej do daty, w której piszę ten tekst. Nawet podczas prezentacji poświęconych architekturze Apple nie wspominało o MVVM, Redux, MVC ani o żadnym innym konkretnym wzorcu, których jest zwolennikiem. Nie wiem, czy to jest spowodowane syndromem "nie wynaleźliśmy tego sami" - czyli ideą, że używa się tylko i poleca rzeczy, które się samemu wynalazło - czy może Apple po prostu nie wie dokładnie, co polecać.

W każdym razie ważne jest to, że mam nadzieję, że słowo "powiązania danych" skojarzyło ci się ze SwiftUI, ponieważ powiązania leżą u podstaw działania SwiftUI.

 Oznacza to, że MVVM często świetnie pasuje do aplikacji SwiftUI, ale nie jest wymagany. Chcę to jasno podkreślić: MVVM nie jest wymagane do pracy z SwiftUI.

Słyszałem, że niektórzy próbują twierdzić, że nie da się robić SwiftUI bez MVVM, ale to po prostu nieprawda - istnieje wiele sposobów strukturyzowania aplikacji, a MVVM to tylko jeden z nich. W rezultacie najlepszym sposobem na wdrożenie MVVM w projekcie może być po prostu jego nieimplementowanie.

W rzeczywistości chciałbym, żebyś zastanowił się nad tym, jak zorganizowaliśmy nasz kod dotychczas i mam nadzieję, że zauważysz dwie rzeczy:

- Pracowaliśmy ciężko, aby przenieść logikę i akcje z wnętrza ciała widoku, aż do tworzenia jednoliniowych zamknięć w postaci metod.
- Prawie wszystkie przekształcenia danych, takie jak formatowanie i obsługa opcjonalności, odbywają się w rozszerzeniach Tag i Issue; przenieśliśmy tę pracę do naszego modelu.
- Oba te elementy zapewniają możliwość ponownego użycia i testowalności, bez dodatkowej złożoności dedykowanych typów ViewModel. Jak już wspomniałem wcześniej, to prowadzi do architektury Model Controller, gdzie V dostarcza samo SwiftUI.

Moim zdaniem to, co mamy teraz, doskonale pasuje do SwiftUI, ale chcę jednak rozmawiać o MVVM. Robię to z trzech powodów:

- Jeśli tego nie zrobię, to będę otrzymywać skargi. Już wielu ludzi pytało mnie, kiedy będzie omawiane MVVM w kursie, i nie chcę, żebyście myśleli, że przypadkowo o tym zapomniałem.
- Jeśli tego nie omówimy, możesz pomyśleć, że idziesz na rozmowę kwalifikacyjną z brakującą wiedzą - "dlaczego nie użyłeś MVVM?" Przynajmniej po tej części kursu będziesz lepiej przygotowany.
- Będziemy używać MVVM w sposób pragmatyczny. Pokażę ci, gdzie działa dobrze, a gdzie mniej dobrze - nie podzielam fanatyzmu, który często słychać u astronautów architektury.

Dobrze, to wystarczy tła - przejdźmy do kodu!





### Przenoszenie widoku **SidebarView** do architektury **MVVM**

Zacznijmy od widoku, który ma dużo logiki, czyli **SidebarView**. Chociaż już pracowaliśmy nad wyodrębnieniem logiki z ciała tego widoku, sama struktura **SidebarView** nadal wykonuje wiele pracy. Zamierzamy to naprawić, przenosząc duże części **SidebarView** do jego własnego **modelu widoku (ViewModel)**, który będzie odpowiedzialny za obsługę niemal całego przepływu danych w widoku.

Najpierw naciśnij Cmd+N, aby utworzyć nowy plik Swift i nazwij go **SidebarViewModel.swift**. Ten plik będzie zawierać **import Foundation** na górze, co jest w porządku - wyraźnie nie chcemy korzystać tutaj z części **SwiftUI**, ponieważ próbujemy unikać przenoszenia jakiejkolwiek części interfejsu użytkownika do naszego **modelu widoku (ViewModel)**. Jednak potrzebujemy korzystać z **Core Data**, ponieważ nasz **model widoku (ViewModel)** jest odpowiedzialny za przesyłanie danych między naszym widokiem (**SidebarView**), a naszym modelem, który oparty jest na **Core Data**.

Następnie zmodyfikuj importy w pliku na coś takiego:

```swift
import CoreData
import Foundation
```

Następnie zdefiniujmy absolutne minimum, które potrzebujemy w tym **modelu widoku (ViewModel)**. Pamiętaj, że **modele widoku (ViewModel)** muszą być w stanie automatycznie aktualizować interfejs użytkownika, gdy zmieniają się dane podstawowe, a w terminologii **SwiftUI** oznacza to korzystanie z protokołu **ObservableObject** - jest to typ, który ogłasza aktualizacje interfejsu użytkownika.

Zaraz po tym, jak chcesz przyjąć protokół **ObservableObject**, musisz użyć klasy, więc teraz możemy napisać nasz pierwszy kod w pliku **SidebarViewModel.swift**:

```swift
extension SidebarView {
    class **ViewModel**: **ObservableObject** {

    }
}
```

Zauważ, że umieściłem to w rozszerzeniu na temat **SidebarView**? To pozwala mi swobodnie używać nazwy **ViewModel**, ponieważ jest zagnieżdżona wewnątrz **SidebarView** - tak naprawdę to **SidebarView.ViewModel**, ale ten sposób pozwala uniknąć zanieczyszczania przestrzeni nazw **modelami widoku (ViewModel)**, które mają zastosowanie tylko w jednym miejscu.

Następnie przyjrzyjmy się plikowi **SidebarView.swift**: które części z tego widoku naprawdę nie powinny być w nim bezpośrednio? Kilka rzeczy przychodzi mi na myśl:

- Właściwość **tags** i jej odpowiednik **tagFilters**.
- Wszystkie trzy właściwości związane z nadawaniem nazw tagom.
- Obie metody **delete()** i obie metody **rename()**.
- Właściwość **dataController**, ponieważ dostęp do danych będzie realizowany za pośrednictwem **modelu widoku (ViewModel)**.

Tak, to praktycznie wszystko, i to jest celowe: pozostawia kod widoku tylko dla widoku, z całą funkcjonalnością wydzieloną gdzie indziej.

Zaczniemy od przenoszenia kodu w całości z widoku do naszego **modelu widoku (ViewModel)**. To nie będzie działać, nawet po niewielkiej oczyszczającej pracy, ale to ważny pierwszy krok.

Więc:

- Przenieś obie metody **delete()**, **rename()** i **completeRename()** z **SidebarView** do **ViewModel**.
- Przenieś wszystkie właściwości oprócz **smartFilters** i **dataController** także do **ViewModel**.
- Usuń właściwość **dataController** z **SidebarView**.

Ten kod nie będzie nawet trochę działać, ale to w porządku - to początek!

Zamiast przechowywać te właściwości w **SidebarView**, przenieśliśmy je do naszego **modelu widoku (ViewModel)**. To pozostawia w **SidebarView** prawie nic, co jest świetne!

Mimo to potrzebujemy jednej nowej właściwości w **SidebarView**, aby zainicjować i przechowywać **model widoku (ViewModel)** dla tego widoku. Czasami możesz chcieć przekazywać ten **model widoku (ViewModel)** z innych miejsc, ale tutaj nie jest to wymagane - możemy tworzyć i zarządzać nim lokalnie, ponieważ nikt inny nie potrzebuje dostępu do tych danych.

Więc proszę dodaj to do **SidebarView** obok właściwości **smartFilters**:

```swift
@StateObject private var **viewModel**: **ViewModel**
```

I to wszystko, nasz **model widoku (ViewModel)** jest gotowy, prawda? Cóż, nie - nasz kod jest teraz absolutnym bałaganem z błędami kompilacji, więc przyjrzyjmy się oczyszczaniu...

### Porządkowanie bałaganu

Zacznijmy od naprawienia ViewModel, ponieważ nie ma zbyt wielu problemów. Będziemy tu postępować dwuetapowo: najpierw szybkim i brudnym skrótem, aby lepiej zrozumieć, co dzieje się za kulisami, a następnie dłuższym rozwiązaniem, które znacznie poprawi sytuację.

Po pierwsze, chcę, abyś dodał na górze pliku **SidebarViewModel.swift** import SwiftUI.

Tak, wiem, że powiedziałem, że nie chcemy tego. Jak wspomniałem, to szybki i brudny skrót, a wkrótce zrobimy to lepiej, ale na razie to jest pomocne - uwierz mi!

Po drugie, potrzebujemy dostępu do klasy **DataController** w naszym modelu widoku, ponieważ to tam znajduje się cały dostęp do danych. Teraz nie możemy odczytywać tego z otoczenia SwiftUI, ponieważ SwiftUI nie czyni dostępnych wszystkich tych danych w każdej klasie. Zamiast tego musimy przekazać go za pomocą wstrzykiwania zależności - musimy odczytać to w **SidebarView**, a następnie przekazać do modelu widoku stamtąd.

Oznacza to dwie rzeczy, zaczynając od dodania nowej właściwości do przechowywania dostępu do kontrolera danych:

```swift
var dataController: DataController
```

A następnie tworzenie inicjalizatora do otrzymywania wartości dla tej właściwości i przechowywania jej:

```swift
init(dataController: DataController) {
    self.dataController = dataController
}
```

To usunie wszystkie błędy w **ViewModel**, co jest dużym krokiem naprzód.

Ostatnią poprawką przed przejściem dalej jest usunięcie części **@State private** z właściwości - to już nie jest potrzebne, a właściwości powinny być oznaczone jako **@Published**, aby za każdym razem, gdy się zmieniają, aktualizować odpowiednie widoki SwiftUI.

Teraz, w pliku **SidebarView**, nadal mamy stosy błędów, ale ogromna ich większość może zostać rozwiązana poprzez dodanie przedrostka **viewModel** do problemu. Na przykład:

- Zmiana **$dataController.selectedFilter** na **$viewModel.dataController.selectedFilter**
- Zmiana **ForEach(tagFilters)** na **ForEach(viewModel.tagFilters)**
- Zmiana **UserFilterRow(filter: filter, rename: rename, delete: delete)** na **UserFilterRow(filter: filter, rename: viewModel.rename, delete: viewModel.delete)**
- Zmiana **.onDelete(perform: delete)** na **.onDelete(perform: viewModel.delete)**
- Zmiana **$renamingTag** na **$viewModel.renamingTag**
- Zmiana **completeRename** na **viewModel.completeRename**
- Zmiana **$tagName** na **$viewModel.tagName**

To nie obejmuje wszystkich błędów, jednak - struktura podglądu na dole nie będzie zadowolona, a także musimy poprawić, jak **SidebarView** jest tworzone w **ContentView**.

Oba te problemy mają związek z tą samą podstawową kwestią: nasz model widoku musi mieć dostęp do instancji **DataController**, ale nie może go odczytać z otoczenia. Tutaj właśnie wchodzi w grę wstrzykiwanie zależności: musimy dodać nowy inicjalizator do **SidebarView**, który przyjmuje kontroler danych i używa go do stworzenia modelu widoku.

Dodaj ten nowy inicjalizator do **SidebarView**:

```swift
init(dataController: DataController) {
    let viewModel = ViewModel(dataController: dataController)
    _viewModel = StateObject(wrappedValue: viewModel)
}
```

Jak widzisz, nie przechowujemy **dataController** nigdzie w **SidebarView** samym w sobie, po prostu przekazujemy wartości bezpośrednio do modelu widoku.

Teraz pozostaje nam tylko upewnić się, że inicjalizujemy **SidebarView** tymi dwoma wartościami. Po pierwsze, w strukturze podglądu:

```swift
SidebarView(dataController: DataController.preview)
```

Tak, możemy usunąć **environment object**, ponieważ już ich nie używamy.

I na koniec, w **ContentView**, musimy przekazać aktualny aktywny kontroler danych bezpośrednio do **SidebarView**, aby mogło zostać przekazane do modelu widoku:

```swift
SidebarView(dataController: dataController)
```

I teraz, w końcu, nasz kod kompiluje się czysto! Uruchom teraz aplikację i naciśnij przycisk **Dodaj przykłady** w **SidebarView**, aby upewnić się, że dane zostały zresetowane.

I powinieneś zobaczyć... czekać, nic? Tak, nic - żadne tagi nie będą teraz widoczne, chociaż jeśli wybierzesz **Wszystkie problemy**, to przynajmniej pokaże trochę danych, ale tylko dlatego, że nie zmieniliśmy jeszcze tej części projektu!

Więc po całej tej pracy nasza aplikacja jest jakoś gorsza niż była wcześniej.

### Co właśnie się stało?

Właśnie dokonaliśmy sporej ingerencji w kod **SidebarView**, dzieląc go na dwie części: jedną dla wszystkiego, co jest rysowane lub interaktywne na ekranie, a drugą dla naszych właściwych danych. Nie napisaliśmy nowego kodu - wręcz przeciwnie, przenieśliśmy istniejący kod w większości. Dlaczego więc nie działa?

Cóż, odpowiedź brzmi, że dekorator właściwości **@FetchRequest** w SwiftUI po prostu nie jest przeznaczony do pracy poza widokami. Nie mam na myśli, że jest złą opcją lub działa trochę źle poza widokami - po prostu nie działa. Dlatego, kiedy nie widzisz niczego w widoku **Filters**, oznacza to, że dekorator **@FetchRequest** zupełnie zawodzi; nie wie, jak się zachować teraz, gdy przeniesiony został poza widok.

Wcześniej powiedziałem, że zamierzamy podjąć "szybki i brudny skrót, aby lepiej zrozumieć, co dzieje się za kulisami", teraz widzisz, jak to się dzieje: nasz skrót, polegający na imporcie **SwiftUI**, pozwolił na kompilację kodu, ale nadal nie działa, ponieważ wewnętrznie **@FetchRequest** musi być przypisany bezpośrednio do widoku. To może się zmienić w przyszłości, jeśli Apple to ponownie rozważy, ale obecnie jest to duży problem, ponieważ MVVM wymaga, abyśmy wyizolowali dostęp do danych od widoku.

Aby to naprawić i wprowadzić MVVM, musimy pozbyć się **@FetchRequest** i samodzielnie wykonać żądanie. Jednak nie możemy po prostu użyć **NSFetchRequest** - to wywoła dane raz, ale chcemy, aby nasz widok pozostawał zaktualizowany w miarę zmian w czasie. Oznacza to korzystanie z czegoś bardziej zaawansowanego, zwłaszcza **NSFetchedResultsController**, który przeprowadzi początkowe żądanie odczytu, a także będzie aktualizować dane.

Więc chciałbym, abyś znalazł ten fragment w **SidebarViewModel**:

```swift
@FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var tags: FetchedResults<Tag>
```

I zamienił go na te dwa:

```swift
private let tagsController: NSFetchedResultsController<Tag>
@Published var tags = [Tag]()
```

Istnieje kilka rzeczy, które warto wyjaśnić w tych dwóch liniach kodu:

- Uczyniłem kontroler wyników żądania prywatnym, ponieważ jest to szczegół implementacyjny.
- Jest on również ogólny pod względem **Tag**, więc nie musimy dokonywać żadnych skomplikowanych rzutowań typów.
- Właściwość **tags** jest teraz po prostu tablicą obiektów **Tag**, co jest znacznie lepsze. To izoluje nasze korzystanie z Core Data w modelu widoku - w przyszłości moglibyśmy całkowicie usunąć Core Data, a widok nie wiedziałby o tym.
- Właściwość **tags** jest oznaczona jako **@Published**, dzięki czemu za każdym razem, gdy zmieniamy tablicę, informujemy o tym wszystkie widoki obserwujące.

Teraz, ta zmiana zepsuła inicjalizator naszego modelu widoku, ponieważ nie ustawiamy nowej właściwości **tagsController**. Musimy wykonać cztery kroki, aby to działało.

Po pierwsze, musimy utworzyć żądanie **NSFetchRequest**, które wczytuje nasze dane. Nie wykonujemy tego bezpośrednio, ale przekazujemy je do kontrolera wyników, aby pozostał zaktualizowany.

Już wcześniej utworzyliśmy żądanie **NSFetchRequest** samodzielnie, więc to nie powinno być niczym nowym. Dodaj to w miejsce linii: 

```swift
// more code to come
```

```swift
let request = Tag.fetchRequest()
request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
```

Po drugie, musimy owinąć to żądanie **NSFetchRequest** w **NSFetchedResultsController**. To dodaje nam dodatkową funkcjonalność, taką jak podział danych na sekcje lub korzystanie z pamięci podręcznej, ale my nie chcemy żadnej z tych rzeczy, więc możemy określić wartości nil. Musimy jednak przekazać kontekst obiektu zarządzającego, aby kontroler wiedział, gdzie wykonać żądanie.

Dodaj ten kod poniżej poprzedniego kodu:

```swift
tagsController = NSFetchedResultsController(
    fetchRequest: request,
    managedObjectContext: dataController.container.viewContext,
    sectionNameKeyPath: nil,
    cacheName: nil
)
```

Po trzecie, musimy ustawić klasę modelu widoku jako delegata kontrolera wyników żądania odczytu, aby ten mógł nas powiadomić, gdy dane zostaną w jakiś sposób zmienione. To wymaga trzech małych kroków, ale chcę, abyś mógł zrozumieć, dlaczego każdy z nich jest potrzebny.

Dodaj tę linię poniżej poprzednich, aby model widoku stał się delegatem swojego kontrolera wyników żądania odczytu:

```swift
tagsController.delegate = self
```

To spowoduje natychmiastowy błąd, ponieważ nasza klasa nie jest zgodna z protokołem **NSFetchedResultsControllerDelegate**. Zmodyfikuj klasę tak, aby wyglądała następująco:

```swift
class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
```

Dodaje zarówno **NSFetchedResultsControllerDelegate**, jak i **

NSObject**, ponieważ to drugie jest wymagane przez pierwsze.

I teraz dostajemy kolejny błąd na linii delegata, ponieważ używamy **self** przed wywołaniem **super.init()**. Jest to konieczne, ponieważ teraz dziedziczymy z **NSObject**, więc musimy dać tej klasie szansę na stworzenie siebie, zanim zmienimy delegata naszego kontrolera wyników żądania odczytu.

Oznacza to umieszczenie **super.init()** przed linią delegata, tak jak tutaj:

```swift
super.init()
tagsController.delegate = self
```

Teraz możemy ukończyć nowy inicjalizator, wykonując żądanie odczytu i przypisując je do właściwości **tags**:

```swift
do {
    try tagsController.performFetch()
    tags = tagsController.fetchedObjects ?? []
} catch {
    print("Failed to fetch tags")
}
```

To ukończa nasz inicjalizator, a nasz kod powinien kompilować się bez błędów. Co więcej, jeśli uruchomisz aplikację, zobaczysz, że przykładowe znaczniki użytkownika są teraz widoczne w widoku **Filters**.

Więc jest lepiej, ale nadal nie jest idealnie. Spróbuj ponownie nacisnąć przycisk **Dodaj przykłady**, na przykład - wszystkie te przykładowe znaczniki, które mieliśmy, znikną, ponieważ ich wiersze pozostaną, ale ich zawartość zniknie.

Dzieje się tak dlatego, że dodanie nowych danych przykładowych czyści wszystko, co mieliśmy dotychczas, i zastępuje to nowymi danymi. Nie powiedzieliśmy naszemu interfejsowi, jak ma się aktualizować, gdy te zmiany zachodzą, więc widzi tylko zniknięcie tytułów wszystkich znaczników, które mieliśmy wcześniej.

Tu właśnie przychodzi delegat **NSFetchedResultsController** do gry, ponieważ jeśli zaimplementujemy metodę o nazwie **controllerDidChangeContent()** w naszym modelu widoku, to zostaniemy powiadomieni, gdy dane zostaną zmienione. Możemy wtedy wyciągnąć nowo zaktualizowane obiekty i przypisać je do naszej tablicy **tags**, co z kolei spowoduje, że jej właściwość **@Published** ogłosi aktualizację naszemu interfejsowi użytkownika.

Dodaj tę metodę do modelu widoku teraz:

```swift
func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    if let newTags = controller.fetchedObjects as? [Tag] {
        tags = newTags
    }
}
```

Teraz naprawdę wróciliśmy do stanu, w którym byliśmy wcześniej - cały interfejs użytkownika jest taki sam, a nasz model widoku działa tak, jak powinien.

Co więcej, możemy mieć pewność, że nasze zmiany są bezpieczne, ponieważ wszystkie nasze testy wciąż przechodzą: nasz projekt wygląda dobrze i działa dobrze.

Przezrobiliśmy naprawdę dużo w tym artykule i mam nadzieję, że zaczynasz rozumieć, jak działa MVVM, jakie ma zalety i gdzie nie do końca pasuje do SwiftUI. Ale to jeszcze nie koniec - w kolejnym artykule przyjrzymy się innym widokom w naszej aplikacji, aby zobaczyć, jak MVVM tam pasuje, bo jest jeszcze wiele do nauki!

Porada: Teraz, gdy skończyliśmy porządkować **SidebarViewModel**, możesz usunąć import **SwiftUI** z tego pliku.