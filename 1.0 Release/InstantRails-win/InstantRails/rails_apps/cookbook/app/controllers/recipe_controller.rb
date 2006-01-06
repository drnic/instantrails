class RecipeController < ApplicationController
  layout "standard-layout"
  scaffold :recipe
  
  def new
    @recipe = Recipe.new
    @categories = Category.find_all
  end
  
  def list
    @category = @params['category']
    @recipes = Recipe.find_all
  end
  
  def edit
    @recipe = Recipe.find(@params["id"])
    @categories = Category.find_all
  end
  
  def create
    @recipe = Recipe.new(@params['recipe'])
    @recipe.date = Date.today
    if @recipe.save
        redirect_to :action => 'list'
    else
        render_action 'new'
    end
  end
  
  def delete
    Recipe.find(@params['id']).destroy
    redirect_to :action => 'list'
  end
end
