PbsSite::App.controllers '/' do

  get :index do
    render 'base/index'
  end

  get :contact, :map => '/contact' do
    @big_title = t('contact.big_title')
    @contact = Contact.new
    render 'base/contact'
  end

  post :send, :map => '/contact' do
    @contact = Contact.new(params[:contact])
    @big_title = t('contact.big_title')
    if @contact.save
      contact(@contact)
      flash.now[:success] = t('contact.success')
      render 'base/contact'
    else
      flash.now[:error] = t('contact.error')
      render 'base/contact'
    end
  end

  #get :about, :map => '/about' do
    #render 'base/about'
  #end

end
