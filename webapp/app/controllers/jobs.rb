PbsSite::App.controllers :jobs do

  get :new do
    # TODO
  end

  post :create do
    # TODO
  end

  get :list do
    # TODO
  end

  get :job do
    # TODO
  end

  delete :destroy do
    # TODO
  end

  post :job, :csrf_protection => false do
    puts params[:result]
  end

end
