class DocsController < ApplicationController
  layout 'docs'

  def show
    authorize! :show, :docs
    render params[:page]
  rescue ActionView::MissingTemplate => _
    render file: "#{Rails.root}/public/404.html", layout: nil, status: 404
  end

end
