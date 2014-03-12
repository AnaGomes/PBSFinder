PbsSite::App.controllers :accounts do

  get :new do
    if logged_in?
      flash[:notice] = t('register.already')
      redirect url('/')
    else
      @account = Account.new
      @big_title = t('register.big_title')
      render 'accounts/new'
    end
  end

  post :create do
    if logged_in?
      flash[:notice] = t('register.already')
      redirect url('/')
    else
      @account = Account.new(params[:account])
      @account.role = 'user'
      if @account.save
        set_current_account(@account)
        flash[:success] = t('register.success')
        redirect url('/')
      else
        @big_title = t('register.big_title')
        flash.now[:error] = t('register.error', :model => 'account')
        render 'accounts/new'
      end
    end
  end

  get :edit do
    unless logged_in?
      flash[:notice] = t('register.not_yet')
      redirect url('/')
    else
      @big_title = t('register.update.big_title')
      @account = current_account
      render 'accounts/edit'
    end
  end

  put :update do
    unless logged_in?
      flash[:notice] = t('register.not_yet')
      redirect url('/')
    else
      @big_title = t('register.update.big_title')
      @account = current_account
      if @account.update_attributes(params[:account])
        flash[:success] = t('register.update.success')
        redirect url(:accounts, :edit)
      else
        flash.now[:error] = t('register.update.error', :model => 'account')
        render 'accounts/edit'
      end
    end
  end

end
