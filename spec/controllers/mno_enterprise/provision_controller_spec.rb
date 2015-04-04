require 'rails_helper'

module MnoEnterprise
  describe ProvisionController, type: :controller do
    render_views
    routes { MnoEnterprise::Engine.routes }
    
    # Create user and organization + mutual associations
    let(:organization) { build(:organization) }
    let(:user) { build(:user) }
    before { api_stub_for(MnoEnterprise::User, method: :get, path: "/users/#{user.id}", response: from_api(user)) }
    before { allow(organization).to receive(:users).and_return([user]) }
    before { allow_any_instance_of(User).to receive(:organizations).and_return([organization]) }
    
    describe 'GET #new' do
      let(:params_org_id) { organization.id }
      let(:params) { { apps: ['vtiger'], organization_id: params_org_id } }
      subject { get :new, params }
      
      describe 'guest' do
        before { subject }
        it { expect(response).to redirect_to(new_user_registration_path) }
      end
      
      # TODO: ability to add app instances for an organization
      describe 'signed in and missing organization with multiple organizations available' do
        let(:params_org_id) { nil }
        before { allow_any_instance_of(User).to receive(:organizations).and_return([organization,organization]) }
        before { sign_in user }
        before { subject }
        
        it { expect(response).to render_template('mno_enterprise/provision/_select_organization') }
      end
      
      describe 'signed in and missing organization with one organization available' do
        let(:params_org_id) { nil }
        before { sign_in user }
        before { subject }
        
        it { expect(response).to render_template('mno_enterprise/provision/_provision_apps') }
      end
    end
    
    describe 'POST #create' do
      let(:params_org_id) { organization.id }
      let(:app_instance) { build(:app_instance) }
      let(:params) { { apps: ['vtiger'], organization_id: params_org_id } }
      subject { post :create, params }
      before { api_stub_for(MnoEnterprise::AppInstance, 
        method: :post, 
        path: "/organizations/#{params_org_id}/app_instances",
        response: from_api(user)
      )}
      
      describe 'guest' do
        before { subject }
        it { expect(response).to_not be_success }
      end
      
      describe 'signed in' do
        before { sign_in user }
        before { subject }
        it { expect(response).to be_success }
      end
    end
    
  end
end