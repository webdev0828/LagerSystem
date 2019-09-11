class CustomerAbility
  include CanCan::Ability

  def initialize(user)
    return unless user

    can :read, Customer, :id => user.customer_ids, :deactivated => false

    # can view pallets
    can :read, Arrival
    can :read, Pallet
    can :read, PalletCorrection

    # can view access following actions
    can [:index, :show, :finished, :delivery_note, :exit_note], Order

    # Only for orders
    alias_action :edit, :update, :new, :create, :destroy, :autofill, :search_pallets, :reserve, :cancel_reservation, :submit, to: :modify
    can :modify, Order, owner_id: user.id, state: 'editing'

    can :make_owner, Order, state: 'editing' # Security hole

    # can :read, Reservation
  end

end