PbsSite::App.controllers :sessions do

  get :new do
    if logged_in?
      flash[:notice] = t('login.already')
      redirect url('/')
    else
      render 'sessions/new'
    end
  end

  post :create do
    if logged_in?
      flash[:notice] = t('login.already')
      redirect url('/')
    else
      if account = Account.authenticate(params[:email], params[:password])
        set_current_account(account)
        flash[:success] = t('login.success')
        redirect url('/')
      else
        params[:email] = h(params[:email])
        flash.now[:error] = t('login.error')
        render 'sessions/new'
      end
    end
  end

  delete :destroy do
    if logged_in?
      set_current_account(nil)
      flash[:success] = t('logout.success')
    else
      flash[:notice] = t('logout.already')
    end
    redirect url(:sessions, :new)
  end
end
