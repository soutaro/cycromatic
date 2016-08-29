require_relative 'test_helper'

class CycromaticTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Cycromatic::VERSION
  end
end
