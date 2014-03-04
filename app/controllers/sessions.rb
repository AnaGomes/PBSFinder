PbsSite::App.controllers :sessions do

  get :new do
    render 'new'
  end

  post :create do
    if account = Account.authenticate(params[:email], params[:password])
      set_current_account(account)
      redirect url(:base, :index)
    else
      params[:email] = h(params[:email])
      flash.now[:error] = pat('login.error')
      render "/sessions/new"
    end
  end

  delete :destroy do
    set_current_account(nil)
    redirect url(:sessions, :new)
  end
end
