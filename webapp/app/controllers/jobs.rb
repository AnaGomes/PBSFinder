PbsSite::App.controllers :jobs do

  post :job, :csrf_protection => false do
    puts params[:result]
  end

end
