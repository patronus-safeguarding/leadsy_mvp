module AccessTemplatesHelper
  def readable_scope_name(scope)
    case scope
    when 'https://www.googleapis.com/auth/adwords'
      'Google Ads Management'
    when 'https://www.googleapis.com/auth/userinfo.email'
      'User Email Access'
    when 'https://www.googleapis.com/auth/userinfo.profile'
      'User Profile Access'
    when 'email'
      'Email Access'
    when 'public_profile'
      'Public Profile'
    when 'business_management'
      'Business Management'
    when 'ads_management'
      'Ads Management'
    when 'pages_manage_ads'
      'Pages Ad Management'
    when 'pages_read_engagement'
      'Pages Engagement'
    when 'pages_show_list'
      'Pages List Access'
    else
      scope.humanize
    end
  end

  def scope_description(scope)
    case scope
    when 'https://www.googleapis.com/auth/adwords'
      'Full access to manage Google Ads campaigns, accounts, and billing'
    when 'https://www.googleapis.com/auth/userinfo.email'
      'Access to user email address for identification'
    when 'https://www.googleapis.com/auth/userinfo.profile'
      'Access to basic user profile information'
    when 'email'
      'Access to user email address'
    when 'public_profile'
      'Access to public profile information'
    when 'business_management'
      'Manage business accounts and settings'
    when 'ads_management'
      'Create and manage advertising campaigns'
    when 'pages_manage_ads'
      'Manage ads for Facebook pages'
    when 'pages_read_engagement'
      'Read page engagement metrics'
    when 'pages_show_list'
      'View list of accessible pages'
    else
      'Access to this resource'
    end
  end
end
