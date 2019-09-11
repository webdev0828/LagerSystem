require 'test_helper'

class CustomerGroupTest < ActiveSupport::TestCase

  def setup
    @department = create(:department)
    @customers = (1..3).map { create(:customer, department_id: @department.id) }
    @customer_group = @department.customer_groups.create(name: 'Test', customer_ids: @customers.map(&:id))

    @article_number = '123'
    @capacity = 10

    very_soon = 2.days.from_now.to_date
    @bbd_old = 50.days.from_now.to_date
    @bbd_new = 100.days.from_now.to_date

    a1 = create(:arrival, {
        number: @article_number,
        customer_id: @customers[0].id,
        count: @capacity + @capacity + 5,
        capacity: @capacity,
        best_before: @bbd_new
    })

    a2 = create(:arrival, {
        number: @article_number,
        customer_id: @customers[1].id,
        count: @capacity + @capacity + 3,
        capacity: @capacity,
        best_before: @bbd_old
    })

    a3 = create(:arrival, {
        number: @article_number,
        customer_id: @customers[0].id,
        count: @capacity + @capacity + 2,
        capacity: @capacity,
        best_before: very_soon
    })
    storage = create(:bulk_storage)

    a1.pallets.each do |p|
      p.update(position: storage)
    end

    a2.pallets.each do |p|
      p.update(position: storage)
    end

  end

  def fetch(count)
    @customer_group.ordered_pallets_by_number(@article_number, count)
  end

  def assert_none_missing(result)
    assert result[:missing] == 0, 'Articles are missing'
  end

  def assert_pallet_count(result, count)
    assert_equal count, result[:selected].size, 'Unexpected number of pallets fetched'
  end

  def assert_old_full(selection, count)
    assert_equal false, selection[:pallet].scrap?, 'Must be full pallet'
    assert_equal @bbd_old, selection[:pallet].best_before, 'Must be old pallet'
    assert_equal count, selection[:count], 'Count must match'
  end

  def assert_old_scrap(selection, count)
    assert_equal true, selection[:pallet].scrap?, 'Must be scrap pallet'
    assert_equal @bbd_old, selection[:pallet].best_before, 'Must be old pallet'
    assert_equal count, selection[:count], 'Count must match'
  end

  def assert_new_full(selection, count)
    assert_equal false, selection[:pallet].scrap?, 'Must be full pallet'
    assert_equal @bbd_new, selection[:pallet].best_before, 'Must be new pallet'
    assert_equal count, selection[:count], 'Count must match'
  end

  def assert_new_scrap(selection, count)
    assert_equal true, selection[:pallet].scrap?, 'Must be scrap pallet'
    assert_equal @bbd_new, selection[:pallet].best_before, 'Must be new pallet'
    assert_equal count, selection[:count], 'Count must match'
  end

  def test_dont_fetch_from_lobby
    result = fetch(70)
    assert_equal 22, result[:missing], 'There should be 22 missing since they are in the lobby'
    assert_equal 3, result[:lobby], 'There should be 2 pallets in the lobby'
  end

  # Select 1 from the oldest scrap pallet
  def test_fetch_1
    result = fetch(1)

    assert_none_missing result
    assert_pallet_count result, 1

    assert_old_scrap result[:selected][0], 1
  end

  # Select 3 (all remaining) from the oldest scrap pallet
  def test_fetch_3
    result = fetch(3)

    assert_none_missing result
    assert_pallet_count result, 1

    assert_old_scrap result[:selected][0], 3
  end


  # Select 5
  # 3 (all remaining) from old scrap
  # 2 from old full
  def test_fetch_5

    result = fetch(5)

    assert_none_missing result
    assert_pallet_count result, 2

    # First empty the oldest scrap pallet
    assert_old_scrap result[:selected][0], 3

    # Then start to empty another old one
    # (even though we have another scrap pallet)
    assert_old_full  result[:selected][1], 2

  end

  # Select 10 (all) from old full pallet
  def test_fetch_10
    result = fetch(10)

    assert_none_missing result
    assert_pallet_count result, 1

    assert_old_full result[:selected][0], 10
  end

  def test_fetch_11
    result = fetch(11)

    assert_none_missing result
    assert_pallet_count result, 2

    assert_old_full  result[:selected][0], 10
    assert_old_scrap result[:selected][1], 1
  end

  # Select 15
  # Select 10 (all) from old full pallet
  # Select 3 (all remaining) from old scrap pallet
  # Select 2 from old full pallet
  def test_fetch_15
    result = fetch(15)

    assert_none_missing result
    assert_pallet_count result, 3

    # Since count bigger than any pallets capacity we first pallet
    assert_old_full  result[:selected][0], 10
    assert_old_scrap result[:selected][1], 3
    assert_old_full  result[:selected][2], 2
  end

  def test_fetch_26
    result = fetch(26)

    assert_none_missing result
    assert_pallet_count result, 4

    assert_old_full  result[:selected][0], 10
    assert_old_full  result[:selected][1], 10
    assert_old_scrap result[:selected][2], 3
    assert_new_scrap result[:selected][3], 3
  end

  def test_fetch_30
    result = fetch(30)

    assert_none_missing result
    assert_pallet_count result, 5

    assert_old_full  result[:selected][0], 10
    assert_old_full  result[:selected][1], 10
    assert_old_scrap result[:selected][2], 3
    assert_new_scrap result[:selected][3], 5
    assert_new_full  result[:selected][4], 2
  end

end
