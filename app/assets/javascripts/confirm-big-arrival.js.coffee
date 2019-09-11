$(document).on 'submit', '#new_arrival', ->
  capacity = parseInt $('#arrival_capacity').val()
  count    = parseInt $('#arrival_count').val()

  if capacity and count
    pallet_count = Math.ceil(count / capacity)

    if pallet_count > 50
      confirm("Indgangen vil resultere i at #{pallet_count} paller vil blive oprettet.\n\nVil du fortsætte?");
