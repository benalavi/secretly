class Main
  get "/css/reset.css" do
    content_type "text/css", :charset => "UTF-8"
    sass :"css/reset"
  end
  
  get "/css/:stylesheet.css" do
    content_type "text/css", :charset => "UTF-8"
    scss :"css/#{params[:stylesheet]}"
  end
end
