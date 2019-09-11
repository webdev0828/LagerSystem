


# Setup Herning department with required storages
dep1 = Department.create(label: "Herning",
                         address: "JN Spedition A/S\nHvidelvej 15\nDK-7400  Herning",
                         name: "JN Spedition A/S",
                         authorization_number: "4418")

lob1 = dep1.bulk_storages.create(name: 'Lobby')
trans1 = dep1.bulk_storages.create(name: 'Transfer')

dep1.lobby = lob1
dep1.transfer = trans1
dep1.save


# Setup an example of an organized storage for Herning
storage = dep1.organized_storages.create(name: 'Organized storage')

(1..20).each do |shelf|
  (1..30).each do |column|
    (1..6).each do |floor|
      storage.placements.create(shelf: shelf, column: column, floor: floor, hidden: (floor == 6))
    end
  end
end



# Setup Køge department with required storages
dep2 = Department.create(label: "Køge",
                         address: "JN Spedition Øst A/S\nSleipnersvej 1\nDK-4600  Køge",
                         name: "JN Spedition Øst A/S",
                         authorization_number: "5643")


lob2 = dep2.bulk_storages.create(name: 'Lobby')
trans2 = dep2.bulk_storages.create(name: 'Transfer')

dep2.lobby = lob2
dep2.transfer = trans2
dep2.save





# Setup admin user with access to both apartments
admin = User.new
admin.role = 'admin'
admin.email = 'some_admin_mail@jn-spedition.dk'
admin.password = 'demo whoop'
admin.username = 'admin'
admin.full_name = 'Administrator user'
admin.department_ids = [dep1.id, dep2.id]
admin.save
