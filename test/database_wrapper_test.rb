require_relative "test_helper"
require_relative "../lib/database_wrapper"

class DatabaseWrapperTest < Minitest::Test
  def test_it_can_make_a_new_database
    data_wrapper = DatabaseWrapper.new

    assert_equal SQLite3::Database, data_wrapper.database.class
  end
end
