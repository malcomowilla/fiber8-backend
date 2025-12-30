# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end



# SystemAdmin.create(system_admin_phone_number: ENV['SYSTEM_ADMIN_PHONE_NUMBER'],
#   password: ENV['SYSTEM_ADMIN_PASSWORD'],
#   # role: 'system_administrator'
  
#   email: ENV['SYSTEM_ADMIN_EMAIL'])







  # plans = [
  #   { name: "Pro", features: ["Basic Support", "Up to 10 Devices"], maximum_pppoe_subscribers: 100 },
  #   { name: "Business", features: ["Priority Support", "Up to 50 Devices", "Analytics"], maximum_pppoe_subscribers: 50 },
  #   { name: "Enterprise", features: ["24/7 Support", "Unlimited Devices", "Custom Features"], maximum_pppoe_subscribers: 2000 },
  #   { name: "Basic", features: ["24/7 Support", "Unlimited Devices", "Custom Features"], maximum_pppoe_subscribers: 50 }

  # ]
  
  


  
  
#   plans = [
#     { name: "Pro", maximum_pppoe_subscribers: 100 },
#     { name: "Standard", maximum_pppoe_subscribers: 180 },
#     { name: "Enterprise", maximum_pppoe_subscribers: 2000 },
#     { name: "Bronze", maximum_pppoe_subscribers: 1000 },
#     { name: "Startup", maximum_pppoe_subscribers: 300 },
#     { name: "Basic",  maximum_pppoe_subscribers: 50 },
#     { name: "Silver",  maximum_pppoe_subscribers: 500 }

#   ]




#   hotspot_plans = [
#     { name: "Starter", hotspot_subscribers: 50 },
#     { name: "Pro", hotspot_subscribers: 200 },
#     { name: "Gold Hotspot", hotspot_subscribers: 1000 },
#     { name: "Business", hotspot_subscribers: 2000 },
#     { name: "Startup", hotspot_subscribers: 300 },
#     { name: "Silver",  hotspot_subscribers: 500 }

#   ]
  


#   hotspot_plans.each do |plan|
#   HotspotPlan.create(name: plan[:name], hotspot_subscribers: plan[:hotspot_subscribers])

# end

# puts "Hotspot Plans have been loaded successfully! 🎯"

  


# plans.each do |plan|
#   PpPoePlan.create(name: plan[:name], maximum_pppoe_subscribers: plan[:maximum_pppoe_subscribers])

# end


 Na.first_or_initialize(shortname: 'superadmin', 



    secret:'dg&24rand(0)'
    
    
    )

puts "radius settings have been loaded successfully! 🎯"

templates = [
    {name: 'sleekspot', template_type: 'Sleekspot Template'},
    {name: 'default_template', template_type: 'Default Template'},
    {name: 'attractive', template_type: 'Attractive Template'},
    {name: 'flat', template_type: 'Flat Design Template'},
    {name: 'minimal', template_type: 'Minimal Template'},
    {name: 'simple', template_type: 'Simple Template'},
    {name: 'clean', template_type: 'Clean Template'},
    {name: 'pepea', template_type: 'Pepea Template'},
    {name: 'premium', template_type: 'Premium Template'}
  ]

templates.each do |template|
    TemplateLocation.create(name: template[:name], template_type: template[:template_type])
  end
  


