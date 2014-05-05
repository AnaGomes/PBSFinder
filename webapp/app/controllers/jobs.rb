PbsSite::App.controllers :jobs do

  get :new do
    @job = Job.new
    @big_title = t('job.big_title.new')
    render 'jobs/new'
  end

  post :create do
    @job = Job.new(params[:job])
    @job.complete = false
    @job.account = current_account
    if server_running?
      if @job.save
        long_job('PbsFinder', @job.id, absolute_url(:jobs, :response, @job.id), @job.query)
        flash[:success] = t('job.create.success')
        redirect(url_for(:jobs, :job, @job.id))
      else
        @big_title = t('job.big_title.new')
        flash.now[:error] = t('job.create.error', :model => 'job')
        render 'jobs/new'
      end
    else
      flash.now[:error] = t('job.create.no_server', :model => 'job')
      render 'jobs/new'
    end
  end

  post :report, :with => :id do
    job = Job.find(params[:id])
    if job
      deliver(
        :notification,
        :job_problem_report_email,
        "#{job.account.name} #{job.account.surname}",
        job.account.email,
        params[:message].empty? ? 'NO DESCRIPTION' : params[:message],
        absolute_url(:jobs, :job, job.id),
        settings.main_conf['contact']['email']
      )
      flash[:success] = t('job.view.report.sent')
      redirect back
    else
      flash[:error] = t('job.view.report.failed')
      redirect back
    end
  end

  get :list do
    @jobs = current_account.jobs.where(complete: true).desc(:created_at)
    @jobs = @jobs.paginate(:page => params[:page] || 1, :per_page => 10)
    @complete = true
    @big_title = t('job.big_title.list')
    render 'jobs/list'
  end

  get :pending do
    @jobs = current_account.jobs.where(complete: false).desc(:created_at)
    @jobs = @jobs.paginate(:page => params[:page] || 1, :per_page => 10)
    @complete = false
    @big_title = t('job.big_title.pending')
    render 'jobs/list'
  end

  get :transcript, :map => '/jobs/transcript/:trans_id' do
    @transcript = Transcript.find(params[:trans_id])
    if @transcript
      @gene = @transcript.gene
      @protein = @transcript.own_protein
      @big_title = t('job.transcript.big_title')
      render 'jobs/transcript'
    else
      flash[:error] = t('job.transcript.not_found')
      redirect url('/')
    end
  end

  get :protein, :map => '/jobs/protein/:prot_id' do
    @protein = Protein.find(params[:prot_id])
    if @protein && @protein.protein_id
      @transcript = @protein.transcript || @protein.own_transcript
      @gene = @transcript.gene
      @big_title = t('job.protein.big_title')
      render 'jobs/protein'
    else
      flash[:error] = t('job.protein.not_found')
      redirect url('/')
    end
  end

  get :job_prot, :with => :id, :provides => [:csv, :tsv] do
    @job = Job.find(params[:id])
    if @job
      case content_type
      when :csv
        content_type 'application/csv'
        attachment "prot_results.csv"
        return @job.to_prot_csv
      when :tsv
        content_type 'application/tsv'
        attachment "prot_results.tsv"
        return @job.to_prot_csv(col_sep: "\t")
      end
    else
      flash[:error] = t('job.view.not_found')
      redirect url('/')
    end
  end

  get :job, :with => :id, :provides => [:html, :csv, :tsv] do
    @job = Job.find(params[:id])
    if @job
      case content_type
      when :html
        @big_title = t('job.view.big_title')
        render 'jobs/job'
      when :csv
        content_type 'application/csv'
        attachment "rbp_results.csv"
        return @job.to_csv
      when :tsv
        content_type 'application/tsv'
        attachment "rbp_results.tsv"
        return @job.to_csv(col_sep: "\t")
      end
    else
      flash[:error] = t('job.view.not_found')
      redirect url('/')
    end
  end

  post :completed, :csrf_protection => false do
    if params[:id].nil?
      return { result: false }.to_json
    else
      job = Job.find(params[:id])
      return { result: (job ? job.complete : false) }.to_json
    end
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

  post :response, :with => :id, :csrf_protection => false do
    job = Job.find(params[:id])
    if job && job.complete && job.notify
      deliver(
        :notification,
        :job_notification_email,
        "#{job.account.name} #{job.account.surname}",
        job.account.email,
        job.id,
        absolute_url(:jobs, :job, job.id),
        job.description
      )
    end
  end

end
