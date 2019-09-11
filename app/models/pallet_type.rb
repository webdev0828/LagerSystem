# encoding: utf-8

class PalletType

  private_class_method :new
  attr_reader :id, :name

  def initialize(id, name)
    @name = name
    @id   = id
  end

  @@map = {
    1 => new(1, "EUR"),
    2 => new(2, "UK"),
    3 => new(3, "Høj EUR"),
    4 => new(4, "Høj UK")
  }.freeze

  @@names = @@map.map { |m,pt| [pt.name, pt.id] }.freeze

  def self.options_for_select
    @@names
  end

  def self.[](id)
    @@map[id]
  end

  def wide?
    @id == 2 || @id == 4
  end

end