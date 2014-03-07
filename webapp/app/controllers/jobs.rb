PbsSite::App.controllers :jobs do

  get :new do
    @job = Job.new
    @big_title = t('job.big_title.new')
    render :new
  end

  post :create do
    @job = Job.new(params[:job])
    @job.completed = false
    @job.account = current_account
    if @job.save
      # TODO CREATE JOB ON SERVER
      flash[:success] = t('job.create.success')
      redirect(url_for(:jobs, :job, @job.id))
    else
      @big_title = t('job.big_title.new')
      puts @job.errors.inspect
      flash.now[:error] = t('job.create.error', :model => 'job')
      render :new
    end
  end

  get :list do
    @jobs = current_account.jobs.where(completed: true)
    @completed = true
    @big_title = t('job.big_title.list')
    render :list
  end

  get :pending do
    @jobs = current_account.jobs.where(completed: false)
    @completed = false
    @big_title = t('job.big_title.pending')
    render :list
  end

  get :job, :with => :id do
    # TODO
  end

  delete :destroy, :with => :id do
    job = Job.find(params[:id])
    if job
      job.destroy
      flash[:success] = t('job.destroy.success')
      redirect back
    else
      flash[:error] = t('job.destroy.error')
      redirect back
    end
  end

  delete :destroy_many do
    unless params[:job_ids]
      flash[:error] = t('job.destroy_many.error', :model => 'account')
      redirect back
    end
    ids = params[:job_ids].split(',').map(&:strip)
    jobs = Job.find(ids)
    jobs.each(&:destroy)
    flash[:success] = t('job.destroy_many.success')
    redirect back
  end

  post :job, :csrf_protection => false do
    puts params[:result]
  end

end
