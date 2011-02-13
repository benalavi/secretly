class Main
  set :haml, :format => :html5
  
  get "/" do
    haml :home
  end
  
  post "/secrets" do
    @secret = Secret.create params[:secret]
    haml :"secrets/create.html"
  end
  
  get "/secrets/:url" do
    @secret = Secret.find(encrypted_url: Secret.hash_url(params[:url])).first
    @secret.content(params[:url])
    
    haml :"secrets/show.html"
  end
end
