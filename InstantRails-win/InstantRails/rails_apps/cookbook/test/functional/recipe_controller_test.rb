require File.dirname(__FILE__) + '/../test_helper'
require 'recipe_controller'

# Re-raise errors caught by the controller.
class RecipeController; def rescue_action(e) raise e end; end

class RecipeControllerTest < Test::Unit::TestCase
  def setup
    @controller = RecipeController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
