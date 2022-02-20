class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :destroy]

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def author_params
    params.require(:author).permit()
  end
end
