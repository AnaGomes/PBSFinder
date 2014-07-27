PbsSite::App.controllers :irap do
  get :new do
    @irap = IrapConfig.new
    @big_title = t('irap.big_title.new')
    render 'irap/new'
  end

  post :create do
    puts params.inspect
    @irap = IrapConfig.new(params[:irap_config])
    @irap.account = current_account
    if @irap.save
      flash[:success] = t('irap.create.success')
      redirect(url_for(:irap, :update, @irap.id))
    else
      @big_title = t('irap.big_title.new')
      flash.now[:error] = t('irap.create.error', :model => 'job')
      render 'irap/new'
    end
  end

  get :edit, with: :id do
  end

  get :new_from_existing, with: :id do
  end

  put :update, with: :id do
  end

  delete :destroy, with: :id do
    irap = IrapConfig.find(params[:id])
    if irap
      irap.destroy
      flash[:success] = t('irap.destroy.success')
      redirect back
    else
      flash[:error] = t('irap.destroy.success')
      redirect back
    end
  end

  delete :destroy_many do
    unless params[:irap_ids]
      flash[:error] = t('irap.destroy_many.error')
      redirect back
    end
    ids = params[:irap_ids].split(',').map(&:strip)
    iraps = IrapConfig.find(ids)
    iraps.each(&:destroy)
    flash[:success] = t('irap.destroy_many.success')
    redirect back
  end

  get :list do
    @iraps = IrapConfig.where(account_id: current_account.id).desc(:created_at)
    @iraps = @iraps.paginate(:page => params[:page] || 1, :per_page => 10)
    @big_title = t('irap.big_title.list')
    render 'irap/list'
  end

  get :download, with: :id do
    @irap = IrapConfig.find(params[:id])
    if @irap
      content_type 'text/txt'
      attachment @irap.name
      return download_format(@irap)
    else
      flash[:error] = t('irap.download.not_found')
      redirect url('/')
    end
  end
end
