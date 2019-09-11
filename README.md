# README

Install bundler

    gem install bundler

Install gems

bundle install

- Configure your `config/database.yml` to fit your database setup
- Run `rake db:create` to create the specified database
- Run `rake db:migrate` to setup the database structure
- Run `rake db:seeds` to setup demo admin, departments and storages

### Howto run development environment

    rails s -e development -p 3000

# DOCS

These docs are under preparation. They will be made continuously when there are more corrections.

The easiest way to find the file you need to edit is to run the following command in your terminal

    rake routes

This command will list all available routes. To find the file you are looking for, go visit the page in the browser. The URL will be something like this: `http://:domain/departments/2/customers/119/orders/138454`. Compare this URL with the ones in the routes list. The correct route for this URL will look like this in the terminal:

    exit_note_department_customer_order     GET     /departments/:department_id/customers/:customer_id/orders/:id/exit_note (.:format)     orders#exit_note

This shows three things:

- _exit_note_department_customer_order_: The rails url helper
- _/departments/:department_id/customers/:customer_id/orders/:id/exit_note_: The URL including name for the parameters
- _orders#exit_note_: The name of the associated controller and controller action

We will be looking at the controller. If we open the OrdersController in `app/controllers/orders_controller.rb`, and go to the `exit_note` action. Some actions have a belonging view. However, this is not the case for this action. If the action had a view, it would however be located in `app/views/:controller_prefix/:controller_action`.

## Edit printable order notes

To edit the notes for printing a customer's order notes go to `app/documents/orders_document.rb`. As an example we will edit the exit_note. This can be done by going to the `self.exit_note` action. This action contains the following

    def self.exit_note(view)
        pdf = OrdersDocument.new(view)
        pdf.note_header
        pdf.exit_table
        pdf
    end

Obviously, the `note_header` contains the header and the `exit_table` contains the table. Inside the `exit_table` action in the current file, all the table's content is listed. The table headers can be found inside the `headers` array, and the table body can be found inside the `table_data` map.

To add another column to the table, first add the name of the column to the `headers` array. Then add the actual code to collect the data to the `table_data` map. Like this

    headers = [
      'Varenr.',
      'Lotnr.',
      'M.H.T',
      'Varebeskrivelse',
      'Vægt/Krt.',
      'Antal',
      'Vægt'
    ]

    table_data = @order.reservations.map { |reservation| [
      reservation.pallet.number,
      reservation.pallet.batch,
      I18n.l(reservation.pallet.best_before, format: :short),
      reservation.pallet.name,
      @view.number_with_precision(reservation.pallet.weight) + " kg",
      @view.number_with_delimiter(reservation.count),
      @view.number_with_precision(reservation.pallet.weight * reservation.count) + " kg"
    ]}

I added the 'M.H.T' column and the associated data `I18n.l(reservation.pallet.best_before, format: :short)`.

That's it.
