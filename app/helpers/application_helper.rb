module ApplicationHelper
  def brand_favicon_tag
    # Prefer app/assets/images/favicon.png if present; otherwise fallback to public/favicon.ico
    if Rails.application.assets&.find_asset('favicon.png') || Rails.application.config.assets.precompile
      favicon_link_tag asset_path('favicon.png')
    else
      # public/ fallback (served as-is)
      tag.link rel: 'icon', href: '/favicon.ico'
    end
  end
end
