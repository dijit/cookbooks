define :psgi_application, :cookbook => 'psgi', :operator => 'Catalyst', :environment => {}, :plackup_environment => 'development', :perl5lib => [], :nproc => '1',  :debug => '1', :install_dir => '/etc/init.d/', :enable_service => 'on', :ignore_failure => true do 
    base_name = ::File.basename(params[:script].chomp ::File.extname(params[:script]))
    daemon_name = params[:daemon_name] ? params[:daemon_name] : base_name
    proc_title = params[:proc_title] ? params[:proc_title] : base_name
    socket = params[:socket] ? params[:socket] : "/tmp/#{base_name}_fcgi.socket"
    if params[:action] == 'install'
        template "#{params[:install_dir]}/#{daemon_name}" do 
            source 'init-script'
            cookbook params[:cookbook]
            variables({
                :application_user => params[:application_user],
                :application_home => params[:application_home],
                :application_script => params[:script],
                :application_desc => params[:name],
                :daemon_name => daemon_name,
                :daemon_path => params[:daemon_path] || `which plackup`.chomp,
                :socket => socket,
                :envvars => params[:environment],
                :perl5lib => params[:perl5lib],
                :nproc => params[:nproc],
                :proc_manager => params[:proc_manager],
                :proc_title => proc_title,
                :mount => params[:mount],
                :config => params[:config],
                :debug => params[:debug],
                :plackup_environment => params[:plackup_environment],
                :install_dir => params[:install_dir],
                :operator => params[:operator]
            })
            owner 'root'
            group 'root'
            mode '0755'
        end
        if params[:enable_service] == 'on'
            service daemon_name do 
                action :enable
            end
        end
    elsif params[:action] == 'test'
        my_env = params[:environment]
        my_env['PERL5LIB'] = params[:perl5lib].join ':'
        my_env['CATALYST_CONFIG'] = params[:config]
        my_env['CATALYST_DEBUG'] = '1'
        log "execute in pwd: #{params[:application_home]}"
        log "execute with env: #{my_env}"
        daemon_path = params[:daemon_path] || `which plackup`.chomp
        log "daemon_path: #{daemon_path}"
        execute "#{daemon_path} -s CGI #{params[:script]} 1>/dev/null" do 
            environment my_env
            cwd params[:application_home]
            user params[:application_user]
            group params[:application_group]
            ignore_failure params[:ignore_failure]
        end
    end
end
