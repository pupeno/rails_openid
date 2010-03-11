# coding: utf-8
# Copyright 2010 J. Pablo Fernández

require 'openid/extensions/sreg'
require 'openid/store/filesystem'

module RailsOpenId
  def send_open_id_request(params, fallback, return_to, meta = [])
    # Create the OpenID request, and in the process, verify the URI is valid.
    identifier = params[:openid_identifier]
    if identifier.blank?
      flash[:error] = "Please, enter an OpenID identifier (that is, your OpenID address)."
      redirect_to fallback
      return
    end
    
    oidreq = consumer.begin(identifier)
    
    if not meta.empty?
      # Request email, nickname and fullname.
      sregreq = OpenID::SReg::Request.new
      sregreq.request_fields(meta, true)
      oidreq.add_extension(sregreq)
      oidreq.return_to_args['did_sreg'] = 'y'
    end
    
    if oidreq.send_redirect?(root_url, return_to)
      redirect_to oidreq.redirect_url(root_url, return_to)
    else
      # This option is used if the request is too big to be sent in the URL, or something like, not very likely to happen I'd say.
      # A way to force is to do this: oidreq.return_to_args['force_post']='x'*2048
      render :text => oidreq.html_markup(root_url, root_url, :form_tag_attrs => {'id' => 'openid_form'})
    end
  rescue OpenID::OpenIDError => e
    flash[:error] = "#{identifier} doesn't seem to be a valid, working OpenID. Maybe it has a typo?"
    redirect_to fallback
    return
  end
  
  def process_open_id_response(params, current_url, fallback)
    parameters = params.reject {|k,v| request.path_parameters[k] }
    oidresp = consumer.complete(parameters, current_url)
    
    if oidresp.status == OpenID::Consumer::SUCCESS
      data = {}
      if params[:did_sreg]
        sreg_resp = OpenID::SReg::Response.from_success_response(oidresp)
        data.merge! sreg_resp.data
      end
      data[:identity_url] = oidresp.identity_url
      data[:display_identifier] = oidresp.display_identifier
      return data
    else
      # Possible non-succes statuses: OpenID::Consumer::FAILURE, OpenID::Consumer::SETUP_NEEDED, OpenID::Consumer::CANCEL
      if not oidresp.display_identifier.blank?
        flash[:error] = "We couldn't verify your OpenID #{oidresp.display_identifier}."
      else
        flash[:error] = "We couldn't verify your OpenID."
      end
      redirect_to fallback
      return nil
    end
  end
  
  private
  
  def consumer
    if @consumer.nil?
      dir = Pathname.new(RAILS_ROOT).join('db').join('cstore')
      store = OpenID::Store::Filesystem.new(dir)
      @consumer = OpenID::Consumer.new(session, store)
    end
    return @consumer
  end
end