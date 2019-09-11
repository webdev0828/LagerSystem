class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user
    return if user.is? :customer

    if user.is? :admin
      can :manage, User
    end

    # Note: No need to rename departments
    can :read, Department, :id => user.department_ids

    if true # can manage customer data
      can :manage, Customer
      can :manage, Arrangement
    end

    if true # can manage arrival, pallets, etc.
      can :manage, Arrival
      can :manage, Pallet
      can :manage, PalletCorrection
    end

    # everyone can create notes
    # ... but only accountants can delete them
    can :manage, Note
    cannot :delete, Note

    if true # can manage accounting
      can :manage, Interval
      can :delete, Note
    end

    if true # can manage orders
      can [:index, :mark, :finish_marked, :show, :delivery_note, :exit_note, :scrap_note, :pallet_note], Order

      # Can only change or delete order if current_user is owner

      # missing: :new, :create

      alias_action :new, :create, :edit, :update, :destroy, :autofill, :search_pallets, :reserve, :cancel_reservation, to: :modify
      can :modify, Order, owner_id: user.id, state: 'editing'

      can [:submit, :change, :reject, :carry_out, :mark_ready, :finish, :make_owner], Order
      can :swap, Order, state: 'submitted'
    end

    if true
      can [:index,:show, :pallets], CustomerGroup
      can [:index, :show, :new, :create], OrderImport

      can [:modify,:approve], OrderImport do |order_import|
        order_import.orders.all? { |order| can? :modify, order }
      end
    end

    if true # can read storages
      can :manage, Storage
      can :manage, BulkStorage
      can :manage, OrganizedStorage
      can :manage, Placement
    end

    if true
      can :show, :docs
    end

  end
end

