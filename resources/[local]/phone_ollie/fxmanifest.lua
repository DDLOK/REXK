fx_version 'cerulean'
game 'gta5'
author 'SAN VALLY STATE'
description 'F1 phone - jobs/bank/contacts/settings/GPS'
version '1.0.0'

client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependency 'account_ollie'
dependency 'cash_ollie'
dependency 'jobs_ollie'
