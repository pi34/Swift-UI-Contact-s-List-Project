//
//  ContentView.swift
//  Practice
//
//  Created by Riya Manchanda on 03/06/21.
//

import SwiftUI
import CoreData

struct ContentView: View {

    @State var showNewContactView: Bool = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Contact.entity(), sortDescriptors: [])

    var persons: FetchedResults<Contact>
    @State var searchText: String = ""
    @State var isFocused: Bool = false


    var body: some View {
        
        
 
        NavigationView {
            
            VStack {
                HStack {
                    TextField("Search", text: $searchText)
                        .frame(height: 30)
                        .padding(10)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color("Title"))
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                 
                                if self.isFocused {
                                    Button(action: {
                                        self.searchText = ""
                                    }) {
                                        Image(systemName: "multiply.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 8)
                                    }
                                }
                           }
                 
                        ).onTapGesture {
                            self.isFocused = true
                        }
                 
                    if isFocused {
                        Button(action: {
                        
                            self.isFocused = false
                            self.searchText = ""
                     UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                        }) {
                            Text("Cancel")
                        }
                        .padding(.trailing, 10)
                        .transition(.move(edge: .trailing))
                        .animation(.default)
                    }
                 
                 
                }
                .padding(.horizontal, 15)
                .padding(.top, 15)
                
                let filteredPeople = persons.filter {

                    searchText.isEmpty || ($0.name!.lowercased().prefix(searchText.count) == searchText.lowercased())

                }
                
                let sortedPeople = filteredPeople.sorted {
                 
                    switch (($0.transactions?.array.last as? Transaction)?.date, ($1.transactions?.array.last as? Transaction)?.date) {
                 
                        case (($0.transactions?.array.last as? Transaction)?.date as Date, ($1.transactions?.array.last as? Transaction)?.date as Date):
                            return ($0.transactions?.array.last as! Transaction).date! > ($1.transactions?.array.last as! Transaction).date!
                        
                        case (nil, nil):
                            return false
                        
                        case (nil, _):
                            return false
                        
                        case (_, nil):
                            return true
                        
                        default:
                            return true
                 
                    }

                 }
                
                List {
                    ForEach (sortedPeople) { person in
                    
                        NavigationLink(destination: ContactPageView(person: person)) {
                            
                                 PersonTileView(person: person)
                            
                             }
                            .contextMenu {
                                Button(action: {
                                    delete(person: person)
                                }) {
                                    Text("Delete")
                                }
                            }
                                
                    }
                }
            }
                 
                .navigationTitle("My Contacts")
                .sheet(isPresented: $showNewContactView) {
                    NewContactView()
                }
                .navigationBarItems(trailing:
                    Button (action: {
                        showNewContactView.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                )
        }
 
    }
    
    func delete (person: Contact) {

        viewContext.delete(person)
        do {
            try viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
            
    }
    
 }

struct NewTransactionView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment (\.presentationMode) var presentationMode

    @State var amount: String = ""
    @State var date: Date = Date()
    @State var title: String = ""
    var contact: Contact

    var body: some View {

        VStack (spacing: 20) {
        
            Form {
        
                    TextField("Enter Amount", text: $amount)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Enter Payment Title", text: $title)
                    Button (action: {
                        guard self.amount != "" && self.title != "" else {
                            return
                        }
                        let transaction = Transaction(context: viewContext)
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        let nsNumber = formatter.number(from: self.amount)
                        transaction.amount = nsNumber!.floatValue
                        transaction.date = self.date
                        transaction.contact = contact
                        transaction.title = self.title
                        transaction.id = UUID()
                        do {
                            try viewContext.save()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }) {
                        Text("Save")
                    }
                 
            }
        }
        .padding()
        .navigationBarTitle("Add New Transaction")
    
    }
}
    


struct ContactPageView:View {
 
    @ObservedObject var person: Contact
    @State var showNewTransactionView: Bool = false
 
    var body: some View {
        List {
            ForEach (person.transactions?.array as! [Transaction]) { transaction in
                HStack {
                    VStack (alignment: .leading, spacing: 7) {
                        Text(transaction.title ?? "")
                        Text("\(transaction.date!)" as String)
                    }
                    Spacer()
                    Text("$\(transaction.amount)" as String)
                }.padding()
            }
        }
        .navigationBarTitle(person.name ?? "")
            .navigationBarItems(trailing:
                Button (action: {
                    showNewTransactionView.toggle()
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showNewTransactionView) {
                NewTransactionView(contact: person)
            }
    }
        
}


struct PersonTileView: View {
 
@ObservedObject var person: Contact
 
var body: some View {

    HStack {
    
        VStack(alignment: .leading, spacing: 8) {
 
            Text(person.name ?? "")
                .font(.system(size: 20))
 
            if let transaction = person.transactions?.array as? [Transaction] {
                
                if !transaction.isEmpty {
                    Text("\(transaction.last!.date!)" as String)
                        .font(.custom("Open-Sans", size: 12))
                }
            
            } else {
 
                Text( "No Transactions")
                    .font(.custom("Open-Sans", size: 12))
                    .foregroundColor(Color("Subitems"))
 
            }
        }
 
      Spacer()

      if let transaction = person.transactions?.array as? [Transaction] {
    
          let amount = transaction.map{($0.amount)}.reduce(0,+)
          let currencySymbol = Locale.current.currencySymbol!
        
          Text("\(currencySymbol) \(amount)" as String)
              .foregroundColor(Color.green)
              .font(.system(size: 20))
    
      }
        
    }.padding()

   }
}

struct NewContactView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment (\.presentationMode) var presentationMode

    @State var name: String = ""

    var body: some View {

        VStack (spacing: 20) {
        
            Text("Add a New Contact:")
                .font(.headline)
            TextField("Enter Name", text: $name)
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
            Button (action: {
                guard self.name != "" else {
                    return
                }
                let newPerson = Contact(context: viewContext)
                newPerson.name = self.name
                newPerson.id = UUID()
                do {
                    try viewContext.save()
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print(error.localizedDescription)
                }
            }) {
                Text("Save")
            }
        
        }
        .padding()
    
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
